import Foundation

/// Rebuild clip engine. Views ask for a `PetAnim`; this owns FPS, looping,
/// one-shots, ping-pong, facing, and interrupt priority. It does not move the pet.
/// Asset names are `{species}-{anim}-{frame}` (e.g. `nubby-walkRight-0`).
/// Missing catalog art falls back to `{species}-idle-0` at draw time.
public enum PetAnim: String, CaseIterable, Sendable {
    case idle, idleBlink, idleLookLeft, idleLookRight, idleLookUp, idleLookDown
    case idleEarMovement, idleTailMovement, idleBreathing
    case idleSit, idleLay, idleStretch, idleYawn, idleScratch, idleGroom, idleCurious
    case idleRare1, idleRare2, idleRare3
    case walkLeft, walkRight, walkSlow, walkFast
    case runLeft, runRight
    case turnLeft, turnRight
    case hop, jump, landing
    case happy, excited, veryHappy, loveReaction, curious, surprised, confused, sad, angry, sleepy, hungry
    case eatNotice, walkToFood, eatStart, eating, eatFinish, favoriteFoodReaction
    case playStart, playing, playExcited, playFinish
    case petReaction, petHappy, doubleTapReaction, repeatedTapReaction, annoyedReaction
    case bathStart, bathing, wet, shakeWater, bathHappy, bathFinish
    case sleepyWalk, walkToBed, sleepStart, sleeping, sleepBreathing, sleepTurn, sleepDream, wakeUp, morningStretch
    case pickup, held, drop, landingAfterDrop
}

public enum PetAnimMode: Sendable, Equatable {
    case loop
    case once
    case pingPong
}

public struct PetAnimClip: Sendable, Equatable {
    public var anim: PetAnim
    public var frameCount: Int
    public var fps: Double
    public var mode: PetAnimMode
    /// Higher wins. Reactions beat idle; care one-shots beat walk.
    public var priority: Int
    public var interruptible: Bool

    public init(anim: PetAnim, frameCount: Int, fps: Double, mode: PetAnimMode, priority: Int, interruptible: Bool) {
        self.anim = anim
        self.frameCount = frameCount
        self.fps = fps
        self.mode = mode
        self.priority = priority
        self.interruptible = interruptible
    }
}

public enum PetAnimCatalog {
    public static func clip(for anim: PetAnim) -> PetAnimClip {
        switch anim {
        case .idle, .idleBreathing:
            // Designer P0 idle is 6 frames, blink on 3–4. Loop, don't ping-pong.
            return PetAnimClip(anim: anim, frameCount: 6, fps: 6, mode: .loop, priority: 0, interruptible: true)
        case .idleBlink:
            return PetAnimClip(anim: anim, frameCount: 3, fps: 10, mode: .once, priority: 1, interruptible: true)
        case .idleLookLeft, .idleLookRight, .idleLookUp, .idleLookDown,
             .idleEarMovement, .idleTailMovement, .idleSit, .idleLay,
             .idleStretch, .idleYawn, .idleScratch, .idleGroom, .idleCurious,
             .idleRare1, .idleRare2, .idleRare3:
            return PetAnimClip(anim: anim, frameCount: 6, fps: 8, mode: .once, priority: 1, interruptible: true)
        case .walkLeft, .walkRight, .walkSlow:
            return PetAnimClip(anim: anim, frameCount: 6, fps: 8, mode: .loop, priority: 2, interruptible: true)
        case .walkFast, .runLeft, .runRight, .sleepyWalk, .walkToFood, .walkToBed:
            return PetAnimClip(anim: anim, frameCount: 6, fps: 12, mode: .loop, priority: 2, interruptible: true)
        case .turnLeft, .turnRight, .hop, .landing, .landingAfterDrop:
            return PetAnimClip(anim: anim, frameCount: 4, fps: 12, mode: .once, priority: 3, interruptible: false)
        case .jump:
            return PetAnimClip(anim: anim, frameCount: 5, fps: 12, mode: .once, priority: 3, interruptible: false)
        case .eating:
            return PetAnimClip(anim: anim, frameCount: 5, fps: 8, mode: .once, priority: 5, interruptible: false)
        case .happy, .petHappy, .excited, .veryHappy, .loveReaction, .playExcited:
            return PetAnimClip(anim: anim, frameCount: 4, fps: 10, mode: .once, priority: 5, interruptible: false)
        case .playing, .bathing, .sleeping, .sleepBreathing, .held:
            return PetAnimClip(anim: anim, frameCount: 4, fps: 6, mode: .loop, priority: 4, interruptible: true)
        default:
            // One-shot reactions and care beats.
            return PetAnimClip(anim: anim, frameCount: 6, fps: 10, mode: .once, priority: 5, interruptible: false)
        }
    }

    /// Sheet name token. Eat frames are `nubby-eat-*`, not `nubby-eating-*`.
    public static func assetToken(for anim: PetAnim) -> String {
        switch anim {
        case .eating, .eatStart, .eatFinish, .eatNotice, .favoriteFoodReaction:
            return "eat"
        default:
            return anim.rawValue
        }
    }

    /// Which sheet to draw. Idle variants share the idle cycle until they have their own frames.
    /// Walk-to-food uses the directional walk sheets.
    public static func playbackAnim(_ anim: PetAnim, facingLeft: Bool) -> PetAnim {
        switch anim {
        case .walkToFood, .walkSlow, .walkFast, .sleepyWalk, .walkToBed:
            return facingLeft ? .walkLeft : .walkRight
        case .runLeft:
            return .walkLeft
        case .runRight:
            return .walkRight
        case .eating, .eatStart, .eatFinish, .eatNotice, .favoriteFoodReaction:
            return .eating
        case .happy, .petHappy, .excited, .veryHappy, .loveReaction, .playExcited, .petReaction:
            return .happy
        case .idleBlink, .idleLookLeft, .idleLookRight, .idleLookUp, .idleLookDown,
             .idleEarMovement, .idleTailMovement, .idleBreathing,
             .idleSit, .idleLay, .idleStretch, .idleYawn, .idleScratch, .idleGroom, .idleCurious,
             .idleRare1, .idleRare2, .idleRare3:
            return .idle
        default:
            return anim
        }
    }

    public static func assetName(speciesId: String, anim: PetAnim, frame: Int) -> String {
        let species = speciesId == "pip" ? "pip" : "nubby"
        return "\(species)-\(assetToken(for: anim))-\(frame)"
    }

    public static func fallbackIdleName(speciesId: String) -> String {
        speciesId == "pip" ? "pip-idle-0" : "nubby-idle-0"
    }
}

/// Clock-driven player. The view owns time and calls `advance`.
public struct PetAnimPlayer: Sendable, Equatable {
    public private(set) var anim: PetAnim
    public private(set) var frame: Int
    public private(set) var facingLeft: Bool
    public private(set) var finishedOneShot: Bool

    private var elapsed: Double
    private var pingForward: Bool

    public init(anim: PetAnim = .idle, facingLeft: Bool = false) {
        self.anim = anim
        self.frame = 0
        self.facingLeft = facingLeft
        self.finishedOneShot = false
        self.elapsed = 0
        self.pingForward = true
    }

    public var clip: PetAnimClip { PetAnimCatalog.clip(for: anim) }

    /// Returns true when the displayed frame changed.
    @discardableResult
    public mutating func advance(dt: Double) -> Bool {
        let clip = self.clip
        guard clip.frameCount > 1, clip.fps > 0, dt > 0 else { return false }
        elapsed += dt
        let step = 1.0 / clip.fps
        guard elapsed >= step else { return false }
        let ticks = Int(elapsed / step)
        elapsed -= Double(ticks) * step
        let before = frame
        for _ in 0..<ticks {
            stepFrame(clip)
        }
        return frame != before
    }

    /// Start `next` if it outranks the current clip, or `force` is set.
    /// One-shots that are not interruptible ignore lower-or-equal requests.
    public mutating func request(_ next: PetAnim, facingLeft: Bool? = nil, force: Bool = false) {
        if let facingLeft { self.facingLeft = facingLeft }
        if next == anim, !finishedOneShot, !force { return }
        let incoming = PetAnimCatalog.clip(for: next)
        let current = clip
        if !force {
            if !current.interruptible && !finishedOneShot && incoming.priority <= current.priority {
                return
            }
            if incoming.priority < current.priority && !finishedOneShot {
                return
            }
        }
        anim = next
        frame = 0
        elapsed = 0
        pingForward = true
        finishedOneShot = false
    }

    private mutating func stepFrame(_ clip: PetAnimClip) {
        let last = clip.frameCount - 1
        switch clip.mode {
        case .loop:
            frame = frame >= last ? 0 : frame + 1
        case .once:
            if frame >= last {
                finishedOneShot = true
            } else {
                frame += 1
            }
        case .pingPong:
            if pingForward {
                if frame >= last {
                    pingForward = false
                    frame = max(0, last - 1)
                } else {
                    frame += 1
                }
            } else if frame <= 0 {
                pingForward = true
                frame = min(last, 1)
            } else {
                frame -= 1
            }
        }
    }
}
