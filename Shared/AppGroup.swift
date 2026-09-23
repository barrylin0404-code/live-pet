import Foundation

/// Shared App Group used by the main app, Live Activity extension, and Home Screen widgets.
enum AppGroup {
    static let identifier = "group.com.barrylin.livepet"

    static let petKey = "livepet.v1.pet"
    static let petsKey = "livepet.v1.pets"
    static let activePetIdKey = "livepet.v1.activePetId"
    static let inventoryKey = "livepet.v1.inventory"
    static let snapshotKey = "livepet.v1.snapshot"
    static let onboardingKey = "livepet.v1.onboardingDone"
    static let sceneKey = "livepet.v1.roomScene"
    static let dailySamplesKey = "livepet.v1.dailySamples"
    static let firefliesUnlockedKey = "livepet.v1.firefliesUnlocked"
    static let showFirefliesKey = "livepet.v1.showFireflies"
    static let feelingFullDayKey = "livepet.v1.feelingFullDay"
    static let pipUnlockedKey = "livepet.v1.pipUnlocked"
    static let meetPipShownKey = "livepet.v1.meetPipShown"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

/// Lightweight pet mirror for WidgetKit timelines (readable from app + extensions).
struct PetSnapshot: Codable, Hashable, Sendable {
    var name: String
    var petGlyph: String
    var moodScore: Int
    var satiety: Int
    var energy: Int
    var moodRaw: String
    var lastAction: String
    var lastUpdated: Date
    var growthStage: String?
    var isSleeping: Bool?

    var mood: PetMood {
        PetMood(rawValue: moodRaw) ?? .content
    }

    var resolvedGrowthStage: GrowthStage {
        if let growthStage, let stage = GrowthStage(rawValue: growthStage) {
            return stage
        }
        return .nubby
    }

    static func load(from defaults: UserDefaults = AppGroup.defaults) -> PetSnapshot? {
        guard let data = defaults.data(forKey: AppGroup.snapshotKey) else { return nil }
        return try? JSONDecoder().decode(PetSnapshot.self, from: data)
    }

    func save(to defaults: UserDefaults = AppGroup.defaults) {
        if let data = try? JSONEncoder().encode(self) {
            defaults.set(data, forKey: AppGroup.snapshotKey)
        }
    }

    static var placeholder: PetSnapshot {
        PetSnapshot(
            name: "Nubby",
            petGlyph: "nubby",
            moodScore: 72,
            satiety: 65,
            energy: 80,
            moodRaw: PetMood.content.rawValue,
            lastAction: "Ready to hang out",
            lastUpdated: .now,
            growthStage: GrowthStage.kit.rawValue,
            isSleeping: false
        )
    }
}
