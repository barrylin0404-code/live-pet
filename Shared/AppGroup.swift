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
    static let weatherCacheKey = "livepet.v1.weatherCache"
    /// Filename inside the App Group container (not UserDefaults).
    static let petFrameFileName = "pet-frame.jpg"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var petFrameURL: URL? {
        containerURL?.appendingPathComponent(petFrameFileName)
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

    /// Widgets read the snapshot projected to `date` — a pet left alone all afternoon should not
    /// still look happy on the Home Screen because the app last wrote at lunch.
    static func load(from defaults: UserDefaults = AppGroup.defaults, at date: Date = .now) -> PetSnapshot? {
        guard let data = defaults.data(forKey: AppGroup.snapshotKey),
              let saved = try? JSONDecoder().decode(PetSnapshot.self, from: data) else { return nil }
        return saved.projected(to: date)
    }

    /// Multi-entry Home Screen timeline: project mood every `stepMinutes` for `throughMinutes`
    /// so hungry/sad/happy sheets advance while the app is closed (pairs with catalog sheets).
    static func projectedTimeline(
        from start: Date = .now,
        stepMinutes: Int = 15,
        throughMinutes: Int = 120,
        defaults: UserDefaults = AppGroup.defaults
    ) -> [(date: Date, snapshot: PetSnapshot)] {
        guard let data = defaults.data(forKey: AppGroup.snapshotKey),
              let saved = try? JSONDecoder().decode(PetSnapshot.self, from: data) else {
            return [(start, .placeholder)]
        }
        var out: [(Date, PetSnapshot)] = []
        var minute = 0
        while minute <= throughMinutes {
            let date = start.addingTimeInterval(TimeInterval(minute * 60))
            out.append((date, saved.projected(to: date)))
            minute += max(1, stepMinutes)
        }
        return out
    }

    /// Same 90 s units as `Pet.applyOfflineDecay` (meters + mood band only; `lastAction` and
    /// `lastUpdated` stay as written so Island blurbs keep the real last care).
    func projected(to date: Date) -> PetSnapshot {
        let units = Int(date.timeIntervalSince(lastUpdated) / 90)
        guard units > 0 else { return self }
        var out = self
        if isSleeping == true {
            out.energy = min(100, energy + units)
            if out.energy >= 95 { out.isSleeping = false }
        } else {
            out.satiety = max(0, satiety - units * 2)
            out.moodScore = max(0, moodScore - units)
            out.energy = max(0, energy - units)
        }
        let band: PetMood = out.isSleeping == true
            ? .sleepy
            : .derived(moodScore: out.moodScore, satiety: out.satiety, energy: out.energy)
        out.moodRaw = band.rawValue
        return out
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
