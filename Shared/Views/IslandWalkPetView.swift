import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Dynamic Island / Lock Screen walking pet.
/// Strict 1D horizontal glide across the capsule with *instant* facing mirror at each
/// edge (zero turn frames). Frame loop + pace driven by `TimelineView` so we never
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
    /// Half-width of L↔R travel in points. Compact leading needs visible pace in-slot;
    /// expanded / Lock Screen can use a wider range.
    public var travelAmplitude: CGFloat

    /// ~8 fps pixel feel (4-frame walk sheet).
    private static let frameInterval: TimeInterval = 0.125
    /// Full L→R→L glide cycle (~2.0s). Instant mirror at edges.
    private static let travelPeriod: TimeInterval = 2.0
    /// Occasional idle hop only — App Lead bounce: constant hop rejected vs clip.
    private static let hopFrames: Int = 4
    /// Quiet walk between hops (~4.5s at 8fps).
    private static let hopIntervalFrames: Int = 36

    public init(
        mood: PetMood,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        speciesId: String = "nubby",
        growthStage: GrowthStage = .nubby,
        scale: CGFloat = 0.5,
        forceWalkWhenIdle: Bool = true,
        travelAmplitude: CGFloat = 11
    ) {
        self.mood = mood
        self.pose = pose
        self.isSleeping = isSleeping
        self.speciesId = speciesId
        self.growthStage = growthStage
        self.scale = scale
        self.forceWalkWhenIdle = forceWalkWhenIdle
        self.travelAmplitude = travelAmplitude
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
        if display != .walk {
            AnimatedPixelPetView(
                mood: mood,
                pose: display,
                isSleeping: display == .sleep,
                scale: scale,
                preferIslandCrop: false,
                speciesId: speciesId,
                growthStage: growthStage
            )
        } else {
            walkBody
        }
    }

    private var walkBody: some View {
        let stageScale = CGFloat(growthStage.bodyScaleMultiplier)
        // Large scales from d3d51dd kept (side = 40 * scale * stage * 3).
        let side = 40 * scale * stageScale * 3
        let amp = travelAmplitude
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let frameTick = Int(t / Self.frameInterval)

            // Strict 1D triangle glide; facing flips instantly at each edge (no turn frames).
            let (xNorm, facingRight) = Self.glide(at: t, period: Self.travelPeriod)

            let frames = Self.walkFrames(speciesId: speciesId, growthStage: growthStage)
            let name = frames[frameTick % max(frames.count, 1)]

            // Occasional idle hop (not every walk cycle) — flat glide most of the time.
            let (squashX, squashY, hopY) = Self.hopTransform(frameTick: frameTick, side: side)

            Group {
                if Self.assetExists(name) {
                    Image(name)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: side, height: side)
                } else {
                    PixelPetView(
                        mood: mood,
                        scale: scale * stageScale,
                        blinking: false,
                        bobOffset: hopY * 0.15,
                        speciesId: speciesId
                    )
                }
            }
            .scaleEffect(x: (facingRight ? 1 : -1) * squashX, y: squashY)
            .offset(x: CGFloat(xNorm) * amp, y: hopY)
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
        let hopAmp = max(3.5, side * 0.10)
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

    private static func walkFrames(speciesId: String, growthStage: GrowthStage) -> [String] {
        if speciesId == "pip" {
            return ["pip-idle-0", "pip-idle-1", "pip-idle-2", "pip-idle-3"]
        }
        switch growthStage {
        case .kit:
            return firstExisting(
                ["nubby-walk-0", "nubby-walk-1", "nubby-walk-2", "nubby-walk-3"],
                fallback: ["nubby-kit-idle-0", "nubby-kit-idle-1", "nubby-kit-idle-2", "nubby-kit-idle-3"]
            )
        case .nubbyPlus:
            return firstExisting(
                ["nubby-walk-0", "nubby-walk-1", "nubby-walk-2", "nubby-walk-3"],
                fallback: [
                    "nubby-nubby_plus-idle-0",
                    "nubby-nubby_plus-idle-1",
                    "nubby-nubby_plus-idle-2",
                    "nubby-nubby_plus-idle-3"
                ]
            )
        case .nubby:
            return ["nubby-walk-0", "nubby-walk-1", "nubby-walk-2", "nubby-walk-3"]
        }
    }

    private static func firstExisting(_ names: [String], fallback: [String]) -> [String] {
        if names.contains(where: assetExists) { return names }
        return fallback
    }

    private static func assetExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }
}
