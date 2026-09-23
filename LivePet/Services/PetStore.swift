import Foundation
import SwiftUI

/// Owns pet + inventory, persists to UserDefaults, drives need decay.
@MainActor
final class PetStore: ObservableObject {
    @Published private(set) var pet: Pet
    @Published private(set) var items: [InventoryItem]

    private let defaults: UserDefaults
    private let petKey = "livepet.v1.pet"
    private let inventoryKey = "livepet.v1.inventory"
    private var tickTask: Task<Void, Never>?

    /// Called whenever pet state changes so Live Activity can sync.
    var onPetChange: ((Pet) -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: petKey),
           let saved = try? JSONDecoder().decode(Pet.self, from: data) {
            self.pet = saved
        } else {
            self.pet = Pet()
        }
        if let data = defaults.data(forKey: inventoryKey),
           let saved = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            self.items = saved
        } else {
            self.items = InventoryItem.catalog
        }
        self.pet.applyOfflineDecay()
        persist()
    }

    var foods: [InventoryItem] { items.filter(\.isFood) }
    var toys: [InventoryItem] { items.filter(\.isToy) }

    func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000) // 20s
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.applyTick()
                }
            }
        }
    }

    func stopTicking() {
        tickTask?.cancel()
        tickTask = nil
    }

    func feed(itemID: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID && $0.isFood }) else { return }
        guard items[index].quantity > 0 else { return }
        let item = items[index]
        items[index].quantity -= 1
        pet.feed(with: item)
        // Soft refill so v1 never soft-locks the player out of food.
        if items[index].quantity == 0 {
            items[index].quantity = 1
            pet.lastAction = "Ate \(item.name) · crumb restocked"
        }
        commit()
    }

    func play(itemID: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID && $0.isToy }) else { return }
        guard items[index].quantity > 0 else { return }
        // Toys are reusable in v1 (quantity stays); still require owning at least 1.
        pet.play(with: items[index])
        commit()
    }

    /// Convenience: feed with the first available food.
    func feedDefault() {
        if let food = foods.first(where: { $0.quantity > 0 }) {
            feed(itemID: food.id)
        }
    }

    /// Convenience: play with the first owned toy.
    func playDefault() {
        if let toy = toys.first(where: { $0.quantity > 0 }) {
            play(itemID: toy.id)
        }
    }

    func sleep() {
        pet.sleep()
        commit()
    }

    func resetToDefaults() {
        pet = Pet()
        items = InventoryItem.catalog
        commit()
    }

    private func applyTick() {
        pet.tick()
        commit()
    }

    private func commit() {
        persist()
        onPetChange?(pet)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(pet) {
            defaults.set(data, forKey: petKey)
        }
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: inventoryKey)
        }
    }
}
