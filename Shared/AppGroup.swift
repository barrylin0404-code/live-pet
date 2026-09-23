import Foundation

/// Shared App Group used by the main app, Live Activity extension, and Home Screen widgets.
enum AppGroup {
    static let identifier = "group.com.barrylin.livepet"

    static let petKey = "livepet.v1.pet"
    static let inventoryKey = "livepet.v1.inventory"
    static let snapshotKey = "livepet.v1.snapshot"
    static let onboardingKey = "livepet.v1.onboardingDone"

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

    var mood: PetMood {
        PetMood(rawValue: moodRaw) ?? .content
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
            lastUpdated: .now
        )
    }
}
