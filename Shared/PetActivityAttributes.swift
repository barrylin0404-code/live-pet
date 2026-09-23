import ActivityKit
import Foundation

/// Shared ActivityKit attributes for the Live Pet Dynamic Island / Lock Screen Live Activity.
public struct PetActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var mood: PetMood
        public var hunger: Int
        public var energy: Int
        public var lastAction: String
        public var updatedAt: Date

        public init(
            mood: PetMood,
            hunger: Int,
            energy: Int,
            lastAction: String,
            updatedAt: Date = .now
        ) {
            self.mood = mood
            self.hunger = max(0, min(100, hunger))
            self.energy = max(0, min(100, energy))
            self.lastAction = lastAction
            self.updatedAt = updatedAt
        }
    }

    public var petName: String
    public var speciesEmoji: String

    public init(petName: String, speciesEmoji: String) {
        self.petName = petName
        self.speciesEmoji = speciesEmoji
    }
}

public enum PetMood: String, Codable, Hashable, CaseIterable {
    case happy
    case content
    case hungry
    case sleepy
    case playful

    public var emoji: String {
        switch self {
        case .happy: return "😊"
        case .content: return "😌"
        case .hungry: return "🥺"
        case .sleepy: return "😴"
        case .playful: return "🤩"
        }
    }

    public var label: String {
        rawValue.capitalized
    }
}
