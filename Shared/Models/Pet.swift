import Foundation

/// In-app pet state mirrored into the Live Activity content state.
/// Needs meters: moodScore, satiety, energy — all 0...100.
/// Energy stays in the model for Sleep / decay; hide it in UI (Feeling + Satiety only).
struct Pet: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    /// Stable species / glyph key for Live Activity + widgets.
    var petGlyph: String
    var moodScore: Int
    var satiety: Int
    var energy: Int
    var lastAction: String
    var lastUpdated: Date
    var pose: PetPose
    var isSleeping: Bool
    /// First create / onboarding time — drives age days chrome.
    var createdAt: Date
    /// Internal-only cleanliness (0...100). Not shown in UI.
    var cleanliness: Int

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
        cleanliness: Int = 70
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


    var activityState: PetActivityAttributes.ContentState {
        .init(
            speciesId: petGlyph,
            pose: (isSleeping ? PetPose.sleep : pose).rawValue,
            moodBand: mood.rawValue,
            isSleeping: isSleeping
        )
    }

    mutating func feed(with item: InventoryItem) {
        isSleeping = false
        pose = .eat
        satiety = Self.clamp(satiety + item.satietyBoost)
        moodScore = Self.clamp(moodScore + item.moodBoost)
        energy = Self.clamp(energy + item.energyDelta)
        lastAction = "Ate \(item.name)"
        touch()
    }

    mutating func play(with item: InventoryItem) {
        isSleeping = false
        pose = .play
        moodScore = Self.clamp(moodScore + item.moodBoost)
        energy = Self.clamp(energy + item.energyDelta)
        satiety = Self.clamp(satiety - 8)
        lastAction = "Played with \(item.name)"
        touch()
    }

    /// Island "Pet" / play-lite — Feeling bump, pose play.
    mutating func pet() {
        isSleeping = false
        pose = .play
        moodScore = Self.clamp(moodScore + Int.random(in: 4...8))
        lastAction = "Got pets"
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
        lastAction = "\(name) took a nap"
        touch()
    }

    /// Passive decay while the app is open (per tick interval).
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
            // Return to idle after action poses; occasional walk when playful.
            if pose == .eat || pose == .play || pose == .clean {
                pose = .idle
            } else if mood == .playful, Int.random(in: 0...4) == 0 {
                pose = .walk
            } else if pose == .walk {
                pose = .idle
            }
            lastAction = "\(name) is hanging out"
        }
        touch()
    }

    /// Apply offline decay based on elapsed wall time since last update.
    mutating func applyOfflineDecay(since date: Date = .now) {
        let elapsed = date.timeIntervalSince(lastUpdated)
        guard elapsed > 0 else { return }
        // One decay unit roughly every 90 seconds offline.
        let units = Int(elapsed / 90)
        guard units > 0 else {
            lastUpdated = date
            return
        }
        if isSleeping {
            energy = Self.clamp(energy + units)
            if energy >= 95 {
                isSleeping = false
                pose = .idle
            }
        } else {
            satiety = Self.clamp(satiety - units * 2)
            moodScore = Self.clamp(moodScore - units)
            energy = Self.clamp(energy - units)
            cleanliness = Self.clamp(cleanliness - units)
        }
        lastAction = "\(name) waited for you"
        lastUpdated = date
    }

    mutating func touch() {
        lastUpdated = .now
    }

    private static func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    enum CodingKeys: String, CodingKey {
        case id, name, petGlyph, moodScore, satiety, energy
        case lastAction, lastUpdated, pose, isSleeping, createdAt, cleanliness
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
    }
}
