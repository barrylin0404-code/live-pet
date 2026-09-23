import Foundation
import SwiftUI
import WidgetKit

/// Owns pet + inventory, persists to the App Group, drives need decay.
@MainActor
final class PetStore: ObservableObject {
    @Published private(set) var pet: Pet
    @Published private(set) var items: [InventoryItem]
    @Published private(set) var hasCompletedOnboarding: Bool

    private let defaults: UserDefaults
    private var tickTask: Task<Void, Never>?

    /// Called whenever pet state changes so Live Activity can sync.
    var onPetChange: ((Pet) -> Void)?

    init(defaults: UserDefaults = AppGroup.defaults) {
        self.defaults = defaults
        Self.migrateFromStandardIfNeeded(into: defaults)

        hasCompletedOnboarding = defaults.bool(forKey: AppGroup.onboardingKey)

        if let data = defaults.data(forKey: AppGroup.petKey),
           let saved = try? JSONDecoder().decode(Pet.self, from: data) {
            pet = saved
            // Existing installs already have a pet — skip onboarding gate.
            if !hasCompletedOnboarding {
                hasCompletedOnboarding = true
                defaults.set(true, forKey: AppGroup.onboardingKey)
            }
        } else {
            pet = Pet()
        }

        if let data = defaults.data(forKey: AppGroup.inventoryKey),
           let saved = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            items = saved
        } else {
            items = InventoryItem.catalog
        }

        if hasCompletedOnboarding {
            pet.applyOfflineDecay()
            persist()
        }
    }

    var foods: [InventoryItem] { items.filter(\.isFood) }
    var toys: [InventoryItem] { items.filter(\.isToy) }

    func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { self?.applyTick() }
            }
        }
    }

    func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }

    /// First-run: create named pet and mark onboarding done.
    func completeOnboarding(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "Nubby" : String(trimmed.prefix(16))
        pet = Pet(name: finalName, createdAt: .now)
        items = InventoryItem.catalog
        hasCompletedOnboarding = true
        defaults.set(true, forKey: AppGroup.onboardingKey)
        commit()
    }

    func rename(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pet.name = String(trimmed.prefix(16))
        pet.lastAction = "Renamed to \(pet.name)"
        pet.touch()
        commit()
    }

    func feed(itemID: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID && $0.isFood }) else { return }
        guard items[index].quantity > 0 else { return }
        let item = items[index]
        items[index].quantity -= 1
        pet.feed(with: item)
        if items[index].quantity == 0 {
            items[index].quantity = 1
            pet.lastAction = "Ate \(item.name) · crumb restocked"
            pet.touch()
        }
        commit()
    }

    func play(itemID: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID && $0.isToy }) else { return }
        guard items[index].quantity > 0 else { return }
        pet.play(with: items[index])
        commit()
    }

    func feedDefault() {
        let id = foods.first(where: { $0.quantity > 0 })?.id
            ?? InventoryItem.catalog.first(where: \.isFood)?.id
        guard let id else { return }
        feed(itemID: id)
    }

    func playDefault() {
        let id = toys.first(where: { $0.quantity > 0 })?.id
            ?? InventoryItem.catalog.first(where: \.isToy)?.id
        guard let id else { return }
        play(itemID: id)
    }

    func sleep() {
        pet.sleep()
        commit()
    }

    /// Wipe pet + inventory and return to onboarding.
    func resetAll() {
        stopTicking()
        pet = Pet()
        items = InventoryItem.catalog
        hasCompletedOnboarding = false
        defaults.set(false, forKey: AppGroup.onboardingKey)
        defaults.removeObject(forKey: AppGroup.petKey)
        defaults.removeObject(forKey: AppGroup.inventoryKey)
        defaults.removeObject(forKey: AppGroup.snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
        onPetChange?(pet)
    }

    private func applyTick() {
        pet.tick()
        commit()
    }

    private func commit() {
        persist()
        onPetChange?(pet)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(pet) {
            defaults.set(data, forKey: AppGroup.petKey)
        }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: AppGroup.inventoryKey)
        }
        PetSnapshot(
            name: pet.name,
            petGlyph: pet.petGlyph,
            moodScore: pet.moodScore,
            satiety: pet.satiety,
            energy: pet.energy,
            moodRaw: pet.mood.rawValue,
            lastAction: pet.lastAction,
            lastUpdated: pet.lastUpdated
        ).save(to: defaults)
    }

    private static func migrateFromStandardIfNeeded(into suite: UserDefaults) {
        let flag = "livepet.v1.migratedToAppGroup"
        guard suite.bool(forKey: flag) == false else { return }
        let legacy = UserDefaults.standard
        if suite.data(forKey: AppGroup.petKey) == nil,
           let data = legacy.data(forKey: AppGroup.petKey) ?? legacy.data(forKey: "livepet.v1.pet") {
            suite.set(data, forKey: AppGroup.petKey)
        }
        if suite.data(forKey: AppGroup.inventoryKey) == nil,
           let data = legacy.data(forKey: AppGroup.inventoryKey) ?? legacy.data(forKey: "livepet.v1.inventory") {
            suite.set(data, forKey: AppGroup.inventoryKey)
        }
        suite.set(true, forKey: flag)
    }
}
