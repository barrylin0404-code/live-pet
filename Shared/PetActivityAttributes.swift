import ActivityKit
import Foundation

/// Shared ActivityKit attributes for the Live Pet Dynamic Island / Lock Screen Live Activity.
public struct PetActivityAttributes: ActivityAttributes {
    /// Tiny ContentState — keep under ActivityKit size pressure; meters come from App Group snapshot.
    public struct ContentState: Codable, Hashable {
        public var speciesId: String
        public var pose: String
        public var moodBand: String
        public var isSleeping: Bool

        public init(
            speciesId: String = "nubby",
            pose: String = PetPose.idle.rawValue,
            moodBand: String = PetMood.content.rawValue,
            isSleeping: Bool = false
        ) {
            self.speciesId = speciesId
            self.pose = pose
            self.moodBand = moodBand
            self.isSleeping = isSleeping
        }

        public var mood: PetMood {
            PetMood(rawValue: moodBand) ?? .content
        }

        public var petPose: PetPose {
            PetPose(rawValue: pose) ?? .idle
        }
    }

    public var petName: String
    /// Short glyph / species key for compact Island regions.
    public var petGlyph: String

    public init(petName: String, petGlyph: String = "nubby") {
        self.petName = petName
        self.petGlyph = petGlyph
    }
}

public enum PetPose: String, Codable, Hashable, CaseIterable {
    case idle
    case walk
    case eat
    case play
    case sleep
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
