import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Dynamic Island / Lock Screen walking pet.
/// Frame loop + facing flip are driven by `TimelineView` dates inside the widget
/// extension so we never spam `Activity.update` for sprite animation.
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

    /// Walk frame tick (~6 fps).
    private static let frameInterval: TimeInterval = 0.16
    /// Simulated "edge" turn — flip facing every ~3.2s.
    private static let facingPeriod: TimeInterval = 3.2

    public init(
        mood: PetMood,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        speciesId: String = "nubby",
        growthStage: GrowthStage = .nubby,
        scale: CGFloat = 0.5,
        forceWalkWhenIdle: Bool = true
    ) {
        self.mood = mood
        self.pose = pose
        self.isSleeping = isSleeping
        self.speciesId = speciesId
        self.growthStage = growthStage
        self.scale = scale
        self.forceWalkWhenIdle = forceWalkWhenIdle
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
        // Care oneshots / sleep: reuse shared sprite loops (no Island static crop).
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
        // Base hop larger than in-app sprites so Island slots read big; slight overflow OK.
        let side = 40 * scale * stageScale * 3
        TimelineView(.animation(minimumInterval: Self.frameInterval, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let frameTick = Int(t / Self.frameInterval)
            let facingRight = (Int(t / Self.facingPeriod) % 2) == 0
            let frames = Self.walkFrames(speciesId: speciesId, growthStage: growthStage)
            let name = frames[frameTick % max(frames.count, 1)]
            // Hop scaled to sprite size so motion still reads without eating ears/feet.
            let hopAmp = max(2.5, side * 0.06)
            let hop: CGFloat = (frameTick % 2 == 0) ? -hopAmp : hopAmp * 0.65

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
                        bobOffset: (frameTick % 2 == 0) ? -0.4 : 0.2,
                        speciesId: speciesId
                    )
                }
            }
            .scaleEffect(x: facingRight ? 1 : -1, y: 1)
            .offset(y: hop)
            .accessibilityLabel("\(speciesId) walking on Island, \(mood.label)")
        }
    }

    private static func walkFrames(speciesId: String, growthStage: GrowthStage) -> [String] {
        if speciesId == "pip" {
            // Pip has no dedicated walk sheet yet — denser idle loop beats a static crop.
            return ["pip-idle-0", "pip-idle-1", "pip-idle-2", "pip-idle-3"]
        }
        switch growthStage {
        case .kit:
            // Prefer real walk frames; fall back to kit idle if walk assets missing.
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
