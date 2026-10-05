import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Dynamic Island / Lock Screen walking pet.
/// Side-view walk sheets, facing swapped at each edge (sheets are already flipped).
/// Frame loop driven by `TimelineView` so we never
/// spam `Activity.update` for sprite animation.
/// Care oneshots (eat / play / sleep) still come from ContentState via `update(pet:)`.
public struct IslandWalkPetView: View {
    public var mood: PetMood
    public var pose: PetPose
    public var isSleeping: Bool
    public var speciesId: String
    public var growthStage: GrowthStage
    public var scale: CGFloat
    /// When true (Island default), idle maps to walk for denser motion than a static crop.
    public var forceWalkWhenIdle: Bool
    /// Half-width of L↔R travel in points. Compact leading stays at 0 so the
    /// pet fills the pill; expanded / Lock Screen can pace.
    public var travelAmplitude: CGFloat
    /// Hard cap for this slot. Compact Dynamic Island is about 36.67 pt;
    /// a taller view can keep the Live Activity from starting.
    public var slotHeight: CGFloat

    /// ~8 fps pixel feel (6-frame side-view walk).
    private static let frameInterval: TimeInterval = 0.125
    /// Full L→R→L glide cycle (~2.0s). Facing sheet swaps at each edge.
    private static let travelPeriod: TimeInterval = 2.0
    /// Occasional idle hop only — App Lead bounce: constant hop rejected vs clip.
    private static let hopFrames: Int = 4
    /// Quiet walk between hops (~2.75s at 8fps). Occasional hop only — denser than sparse, not constant.
    private static let hopIntervalFrames: Int = 22

    public init(
        mood: PetMood,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        speciesId: String = "nubby",
        growthStage: GrowthStage = .nubby,
        scale: CGFloat = 0.5,
        forceWalkWhenIdle: Bool = true,
        travelAmplitude: CGFloat = 11,
        slotHeight: CGFloat = 36
    ) {
        self.mood = mood
        self.pose = pose
        self.isSleeping = isSleeping
        self.speciesId = speciesId
        self.growthStage = growthStage
        self.scale = scale
        self.forceWalkWhenIdle = forceWalkWhenIdle
        self.travelAmplitude = travelAmplitude
        self.slotHeight = slotHeight
    }

    private var effectivePose: PetPose {
        if isSleeping || pose == .sleep { return .sleep }
        if pose == .eat || pose == .play { return pose }
        if pose == .clean { return .clean }
        if forceWalkWhenIdle || pose == .walk { return .walk }
        return pose
    }

    public var body: some View {
        let display = effectivePose
        Group {
            if display != .walk {
                careBody(display)
            } else {
                walkBody
            }
        }
        .frame(height: slotHeight)
    }

    /// Eat, play, bath, and sleep use the same side-view sheets as the room.
    private func careBody(_ pose: PetPose) -> some View {
        let height = slotHeight
        let anim: PetAnim = switch pose {
        case .sleep: .sleeping
        case .eat: .eating
        case .play: .playing
        case .clean: .bathing
        case .idle, .walk: .idle
        }
        return TimelineView(.animation(minimumInterval: 1.0 / 6.0, paused: false)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate * 6)
            ClipPetView(
                speciesId: speciesId,
                anim: anim,
                frame: tick,
                facingLeft: false,
                displaySize: height,
                growthStage: growthStage
            )
        }
        .frame(height: height)
    }

    private var walkBody: some View {

        let height = slotHeight
        // Side-view sheets are wider than tall. A wider frame lets height fill the pill.
        let petWidth = height * 1.35
        let amp = travelAmplitude
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let frameTick = Int(t / Self.frameInterval)

            // Strict 1D triangle glide; facing swaps sheets at each edge (no mirror).
            let (xNorm, facingRight) = Self.glide(at: t, period: Self.travelPeriod)

            let frames = Self.walkFrames(speciesId: speciesId, facingRight: facingRight)
            let name = frames[frameTick % max(frames.count, 1)]

            let (squashX, squashY, hopY) = Self.hopTransform(frameTick: frameTick, side: height)

            Group {
                if Self.assetExists(name) {
                    Image(name)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: petWidth, height: height)
                } else {
                    PixelPetView(
                        mood: mood,
                        scale: min(scale, height / 104),
                        blinking: false,
                        bobOffset: 0,
                        speciesId: speciesId
                    )
                    .frame(width: petWidth, height: height)
                }
            }
            .scaleEffect(x: squashX, y: squashY)
            .offset(x: CGFloat(xNorm) * amp, y: hopY)
            .frame(width: petWidth + amp * 2, height: height)
            .clipped()
            .accessibilityLabel("\(speciesId) walking on Island, \(mood.label)")
        }
    }

    /// Triangle wave -1…1 across the capsule; `facingRight` true while moving L→R.
    /// Mirror swaps the instant we hit an edge — zero interpolated turn frames.
    private static func glide(at t: TimeInterval, period: TimeInterval) -> (xNorm: Double, facingRight: Bool) {
        let phase = t.truncatingRemainder(dividingBy: period)
        let half = period * 0.5
        if phase < half {
            let u = phase / half // 0…1
            return (-1.0 + 2.0 * u, true)
        } else {
            let u = (phase - half) / half // 0…1
            return (1.0 - 2.0 * u, false)
        }
    }

    /// Squash→stretch→land squash only during a short window every `hopIntervalFrames`.
    /// Flat walk (identity) the rest of the time — matches clip occasional idle hop.
    private static func hopTransform(frameTick: Int, side: CGFloat) -> (sx: CGFloat, sy: CGFloat, y: CGFloat) {
        let phase = frameTick % hopIntervalFrames
        guard phase < hopFrames else {
            return (1, 1, 0)
        }
        let hopAmp = max(4.0, side * 0.11)
        switch phase {
        case 0: // crouch squash
            return (1.12, 0.88, hopAmp * 0.15)
        case 1: // stretch airborne
            return (0.90, 1.14, -hopAmp)
        case 2: // peak / settle
            return (0.96, 1.06, -hopAmp * 0.55)
        default: // land squash
            return (1.10, 0.90, hopAmp * 0.25)
        }
    }

    /// Same side-view sheets as the room. Left sheets are already flipped.
    /// The widget catalog holds a tight crop so the pet fills the pill.
    private static func walkFrames(speciesId: String, facingRight: Bool) -> [String] {
        let species = speciesId == "pip" ? "pip" : "nubby"
        let dir = facingRight ? "walkRight" : "walkLeft"
        return (0..<6).map { "\(species)-\(dir)-\($0)" }
    }

    private static func assetExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }
}
