import Foundation
import SwiftUI
import WidgetKit

/// Owns pet + inventory, persists to the App Group, drives need decay.
@MainActor
final class PetStore: ObservableObject {
    @Published private(set) var pet: Pet
    @Published private(set) var pets: [Pet]
    @Published private(set) var items: [InventoryItem]
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var selectedScene: PetRoomScene
    @Published private(set) var firefliesUnlocked: Int
    @Published var showFireflies: Bool
    @Published private(set) var pipUnlocked: Bool
    @Published var showGrowCelebration = false
    @Published var showMeetPip = false
    @Published private(set) var lastUsedFavorite = false

    private let defaults: UserDefaults
    private var tickTask: Task<Void, Never>?
    private var dailySamples: [DailyMeterSample]

    /// Called whenever pet state changes so Live Activity can sync.
    var onPetChange: ((Pet) -> Void)?

    init(defaults: UserDefaults = AppGroup.defaults) {
        self.defaults = defaults
        Self.migrateFromStandardIfNeeded(into: defaults)

        hasCompletedOnboarding = defaults.bool(forKey: AppGroup.onboardingKey)
        firefliesUnlocked = defaults.object(forKey: AppGroup.firefliesUnlockedKey) as? Int ?? 0
        if defaults.object(forKey: AppGroup.showFirefliesKey) == nil {
            showFireflies = true
        } else {
            showFireflies = defaults.bool(forKey: AppGroup.showFirefliesKey)
        }
        pipUnlocked = defaults.bool(forKey: AppGroup.pipUnlockedKey)

        if let raw = defaults.string(forKey: AppGroup.sceneKey),
           let scene = PetRoomScene(rawValue: raw) {
            selectedScene = scene
        } else {
            selectedScene = .sunNook
        }

        if let data = defaults.data(forKey: AppGroup.dailySamplesKey),
           let saved = try? JSONDecoder().decode([DailyMeterSample].self, from: data) {
            dailySamples = saved
        } else {
            dailySamples = []
        }

        if let data = defaults.data(forKey: AppGroup.petsKey),
           let saved = try? JSONDecoder().decode([Pet].self, from: data), !saved.isEmpty {
            pets = saved
        } else if let data = defaults.data(forKey: AppGroup.petKey),
                  let saved = try? JSONDecoder().decode(Pet.self, from: data) {
            pets = [saved]
        } else {
            pets = []
        }

        if let activeId = defaults.string(forKey: AppGroup.activePetIdKey),
           let match = pets.first(where: { $0.id.uuidString == activeId }) {
            pet = match
        } else if let first = pets.first {
            pet = first
        } else {
            pet = Pet()
        }

        if !pets.isEmpty, !hasCompletedOnboarding {
            hasCompletedOnboarding = true
            defaults.set(true, forKey: AppGroup.onboardingKey)
        }

        if let data = defaults.data(forKey: AppGroup.inventoryKey),
           let saved = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            items = Self.mergeCatalog(into: saved)
        } else {
            items = InventoryItem.catalog
        }

        if hasCompletedOnboarding {
            pet.applyOfflineDecay()
            syncActiveIntoPets()
            recordDailySample()
            evaluateFireflies()
            persist()
        }
    }

    var foods: [InventoryItem] { items.filter(\.isFood) }
    var toys: [InventoryItem] { items.filter(\.isToy) }
    var careItems: [InventoryItem] { items.filter(\.isCare) }

    /// True when active Nubby can Grow (user copy: Grow — never Evolve).
    var isGrowEligible: Bool {
        guard pet.petGlyph == "nubby", pet.growthStage.next != nil else { return false }
        switch pet.growthStage {
        case .kit:
            return pet.ageDays >= 3 && rollingAverage(days: 2, moodAtLeast: 55, satietyAtLeast: 55)
        case .nubby:
            return pet.ageDays >= 7 && rollingAverage(days: 3, moodAtLeast: 60, satietyAtLeast: 60)
        case .nubbyPlus:
            return false
        }
    }

    var growBannerTitle: String { "\(pet.name)’s ready to grow!" }

    var lovesSummary: String {
        let food = items.first(where: { $0.id == pet.favoriteFoodId })?.name ?? "Fish biscuit"
        let toy = items.first(where: { $0.id == pet.favoriteToyId })?.name ?? "Bounce Block"
        return "Loves: \(food) · \(toy)"
    }

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

    func completeOnboarding(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "Nubby" : String(trimmed.prefix(16))
        pet = Pet(name: finalName, petGlyph: "nubby", createdAt: .now, growthStage: .kit)
        pets = [pet]
        items = InventoryItem.catalog
        hasCompletedOnboarding = true
        firefliesUnlocked = 0
        pipUnlocked = false
        defaults.set(true, forKey: AppGroup.onboardingKey)
        defaults.set(false, forKey: AppGroup.pipUnlockedKey)
        defaults.set(0, forKey: AppGroup.firefliesUnlockedKey)
        defaults.set(false, forKey: AppGroup.meetPipShownKey)
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

    func setScene(_ scene: PetRoomScene) {
        selectedScene = scene
        defaults.set(scene.rawValue, forKey: AppGroup.sceneKey)
    }

    func setShowFireflies(_ on: Bool) {
        showFireflies = on
        defaults.set(on, forKey: AppGroup.showFirefliesKey)
    }

    func setActivePet(id: UUID) {
        guard let match = pets.first(where: { $0.id == id }) else { return }
        syncActiveIntoPets()
        pet = match
        defaults.set(id.uuidString, forKey: AppGroup.activePetIdKey)
        commit()
    }

    func feed(itemID: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID && $0.isFood }) else { return }
        guard items[index].quantity > 0 else { return }
        let item = items[index]
        lastUsedFavorite = pet.isFavoriteFood(item.id)
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
        lastUsedFavorite = pet.isFavoriteToy(items[index].id)
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

    func clean() {
        var usedSoap = false
        if let index = items.firstIndex(where: { $0.id == "bubble_soap" && $0.quantity > 0 }) {
            items[index].quantity -= 1
            usedSoap = true
        }
        lastUsedFavorite = false
        pet.clean(usingSoap: usedSoap)
        commit()
    }

    func sleep() {
        lastUsedFavorite = false
        pet.sleep()
        commit()
    }

    /// Confirm Grow from banner — celebration sheet follows. Never say Evolve.
    func confirmGrow() {
        guard isGrowEligible else { return }
        let wasFirstGrow = pet.growthStage == .kit
        guard pet.applyGrow() else { return }
        if wasFirstGrow {
            pipUnlocked = true
            defaults.set(true, forKey: AppGroup.pipUnlockedKey)
            firefliesUnlocked = max(firefliesUnlocked, 2)
            defaults.set(firefliesUnlocked, forKey: AppGroup.firefliesUnlockedKey)
        }
        showGrowCelebration = true
        commit()
    }

    func dismissGrowCelebration() {
        showGrowCelebration = false
        if pipUnlocked && !defaults.bool(forKey: AppGroup.meetPipShownKey) {
            showMeetPip = true
        }
    }

    func meetPip(switchActive: Bool) {
        defaults.set(true, forKey: AppGroup.meetPipShownKey)
        showMeetPip = false
        if !pets.contains(where: { $0.petGlyph == "pip" }) {
            let pip = Pet.makePip()
            pets.append(pip)
            if switchActive {
                pet = pip
                defaults.set(pip.id.uuidString, forKey: AppGroup.activePetIdKey)
            }
        } else if switchActive, let pip = pets.first(where: { $0.petGlyph == "pip" }) {
            pet = pip
            defaults.set(pip.id.uuidString, forKey: AppGroup.activePetIdKey)
        }
        commit()
    }

    func skipMeetPip() {
        defaults.set(true, forKey: AppGroup.meetPipShownKey)
        showMeetPip = false
        if !pets.contains(where: { $0.petGlyph == "pip" }) {
            pets.append(Pet.makePip())
        }
        commit()
    }

    func resetAll() {
        stopTicking()
        pet = Pet()
        pets = []
        items = InventoryItem.catalog
        selectedScene = .sunNook
        hasCompletedOnboarding = false
        firefliesUnlocked = 0
        pipUnlocked = false
        showGrowCelebration = false
        showMeetPip = false
        dailySamples = []
        defaults.set(false, forKey: AppGroup.onboardingKey)
        defaults.set(PetRoomScene.sunNook.rawValue, forKey: AppGroup.sceneKey)
        defaults.set(0, forKey: AppGroup.firefliesUnlockedKey)
        defaults.set(false, forKey: AppGroup.pipUnlockedKey)
        defaults.set(false, forKey: AppGroup.meetPipShownKey)
        for key in [AppGroup.petKey, AppGroup.petsKey, AppGroup.activePetIdKey,
                    AppGroup.inventoryKey, AppGroup.snapshotKey, AppGroup.dailySamplesKey,
                    AppGroup.feelingFullDayKey] {
            defaults.removeObject(forKey: key)
        }
        WidgetCenter.shared.reloadAllTimelines()
        onPetChange?(pet)
    }

    private func applyTick() {
        pet.tick()
        recordDailySample()
        evaluateFireflies()
        commit()
    }

    private func commit() {
        syncActiveIntoPets()
        recordDailySample()
        evaluateFireflies()
        persist()
        onPetChange?(pet)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func syncActiveIntoPets() {
        if let idx = pets.firstIndex(where: { $0.id == pet.id }) {
            pets[idx] = pet
        } else if hasCompletedOnboarding {
            pets.append(pet)
        }
    }

    private func persist() {
        syncActiveIntoPets()
        if let data = try? JSONEncoder().encode(pet) {
            defaults.set(data, forKey: AppGroup.petKey)
        }
        if let data = try? JSONEncoder().encode(pets) {
            defaults.set(data, forKey: AppGroup.petsKey)
        }
        defaults.set(pet.id.uuidString, forKey: AppGroup.activePetIdKey)
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: AppGroup.inventoryKey)
        }
        if let data = try? JSONEncoder().encode(dailySamples) {
            defaults.set(data, forKey: AppGroup.dailySamplesKey)
        }
        defaults.set(selectedScene.rawValue, forKey: AppGroup.sceneKey)
        defaults.set(firefliesUnlocked, forKey: AppGroup.firefliesUnlockedKey)
        defaults.set(showFireflies, forKey: AppGroup.showFirefliesKey)
        defaults.set(pipUnlocked, forKey: AppGroup.pipUnlockedKey)
        PetSnapshot(
            name: pet.name,
            petGlyph: pet.petGlyph,
            moodScore: pet.moodScore,
            satiety: pet.satiety,
            energy: pet.energy,
            moodRaw: pet.mood.rawValue,
            lastAction: pet.lastAction,
            lastUpdated: pet.lastUpdated,
            growthStage: pet.growthStage.rawValue,
            isSleeping: pet.isSleeping
        ).save(to: defaults)
    }

    private func recordDailySample() {
        let day = Calendar.current.startOfDay(for: .now)
        if let idx = dailySamples.firstIndex(where: { Calendar.current.isDate($0.dayStart, inSameDayAs: day) }) {
            dailySamples[idx].moodScore = pet.moodScore
            dailySamples[idx].satiety = pet.satiety
        } else {
            dailySamples.append(DailyMeterSample(dayStart: day, moodScore: pet.moodScore, satiety: pet.satiety))
        }
        dailySamples.sort { $0.dayStart < $1.dayStart }
        if dailySamples.count > 14 {
            dailySamples = Array(dailySamples.suffix(14))
        }
    }

    private func rollingAverage(days: Int, moodAtLeast: Int, satietyAtLeast: Int) -> Bool {
        recordDailySample()
        let recent = Array(dailySamples.suffix(days))
        guard recent.count >= days else { return false }
        let moodAvg = recent.map(\.moodScore).reduce(0, +) / recent.count
        let satietyAvg = recent.map(\.satiety).reduce(0, +) / recent.count
        return moodAvg >= moodAtLeast && satietyAvg >= satietyAtLeast
    }

    /// Fireflies A after Feeling full one calendar day; B after first Grow.
    private func evaluateFireflies() {
        if pet.moodScore >= 75 {
            let today = Calendar.current.startOfDay(for: .now)
            if let stamped = defaults.object(forKey: AppGroup.feelingFullDayKey) as? Date {
                if stamped < today {
                    firefliesUnlocked = max(firefliesUnlocked, 1)
                }
            } else {
                defaults.set(today, forKey: AppGroup.feelingFullDayKey)
            }
        }
        if pet.growthStage != .kit {
            firefliesUnlocked = max(firefliesUnlocked, 2)
        }
    }

    private static func mergeCatalog(into saved: [InventoryItem]) -> [InventoryItem] {
        var merged = saved
        for item in InventoryItem.catalog where !merged.contains(where: { $0.id == item.id }) {
            merged.append(item)
        }
        return merged
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
