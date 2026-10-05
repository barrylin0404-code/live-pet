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
        /// Optional short stage id (`kit` | `nubby` | `nubby_plus`) — keep payload tiny.
        public var growthStage: String?
        /// Roam clock origin (`Date.timeIntervalSinceReferenceDate` when phase was 0).
        /// Lets care→walk resume at the care pose's x instead of wall-clock teleport.
        public var walkEpoch: Double?

        public init(
            speciesId: String = "nubby",
            pose: String = PetPose.idle.rawValue,
            moodBand: String = PetMood.content.rawValue,
            isSleeping: Bool = false,
            growthStage: String? = nil,
            walkEpoch: Double? = nil
        ) {
            self.speciesId = speciesId
            self.pose = pose
            self.moodBand = moodBand
            self.isSleeping = isSleeping
            self.growthStage = growthStage
            self.walkEpoch = walkEpoch
        }

        public var mood: PetMood {
            PetMood(rawValue: moodBand) ?? .content
        }

        public var petPose: PetPose {
            PetPose(rawValue: pose) ?? .idle
        }

        /// Mid return leg → xNorm 0 facing left, matching care sheets — and outside the
        /// outbound-only hop window. Mid outbound (old) landed Feed/Pet settle mid-hop.
        public static func centeredWalkEpoch(
            at t: TimeInterval = Date().timeIntervalSinceReferenceDate,
            walkLeg: TimeInterval = 1.0,
            mood: PetMood = .content
        ) -> Double {
            let pause = mood.islandEdgePause
            return t - (walkLeg + pause + walkLeg / 2)
        }

        /// Island mapping: idle → walk. Care oneshots (eat / play / clean) + sleep pass through.
        /// Does not stamp `walkEpoch` — use `islandUpdate(from:previous:)` so stroll phase
        /// survives mood ticks and only recenters after care / sleep.
        public func islandContentState() -> ContentState {
            if isSleeping || petPose == .sleep || petPose == .eat || petPose == .play || petPose == .clean {
                return self
            }
            if petPose == .walk {
                return self
            }
            return ContentState(
                speciesId: speciesId,
                pose: PetPose.walk.rawValue,
                moodBand: moodBand,
                isSleeping: isSleeping,
                growthStage: growthStage,
                walkEpoch: walkEpoch
            )
        }

        /// Merge pet → Island payload with the live Activity state.
        /// Care/sleep → walk and hungry/sad → stroll recenter at x=0; walk → walk keeps the prior epoch.
        public static func islandUpdate(from petState: ContentState, previous: ContentState?) -> ContentState {
            var next = petState.islandContentState()
            guard next.petPose == .walk else {
                next.walkEpoch = nil
                return next
            }
            let fromCare = previous.map { prev in
                prev.isSleeping
                    || prev.petPose == .eat
                    || prev.petPose == .play
                    || prev.petPose == .clean
                    || prev.petPose == .sleep
            } ?? false
            // Hungry/sad sheets sit at x=0 — leaving that hold for a stroll must recenter
            // the same way care→walk does (mood tick alone used to keep the old roam phase).
            let fromMoodHold = previous.map { prev in
                prev.mood.holdsIslandStroll
                    && !prev.isSleeping
                    && prev.petPose != .eat
                    && prev.petPose != .play
                    && prev.petPose != .clean
                    && prev.petPose != .sleep
            } ?? false
            if fromCare || (fromMoodHold && !next.mood.holdsIslandStroll) {
                next.walkEpoch = centeredWalkEpoch(mood: next.mood)
            } else if next.walkEpoch == nil {
                if let epoch = previous?.walkEpoch, previous?.petPose == .walk {
                    next.walkEpoch = epoch
                } else if previous == nil || previous?.petPose != .walk {
                    // Fresh request / first stroll — start centered, not at a random wall-clock x.
                    next.walkEpoch = centeredWalkEpoch(mood: next.mood)
                }
            }
            return next
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
    /// Bath / clean oneshot — sprite maps to idle + bubble or walk frames.
    case clean
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

    /// Island / Lock Screen: hungry & low hold a sheet instead of strolling.
    public var holdsIslandStroll: Bool {
        switch self {
        case .hungry, .low: return true
        default: return false
        }
    }

    /// Edge park length on Island stroll. Playful barely stops; happy denser than content;
    /// sleepy lingers. Shared so walkEpoch / IslandLook / Walk sims stay in sync.
    public var islandEdgePause: TimeInterval {
        switch self {
        case .playful: return 0.45
        case .happy: return 0.65
        case .sleepy: return 1.4
        default: return 0.9
        }
    }

    /// Derive a display mood from the three needs meters.
    public static func derived(moodScore: Int, satiety: Int, energy: Int) -> PetMood {
        if satiety < 25 { return .hungry }
        if energy < 20 { return .sleepy }
        if moodScore < 25 { return .low }
        // Reachable after light pets/feed (default mood 72 → one pet tap).
        if moodScore >= 70 && energy >= 40 { return .playful }
        if moodScore >= 60 && satiety >= 50 { return .happy }
        return .content
    }
}
