import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Dynamic Island / Lock Screen walking pet.
/// Side-view walk sheets, facing swapped at each edge (sheets are already flipped).
/// Frame loop driven by `TimelineView` so we never
/// spam `Activity.update` for sprite animation.
/// Care oneshots (eat / play / sleep) still come from ContentState via `update(pet:)`.
/// Hungry / low mood bands hold the hungry / sad sheet instead of the stroll.
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
    /// Roam clock origin from ContentState. Nil falls back to wall clock (legacy Activities).
    public var walkEpoch: Double?

    /// ~8 fps pixel feel (6-frame side-view walk).
    private static let frameInterval: TimeInterval = 0.125
    /// One edge-to-edge walk (~1.0s, same speed as the old 2.0s ping-pong).
    private static let walkLeg: TimeInterval = 1.0
    /// Occasional hop only — App Lead bounce: constant hop rejected vs clip. 4 frames at 8 fps.
    private static let hopFrames: Int = 4
    /// The hop starts this far into a walk leg, so its 0.5 s lands well before the edge park.
    private static let hopStart: Double = 0.3

    public init(
        mood: PetMood,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        speciesId: String = "nubby",
        growthStage: GrowthStage = .nubby,
        scale: CGFloat = 0.5,
        forceWalkWhenIdle: Bool = true,
        travelAmplitude: CGFloat = 11,
        slotHeight: CGFloat = 36,
        walkEpoch: Double? = nil
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
        self.walkEpoch = walkEpoch
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
                careBody(Self.careAnim(for: display))
            } else if let moodAnim = Self.moodAnim(for: mood) {
                // Hungry / low pets stop strolling — same sheets as the room and home widget.
                careBody(moodAnim)
            } else {
                walkBody
            }
        }
        .frame(height: slotHeight)
    }

    /// Care pose → room clip. Sleep keeps the sleeping alias (no invented sleepStart sheet).
    static func careAnim(for pose: PetPose) -> PetAnim {
        switch pose {
        case .sleep: return .sleeping
        case .eat: return .eating
        case .play: return .playing
        case .clean: return .bathing
        case .idle, .walk: return .idle
        }
    }

    /// Awake mood that should read on the Island instead of the stroll. Nil = keep walking.
    static func moodAnim(for mood: PetMood) -> PetAnim? {
        guard mood.holdsIslandStroll else { return nil }
        return mood == .hungry ? .hungry : .sad
    }

    /// Eat, play, bath, sleep, hungry, and sad use the same side-view sheets as the room.
    /// Kit / plus scale lives in ClipPetView (stage sheets are drawn at stage size) — do not
    /// scale again here. Compact / Lock Screen slots crop to the walk window so hungry/sad
    /// (full 64-px canvas) fill the pill like the stroll and keep feet on the floor.
    private func careBody(_ anim: PetAnim) -> some View {
        let height = slotHeight
        let petWidth = height * 1.35
        let crop = Self.walkCrop(speciesId: speciesId, facingRight: true)
        let unit = min(petWidth / crop.w, height / crop.h)
        let sheetSide = 64 * unit
        let cropX = (petWidth - crop.w * unit) / 2
        let cropY = (height - crop.h * unit) / 2
        return TimelineView(.animation(minimumInterval: 1.0 / 6.0, paused: false)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate * 6)
            ClipPetView(
                speciesId: speciesId,
                anim: anim,
                frame: tick,
                facingLeft: false,
                displaySize: sheetSide,
                growthStage: growthStage
            )
            .frame(width: sheetSide, height: sheetSide, alignment: .topLeading)
            .offset(x: cropX - crop.x * unit, y: cropY - crop.y * unit)
            .frame(width: petWidth, height: height, alignment: .topLeading)
            .clipped()
        }
        .frame(height: height)
        .clipped()
        .accessibilityLabel("\(speciesId) on Island, \(mood.label)")
    }

    private var walkBody: some View {
        let height = slotHeight
        // Side-view sheets are wider than tall. A wider frame lets height fill the pill.
        let petWidth = height * 1.35
        let amp = travelAmplitude
        let pause = Self.edgePause(for: mood)
        // Several statements: a getter (not a ViewBuilder) needs an explicit return.
        return TimelineView(.animation(minimumInterval: Self.frameInterval, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            // Care sheets sit at x=0; stroll from walkEpoch so Feed/Pet handback does not teleport.
            let roamT = walkEpoch.map { t - $0 } ?? t
            let frameTick = Int(t / Self.frameInterval)

            // Walk an edge, park and idle a beat, turn, walk back — a pet roaming, not a slider.
            let (xNorm, facingRight, parked, legProgress) = Self.roam(at: roamT, walk: Self.walkLeg, pause: pause)

            let frames = Self.walkFrames(speciesId: speciesId, growthStage: growthStage, facingRight: facingRight)
            let name = frames[frameTick % max(frames.count, 1)]
            let idleName = Self.idleFrameName(speciesId: speciesId, growthStage: growthStage, frame: Int(t * 6) % 6)

            // Hops belong to the stroll, mid-leg on legs the mood allows; a parked pet just
            // breathes and blinks, and a hop is never cut short by the park.
            let (squashX, squashY, hopY) = (parked || !Self.hopsOnLeg(facingRight: facingRight, mood: mood))
                ? (CGFloat(1), CGFloat(1), CGFloat(0))
                : Self.hopTransform(legProgress: legProgress, side: height)

            // Stage walk/idle sheets are drawn at kit/plus size — no bodyScale. Adult fallbacks still scale.
            let stageArt = Self.usesStageWalkArt(speciesId: speciesId, growthStage: growthStage)
            let stageScale: CGFloat = stageArt ? 1 : CGFloat(growthStage.bodyScaleMultiplier)
            Group {
                if parked, Self.assetExists(idleName) {
                    parkedIdle(idleName, facingRight: facingRight, petWidth: petWidth, height: height)
                } else if Self.assetExists(name) {
                    if stageArt {
                        // Full 64-px stage walks — same walk-window crop as care / parked idle.
                        stageWalkFrame(name, facingRight: facingRight, petWidth: petWidth, height: height)
                    } else {
                        // Widget catalog adult walks are already tight crops.
                        Image(name)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: petWidth, height: height)
                    }
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
            // Feet stay on the pill floor: kit shrinks (and hops squash) toward the ground, same as
            // the care sheets, instead of floating mid-slot.
            .scaleEffect(x: squashX * stageScale, y: squashY * stageScale, anchor: .bottom)
            .offset(x: CGFloat(xNorm) * amp, y: hopY)
            .frame(width: petWidth + amp * 2, height: height)
            .clipped()
            .accessibilityLabel("\(speciesId) \(parked ? "resting" : "walking") on Island, \(mood.label)")
        }
    }

    /// Walk L→R, park at the right edge, walk R→L, park at the left edge. xNorm is -1…1;
    /// the pet keeps facing the way it walked while parked and turns when it sets off.
    /// `legProgress` is 0…1 through the current walk leg (1 while parked).
    static func roam(at t: TimeInterval, walk: TimeInterval, pause: TimeInterval) -> (xNorm: Double, facingRight: Bool, parked: Bool, legProgress: Double) {
        let cycle = 2 * (walk + pause)
        let phase = t.truncatingRemainder(dividingBy: cycle)
        if phase < walk {
            return (-1.0 + 2.0 * phase / walk, true, false, phase / walk)
        }
        if phase < walk + pause {
            return (1.0, true, true, 1)
        }
        let back = phase - walk - pause
        if back < walk {
            return (1.0 - 2.0 * back / walk, false, false, back / walk)
        }
        return (-1.0, false, true, 1)
    }

    /// One hop on the outbound leg (sleepy pets never hop) — about the old density, but locked
    /// mid-walk instead of drifting across the park. Playful reads livelier through its shorter
    /// edge park, not more hops (App Lead rejected constant hopping).
    static func hopsOnLeg(facingRight: Bool, mood: PetMood) -> Bool {
        switch mood {
        case .sleepy, .hungry, .low: return false
        default: return facingRight
        }
    }

    /// Edge park length by mood: playful pets barely stop, sleepy ones linger (Shimeji density).
    static func edgePause(for mood: PetMood) -> TimeInterval {
        switch mood {
        case .playful: return 0.45
        case .sleepy: return 1.4
        default: return 0.9
        }
    }

    /// Widget walk sheets are tight crops of the 64-px room sheets; the idle sheet is not.
    /// Crop origin + size per species and facing, so the parked idle lines up with the walk.
    private static func walkCrop(speciesId: String, facingRight: Bool) -> (x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        if speciesId == "pip" {
            return (facingRight ? 16 : 4, 20, 44, 36)
        }
        return (facingRight ? 8 : 2, 14, 54, 42)
    }

    /// Room idle sheet (6 frames, blink on 3–4) placed so its pixels sit exactly where the walk
    /// crop would draw — same size, same feet. Mirrored when parked at the left edge.
    private func parkedIdle(_ name: String, facingRight: Bool, petWidth: CGFloat, height: CGFloat) -> some View {
        let crop = Self.walkCrop(speciesId: speciesId, facingRight: facingRight)
        let unit = min(petWidth / crop.w, height / crop.h)
        let side = 64 * unit
        let cropX = (petWidth - crop.w * unit) / 2
        let cropY = (height - crop.h * unit) / 2
        return Image(name)
            .interpolation(.none)
            .resizable()
            .frame(width: side, height: side)
            .scaleEffect(x: facingRight ? 1 : -1, y: 1)
            .offset(x: cropX - crop.x * unit, y: cropY - crop.y * unit)
            .frame(width: petWidth, height: height, alignment: .topLeading)
    }

    /// Kit / plus walk sheets are full 64-px (left already drawn). Crop into the pill; no mirror.
    private func stageWalkFrame(_ name: String, facingRight: Bool, petWidth: CGFloat, height: CGFloat) -> some View {
        let crop = Self.walkCrop(speciesId: speciesId, facingRight: facingRight)
        let unit = min(petWidth / crop.w, height / crop.h)
        let side = 64 * unit
        let cropX = (petWidth - crop.w * unit) / 2
        let cropY = (height - crop.h * unit) / 2
        return Image(name)
            .interpolation(.none)
            .resizable()
            .frame(width: side, height: side)
            .offset(x: cropX - crop.x * unit, y: cropY - crop.y * unit)
            .frame(width: petWidth, height: height, alignment: .topLeading)
    }

    /// Squash→stretch→land squash in a 4-frame window starting `hopStart` into the leg.
    /// Flat walk (identity) the rest of the time — matches clip occasional idle hop.
    private static func hopTransform(legProgress: Double, side: CGFloat) -> (sx: CGFloat, sy: CGFloat, y: CGFloat) {
        let into = (legProgress - hopStart) * walkLeg
        guard into >= 0 else { return (1, 1, 0) }
        let phase = Int(into / frameInterval)
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

    /// Same side-view sheets as the room. Left sheets are already flipped — pick walkLeft / walkRight
    /// by name; never mirror again. Kit / plus use their own walks when App Lead flag is on.
    private static func walkFrames(speciesId: String, growthStage: GrowthStage, facingRight: Bool) -> [String] {
        let dir = facingRight ? "walkRight" : "walkLeft"
        if usesStageWalkArt(speciesId: speciesId, growthStage: growthStage) {
            let prefix = growthStage == .kit ? "nubby-kit" : "nubby-nubby_plus"
            return (0..<6).map { "\(prefix)-\(dir)-\($0)" }
        }
        let species = speciesId == "pip" ? "pip" : "nubby"
        return (0..<6).map { "\(species)-\(dir)-\($0)" }
    }

    private static func idleFrameName(speciesId: String, growthStage: GrowthStage, frame: Int) -> String {
        let i = ((frame % 6) + 6) % 6
        if usesStageWalkArt(speciesId: speciesId, growthStage: growthStage) {
            let prefix = growthStage == .kit ? "nubby-kit" : "nubby-nubby_plus"
            return "\(prefix)-idle-\(i)"
        }
        let species = speciesId == "pip" ? "pip" : "nubby"
        return "\(species)-idle-\(i)"
    }

    private static func usesStageWalkArt(speciesId: String, growthStage: GrowthStage) -> Bool {
        guard ClipPetView.stageSheetsMatchSideView, speciesId != "pip" else { return false }
        return growthStage == .kit || growthStage == .nubbyPlus
    }

    private static func assetExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }
}
