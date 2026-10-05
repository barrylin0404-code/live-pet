import Foundation

/// In-app pet state mirrored into the Live Activity content state.
/// Needs meters: moodScore, satiety, energy — all 0...100.
/// Energy stays in the model for Sleep / decay; hide it in UI (Feeling + Satiety only).
struct Pet: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    /// Stable species / glyph key for Live Activity + widgets (`nubby` | `pip`).
    var petGlyph: String
    var moodScore: Int
    var satiety: Int
    var energy: Int
    var lastAction: String {
        didSet { blurbTicks = 0 }
    }
    /// Ticks (20s each) since `lastAction` was written. Not saved — a fresh launch starts at 0.
    private(set) var blurbTicks: Int = 0
    var lastUpdated: Date
    var pose: PetPose
    var isSleeping: Bool
    /// First create / onboarding time — drives age days chrome.
    var createdAt: Date
    /// Internal-only cleanliness (0...100). Not shown in UI.
    var cleanliness: Int
    /// Nubby line only: kit → nubby → nubby_plus. Pip keeps `.nubby` (unused visually).
    var growthStage: GrowthStage
    var favoriteFoodId: String?
    var favoriteToyId: String?

    init(
        id: UUID = UUID(),
        name: String = "Nubby",
        petGlyph: String = "nubby",
        moodScore: Int = 72,
        satiety: Int = 65,
        energy: Int = 80,
        lastAction: String = "Ready to hang out",
        lastUpdated: Date = .now,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        createdAt: Date = .now,
        cleanliness: Int = 70,
        growthStage: GrowthStage = .kit,
        favoriteFoodId: String? = nil,
        favoriteToyId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.petGlyph = petGlyph
        self.moodScore = Self.clamp(moodScore)
        self.satiety = Self.clamp(satiety)
        self.energy = Self.clamp(energy)
        self.lastAction = lastAction
        self.lastUpdated = lastUpdated
        self.pose = pose
        self.isSleeping = isSleeping
        self.createdAt = createdAt
        self.cleanliness = Self.clamp(cleanliness)
        self.growthStage = petGlyph == "pip" ? .nubby : growthStage
        self.favoriteFoodId = favoriteFoodId ?? Self.defaultFavoriteFood(for: petGlyph)
        self.favoriteToyId = favoriteToyId ?? Self.defaultFavoriteToy(for: petGlyph)
    }

    var mood: PetMood {
        if isSleeping { return .sleepy }
        return PetMood.derived(moodScore: moodScore, satiety: satiety, energy: energy)
    }

    /// Designer lock: max(1, daysBetween(createdAt, now) + 1) using start-of-day calendar math.
    var ageDays: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: createdAt)
        let end = cal.startOfDay(for: .now)
        let days = cal.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, days + 1)
    }

    var speciesDisplayName: String {
        switch petGlyph {
        case "pip": return "Pip"
        default: return growthStage.displayName
        }
    }

    /// Used by PetLiveActivityManager — leave property name stable.
    var activityState: PetActivityAttributes.ContentState {
        .init(
            speciesId: petGlyph,
            pose: (isSleeping ? PetPose.sleep : pose).rawValue,
            moodBand: mood.rawValue,
            isSleeping: isSleeping,
            growthStage: growthStage.rawValue
        )
    }

    func isFavoriteFood(_ id: String) -> Bool { favoriteFoodId == id }
    func isFavoriteToy(_ id: String) -> Bool { favoriteToyId == id }

    mutating func feed(with item: InventoryItem) {
        isSleeping = false
        pose = .eat
        let favorite = isFavoriteFood(item.id)
        // Favorite: +15 vs +10 on the primary care bump (delta +5 on top of item boosts).
        let favoriteExtra = favorite ? 5 : 0
        satiety = Self.clamp(satiety + item.satietyBoost + favoriteExtra)
        moodScore = Self.clamp(moodScore + item.moodBoost + (favorite ? 5 : 0))
        energy = Self.clamp(energy + item.energyDelta)
        lastAction = favorite ? "Loved \(item.name)!" : "Ate \(item.name)"
        touch()
    }

    mutating func play(with item: InventoryItem) {
        isSleeping = false
        pose = .play
        let favorite = isFavoriteToy(item.id)
        let favoriteExtra = favorite ? 5 : 0
        moodScore = Self.clamp(moodScore + item.moodBoost + favoriteExtra)
        energy = Self.clamp(energy + item.energyDelta)
        satiety = Self.clamp(satiety - 8)
        lastAction = favorite ? "Loved \(item.name)!" : "Played with \(item.name)"
        touch()
    }

    /// Follow the wand — free lure, not an inventory toy. Lighter than a toy, own blurb.
    mutating func chaseWand() {
        isSleeping = false
        pose = .play
        moodScore = Self.clamp(moodScore + 12)
        energy = Self.clamp(energy - 6)
        satiety = Self.clamp(satiety - 4)
        lastAction = "Chased the wand!"
        touch()
    }

    /// Island "Pet" / play-lite — Feeling bump, pose play.
    mutating func pet() {
        isSleeping = false
        pose = .play
        moodScore = Self.clamp(moodScore + Int.random(in: 4...8))
        // Small energy lift so playful (mood≥70, energy≥40) stays reachable after toys.
        energy = Self.clamp(energy + Int.random(in: 1...3))
        lastAction = "Feeling warmer"
        touch()
    }

    /// Bath / Clean — Feeling +5…10; cleanliness internal only.
    mutating func clean(usingSoap: Bool = false) {
        isSleeping = false
        pose = .clean
        let bump = usingSoap ? Int.random(in: 8...10) : Int.random(in: 5...10)
        moodScore = Self.clamp(moodScore + bump)
        cleanliness = Self.clamp(cleanliness + (usingSoap ? 40 : 25))
        lastAction = usingSoap ? "Got a soapy bath" : "Got a bath"
        touch()
    }

    /// Sleep / rest — restores energy, small mood bump. ("Tuck in")
    mutating func sleep() {
        isSleeping = true
        pose = .sleep
        energy = Self.clamp(energy + 35)
        moodScore = Self.clamp(moodScore + 6)
        lastAction = "\(name) tucked in"
        touch()
    }

    /// Wake from a nap — Sleep dock toggles; care can wake then act.
    mutating func wake() {
        guard isSleeping else { return }
        isSleeping = false
        pose = .idle
        lastAction = "\(name) woke up"
        touch()
    }

    /// Apply Grow to the next stage (Nubby line only). User copy: Grow / All grown — never Evolve.
    @discardableResult
    mutating func applyGrow() -> Bool {
        guard petGlyph == "nubby", let next = growthStage.next else { return false }
        growthStage = next
        isSleeping = false
        pose = .idle
        moodScore = Self.clamp(moodScore + 10)
        lastAction = "\(name) grew!"
        touch()
        return true
    }

    mutating func tick() {
        if isSleeping {
            energy = Self.clamp(energy + 2)
            if energy >= 95 {
                isSleeping = false
                pose = .idle
                lastAction = "\(name) woke up"
            } else {
                lastAction = "\(name) is sleeping"
            }
        } else {
            satiety = Self.clamp(satiety - 2)
            moodScore = Self.clamp(moodScore - 1)
            energy = Self.clamp(energy - 1)
            cleanliness = Self.clamp(cleanliness - 1)
            if pose == .eat || pose == .play || pose == .clean {
                pose = .idle
            } else if mood == .playful, Int.random(in: 0...4) == 0 {
                pose = .walk
            } else if pose == .walk {
                pose = .idle
            }
            awakeTickBlurb()
        }
        touch()
    }

    /// Island / Lock Screen line between care beats. A care line ("Caught 3 islands!",
    /// "Loved Fish!") holds ~1 min instead of being stomped by the next 20s tick; a hungry or
    /// low pet says so; a stale line or a leftover sleep line falls back to hanging out.
    private mutating func awakeTickBlurb() {
        let hangingOut = "\(name) is hanging out"
        let line: String
        switch mood {
        case .hungry:
            line = "\(name) is hungry"
        case .low:
            line = "\(name) needs care"
        default:
            let sleepLine = lastAction == "\(name) is sleeping" || lastAction == "\(name) tucked in"
            line = (blurbTicks >= 3 || sleepLine || lastAction.isEmpty) ? hangingOut : lastAction
        }
        if line == lastAction {
            blurbTicks += 1
        } else {
            lastAction = line
        }
    }

    mutating func applyOfflineDecay(from date: Date) {
        let elapsed = date.timeIntervalSince(lastUpdated)
        guard elapsed > 0 else { return }
        let units = Int(elapsed / PetDecay.unitSeconds)
        guard units > 0 else {
            lastUpdated = date
            return
        }
        let wasSleeping = isSleeping
        let after = PetDecay.apply(units: units, to: PetDecay.Meters(
            satiety: satiety, moodScore: moodScore, energy: energy,
            cleanliness: cleanliness, isSleeping: isSleeping
        ))
        satiety = after.satiety
        moodScore = after.moodScore
        energy = after.energy
        cleanliness = after.cleanliness
        isSleeping = after.isSleeping
        if wasSleeping && !isSleeping {
            pose = .idle
        }
        // Short hops (Control Center, a quick Island tap) keep the last care blurb;
        // only a real absence (~30 min+) reads as waiting.
        if units >= 20 {
            lastAction = isSleeping ? "\(name) is sleeping" : "\(name) waited for you"
        } else if wasSleeping && !isSleeping {
            lastAction = "\(name) woke up"
        }
        lastUpdated = date
    }

    mutating func applyOfflineDecay() {
        applyOfflineDecay(from: .now)
    }

    mutating func touch() {
        lastUpdated = .now
    }

    private static func clamp(_ value: Int) -> Int { max(0, min(100, value)) }

    static func defaultFavoriteFood(for species: String) -> String {
        species == "pip" ? "berry" : "fish"
    }

    static func defaultFavoriteToy(for species: String) -> String {
        species == "pip" ? "twinkle_ball" : "bounce_block"
    }

    static func makePip(name: String = "Pip") -> Pet {
        Pet(
            name: name,
            petGlyph: "pip",
            moodScore: 70,
            satiety: 70,
            energy: 80,
            lastAction: "Pip is ready to hang out",
            growthStage: .nubby
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, name, petGlyph, moodScore, satiety, energy
        case lastAction, lastUpdated, pose, isSleeping, createdAt, cleanliness
        case growthStage, favoriteFoodId, favoriteToyId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        petGlyph = try c.decodeIfPresent(String.self, forKey: .petGlyph) ?? "nubby"
        moodScore = Self.clamp(try c.decode(Int.self, forKey: .moodScore))
        satiety = Self.clamp(try c.decode(Int.self, forKey: .satiety))
        energy = Self.clamp(try c.decode(Int.self, forKey: .energy))
        lastAction = try c.decode(String.self, forKey: .lastAction)
        lastUpdated = try c.decode(Date.self, forKey: .lastUpdated)
        pose = try c.decodeIfPresent(PetPose.self, forKey: .pose) ?? .idle
        isSleeping = try c.decodeIfPresent(Bool.self, forKey: .isSleeping) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? lastUpdated
        cleanliness = Self.clamp(try c.decodeIfPresent(Int.self, forKey: .cleanliness) ?? 70)
        if let raw = try c.decodeIfPresent(String.self, forKey: .growthStage),
           let stage = GrowthStage(rawValue: raw) {
            growthStage = stage
        } else {
            growthStage = .nubby
        }
        favoriteFoodId = try c.decodeIfPresent(String.self, forKey: .favoriteFoodId)
            ?? Self.defaultFavoriteFood(for: petGlyph)
        favoriteToyId = try c.decodeIfPresent(String.self, forKey: .favoriteToyId)
            ?? Self.defaultFavoriteToy(for: petGlyph)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(petGlyph, forKey: .petGlyph)
        try c.encode(moodScore, forKey: .moodScore)
        try c.encode(satiety, forKey: .satiety)
        try c.encode(energy, forKey: .energy)
        try c.encode(lastAction, forKey: .lastAction)
        try c.encode(lastUpdated, forKey: .lastUpdated)
        try c.encode(pose, forKey: .pose)
        try c.encode(isSleeping, forKey: .isSleeping)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(cleanliness, forKey: .cleanliness)
        try c.encode(growthStage.rawValue, forKey: .growthStage)
        try c.encodeIfPresent(favoriteFoodId, forKey: .favoriteFoodId)
        try c.encodeIfPresent(favoriteToyId, forKey: .favoriteToyId)
    }
}

/// Time-away decay in 90 s units, shared by `Pet.applyOfflineDecay` (app / Island intents) and
/// `PetSnapshot.projected` (widgets, Island mood) so they never disagree.
/// A pet asleep for part of the absence gains energy until it wakes at 95 — same as `Pet.tick` —
/// then decays awake for the rest. It used to count the whole absence as sleep, so a nap froze
/// Satiety / Feeling and a pet tucked in at noon still read fed and content at dinner.
enum PetDecay {
    static let unitSeconds: TimeInterval = 90
    static let wakeEnergy = 95

    struct Meters: Equatable {
        var satiety: Int
        var moodScore: Int
        var energy: Int
        var cleanliness: Int
        var isSleeping: Bool
    }

    static func apply(units: Int, to meters: Meters) -> Meters {
        guard units > 0 else { return meters }
        var out = meters
        var awakeUnits = units
        if out.isSleeping {
            let toWake = max(0, wakeEnergy - out.energy)
            if units < toWake {
                out.energy = clamp(out.energy + units)
                return out
            }
            out.energy = clamp(out.energy + toWake)
            out.isSleeping = false
            awakeUnits = units - toWake
        }
        out.satiety = clamp(out.satiety - awakeUnits * 2)
        out.moodScore = clamp(out.moodScore - awakeUnits)
        out.energy = clamp(out.energy - awakeUnits)
        out.cleanliness = clamp(out.cleanliness - awakeUnits)
        return out
    }

    private static func clamp(_ value: Int) -> Int { max(0, min(100, value)) }
}
