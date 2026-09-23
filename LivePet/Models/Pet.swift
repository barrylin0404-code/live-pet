import Foundation

/// In-app pet state mirrored into the Live Activity content state.
/// Needs meters: moodScore, satiety, energy — all 0...100.
struct Pet: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    /// Stable glyph key for Live Activity compact regions.
    var petGlyph: String
    var moodScore: Int
    var satiety: Int
    var energy: Int
    var lastAction: String
    var lastUpdated: Date

    init(
        id: UUID = UUID(),
        name: String = "Nubby",
        petGlyph: String = "nubby",
        moodScore: Int = 72,
        satiety: Int = 65,
        energy: Int = 80,
        lastAction: String = "Ready to hang out",
        lastUpdated: Date = .now
    ) {
        self.id = id
        self.name = name
        self.petGlyph = petGlyph
        self.moodScore = Self.clamp(moodScore)
        self.satiety = Self.clamp(satiety)
        self.energy = Self.clamp(energy)
        self.lastAction = lastAction
        self.lastUpdated = lastUpdated
    }

    var mood: PetMood {
        PetMood.derived(moodScore: moodScore, satiety: satiety, energy: energy)
    }

    var activityState: PetActivityAttributes.ContentState {
        .init(
            mood: mood,
            moodScore: moodScore,
            satiety: satiety,
            energy: energy,
            lastAction: lastAction,
            updatedAt: lastUpdated
        )
    }

    mutating func feed(with item: InventoryItem) {
        satiety = Self.clamp(satiety + item.satietyBoost)
        moodScore = Self.clamp(moodScore + item.moodBoost)
        energy = Self.clamp(energy + item.energyDelta)
        lastAction = "Ate \(item.name)"
        touch()
    }

    mutating func play(with item: InventoryItem) {
        moodScore = Self.clamp(moodScore + item.moodBoost)
        energy = Self.clamp(energy + item.energyDelta)
        satiety = Self.clamp(satiety - 8)
        lastAction = "Played with \(item.name)"
        touch()
    }

    /// Sleep / rest — restores energy, small mood bump.
    mutating func sleep() {
        energy = Self.clamp(energy + 35)
        moodScore = Self.clamp(moodScore + 6)
        lastAction = "\(name) took a nap"
        touch()
    }

    /// Passive decay while the app is open (per tick interval).
    mutating func tick() {
        satiety = Self.clamp(satiety - 2)
        moodScore = Self.clamp(moodScore - 1)
        energy = Self.clamp(energy - 1)
        lastAction = "\(name) is hanging out"
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
        satiety = Self.clamp(satiety - units * 2)
        moodScore = Self.clamp(moodScore - units)
        energy = Self.clamp(energy - units)
        lastAction = "\(name) waited for you"
        lastUpdated = date
    }

    mutating func touch() {
        lastUpdated = .now
    }

    private static func clamp(_ value: Int) -> Int {
        max(0, min(100, value))
    }
}
