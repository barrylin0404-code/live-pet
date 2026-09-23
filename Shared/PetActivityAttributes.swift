import ActivityKit
import Foundation

/// Shared ActivityKit attributes for the Live Pet Dynamic Island / Lock Screen Live Activity.
public struct PetActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var mood: PetMood
        public var moodScore: Int
        public var satiety: Int
        public var energy: Int
        public var lastAction: String
        public var updatedAt: Date

        public init(
            mood: PetMood,
            moodScore: Int,
            satiety: Int,
            energy: Int,
            lastAction: String,
            updatedAt: Date = .now
        ) {
            self.mood = mood
            self.moodScore = max(0, min(100, moodScore))
            self.satiety = max(0, min(100, satiety))
            self.energy = max(0, min(100, energy))
            self.lastAction = lastAction
            self.updatedAt = updatedAt
        }
    }

    public var petName: String
    /// Short glyph shown in compact Island regions (SF Symbol name or emoji-free mark).
    public var petGlyph: String

    public init(petName: String, petGlyph: String = "nubby") {
        self.petName = petName
        self.petGlyph = petGlyph
    }
}

public enum PetMood: String, Codable, Hashable, CaseIterable {
    case happy
    case content
    case hungry
    case sleepy
    case playful
    case low

    public var symbolName: String {
        switch self {
        case .happy: return "face.smiling"
        case .content: return "leaf"
        case .hungry: return "fork.knife"
        case .sleepy: return "moon.zzz"
        case .playful: return "sparkles"
        case .low: return "cloud.rain"
        }
    }

    public var label: String {
        switch self {
        case .happy: return "Happy"
        case .content: return "Content"
        case .hungry: return "Hungry"
        case .sleepy: return "Sleepy"
        case .playful: return "Playful"
        case .low: return "Needs care"
        }
    }

    /// Derive a display mood from the three needs meters.
    public static func derived(moodScore: Int, satiety: Int, energy: Int) -> PetMood {
        if satiety < 25 { return .hungry }
        if energy < 20 { return .sleepy }
        if moodScore < 25 { return .low }
        if moodScore >= 75 && energy >= 50 { return .playful }
        if moodScore >= 60 && satiety >= 50 { return .happy }
        return .content
    }
}
