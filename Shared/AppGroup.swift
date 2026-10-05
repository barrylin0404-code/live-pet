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
        loadSaved(from: defaults)?.projected(to: date)
    }

    /// Exactly what the app / Island intents last wrote — no projection.
    static func loadSaved(from defaults: UserDefaults = AppGroup.defaults) -> PetSnapshot? {
        guard let data = defaults.data(forKey: AppGroup.snapshotKey) else { return nil }
        return try? JSONDecoder().decode(PetSnapshot.self, from: data)
    }

    /// Multi-entry Home Screen timeline: project mood every `stepMinutes` for `throughMinutes`
    /// so hungry/sad/happy sheets advance while the app is closed (pairs with catalog sheets).
    /// Also adds an entry at the exact 90 s decay unit where the mood band or nap flips, so the
    /// widget turns hungry (or wakes) when the pet does — not up to a whole step later.
    static func projectedTimeline(
        from start: Date = .now,
        stepMinutes: Int = 15,
        throughMinutes: Int = 120,
        defaults: UserDefaults = AppGroup.defaults
    ) -> [(date: Date, snapshot: PetSnapshot)] {
        guard let saved = loadSaved(from: defaults) else {
            return [(start, .placeholder)]
        }
        return saved.timeline(from: start, stepMinutes: stepMinutes, throughMinutes: throughMinutes)
    }

    /// Step entries plus band-flip entries, sorted, one per moment.
    func timeline(from start: Date, stepMinutes: Int = 15, throughMinutes: Int = 120) -> [(date: Date, snapshot: PetSnapshot)] {
        let end = start.addingTimeInterval(TimeInterval(max(0, throughMinutes) * 60))
        var dates: [Date] = []
        var minute = 0
        while minute <= throughMinutes {
            dates.append(start.addingTimeInterval(TimeInterval(minute * 60)))
            minute += max(1, stepMinutes)
        }
        let unit = PetDecay.unitSeconds
        var k = max(1, Int(start.timeIntervalSince(lastUpdated) / unit) + 1)
        var previous = projected(to: start)
        // Half a second past the unit boundary so float rounding never lands one unit short.
        while true {
            let flip = lastUpdated.addingTimeInterval(Double(k) * unit + 0.5)
            if flip > end { break }
            let snap = projected(to: flip)
            if snap.moodRaw != previous.moodRaw || snap.isSleeping != previous.isSleeping {
                dates.append(flip)
            }
            previous = snap
            k += 1
        }
        dates.sort()
        var out: [(date: Date, snapshot: PetSnapshot)] = []
        for date in dates where out.last.map({ date.timeIntervalSince($0.date) >= 1 }) ?? true {
            out.append((date, projected(to: date)))
        }
        return out
    }

    /// Same decay as `Pet.applyOfflineDecay` (`PetDecay`: a napping pet wakes at 95 energy, then
    /// decays awake). Meters + mood band only; `lastAction` and `lastUpdated` stay as written so
    /// Island blurbs keep the real last care.
    func projected(to date: Date) -> PetSnapshot {
        let units = Int(date.timeIntervalSince(lastUpdated) / PetDecay.unitSeconds)
        guard units > 0 else { return self }
        var out = self
        let after = PetDecay.apply(units: units, to: PetDecay.Meters(
            satiety: satiety, moodScore: moodScore, energy: energy,
            cleanliness: 0, isSleeping: isSleeping == true
        ))
        out.satiety = after.satiety
        out.moodScore = after.moodScore
        out.energy = after.energy
        if isSleeping != nil || after.isSleeping {
            out.isSleeping = after.isSleeping
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
