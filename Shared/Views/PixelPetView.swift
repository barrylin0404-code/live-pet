import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Canvas fallback when Asset Catalog sprites are missing (previews / older builds).
public struct PixelPetView: View {
    public var mood: PetMood
    public var scale: CGFloat
    public var blinking: Bool
    public var bobOffset: CGFloat
    public var speciesId: String

    public init(
        mood: PetMood,
        scale: CGFloat = 1,
        blinking: Bool = false,
        bobOffset: CGFloat = 0,
        speciesId: String = "nubby"
    ) {
        self.mood = mood
        self.scale = scale
        self.blinking = blinking
        self.bobOffset = bobOffset
        self.speciesId = speciesId
    }

    public var body: some View {
        Canvas { context, size in
            let unit = size.width / 16
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * unit, y: (y + bobOffset) * unit, width: w * unit, height: h * unit)
            }
            if speciesId == "pip" {
                // Soft mint bird — round body, big eye, tiny beak (original, not competitor IP).
                let body = Color(red: 0x7E / 255.0, green: 0xC8 / 255.0, blue: 0xA3 / 255.0)
                let belly = Color(red: 0xAF / 255.0, green: 0xE1 / 255.0, blue: 0xC3 / 255.0)
                let beak = Color(red: 1.0, green: 0xC8 / 255.0, blue: 0xAA / 255.0)
                context.fill(Path(ellipseIn: rect(3.8, 4.2, 8.4, 7.6)), with: .color(body))
                context.fill(Path(ellipseIn: rect(5.2, 7.0, 5.2, 3.6)), with: .color(belly))
                context.fill(Path(ellipseIn: rect(2.4, 7.0, 2.0, 1.4)), with: .color(beak))
                if blinking || mood == .sleepy {
                    context.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: 7.0 * unit, y: (6.6 + bobOffset) * unit))
                            p.addLine(to: CGPoint(x: 9.0 * unit, y: (6.6 + bobOffset) * unit))
                        },
                        with: .color(.black.opacity(0.75)),
                        lineWidth: max(1, unit * 0.4)
                    )
                } else {
                    context.fill(Path(ellipseIn: rect(7.0, 5.8, 2.2, 2.4)), with: .color(.black.opacity(0.88)))
                    context.fill(Path(ellipseIn: rect(8.2, 6.2, 0.7, 0.7)), with: .color(.white.opacity(0.9)))
                }
                context.fill(Path(ellipseIn: rect(10.2, 5.2, 2.8, 1.6)), with: .color(body.opacity(0.95)))
            } else {
                // Coral Nubby — rounder face, bigger eyes, soft peach belly (original).
                let bodyColor = Color(red: 1.0, green: 0.545, blue: 0.478) // #FF8B7A
                let earColor = Color(red: 0.91, green: 0.416, blue: 0.361) // #E86A5C
                let belly = Color(red: 1.0, green: 0.878, blue: 0.831) // #FFE0D4
                context.fill(Path(ellipseIn: rect(4.6, 1.6, 2.8, 3.2)), with: .color(earColor))
                context.fill(Path(ellipseIn: rect(8.6, 1.6, 2.8, 3.2)), with: .color(earColor))
                context.fill(Path(ellipseIn: rect(3.2, 4.0, 9.6, 9.0)), with: .color(bodyColor))
                context.fill(Path(ellipseIn: rect(5.0, 7.4, 6.0, 4.2)), with: .color(belly))
                if blinking || mood == .sleepy {
                    context.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: 5.6 * unit, y: (6.8 + bobOffset) * unit))
                            p.addLine(to: CGPoint(x: 7.4 * unit, y: (6.8 + bobOffset) * unit))
                            p.move(to: CGPoint(x: 8.6 * unit, y: (6.8 + bobOffset) * unit))
                            p.addLine(to: CGPoint(x: 10.4 * unit, y: (6.8 + bobOffset) * unit))
                        },
                        with: .color(.black.opacity(0.75)),
                        lineWidth: max(1, unit * 0.4)
                    )
                } else {
                    context.fill(Path(ellipseIn: rect(5.5, 6.0, 2.0, 2.2)), with: .color(.black.opacity(0.88)))
                    context.fill(Path(ellipseIn: rect(8.5, 6.0, 2.0, 2.2)), with: .color(.black.opacity(0.88)))
                    context.fill(Path(ellipseIn: rect(6.4, 6.4, 0.7, 0.7)), with: .color(.white.opacity(0.9)))
                    context.fill(Path(ellipseIn: rect(9.4, 6.4, 0.7, 0.7)), with: .color(.white.opacity(0.9)))
                }
                if mood == .happy || mood == .playful {
                    context.fill(Path(ellipseIn: rect(3.8, 8.4, 1.8, 1.2)), with: .color(.pink.opacity(0.5)))
                    context.fill(Path(ellipseIn: rect(10.4, 8.4, 1.8, 1.2)), with: .color(.pink.opacity(0.5)))
                }
            }
        }
        .frame(width: 96 * scale, height: 96 * scale)
        .accessibilityLabel("\(speciesId) the pixel pet, \(mood.label)")
    }
}

/// Timeline-driven sprite loops from design-pack Asset Catalog frames.
/// Idle / walk / eat / sleep — never push Activity updates for frame animation.
public struct AnimatedPixelPetView: View {
    public var mood: PetMood
    public var pose: PetPose
    public var isSleeping: Bool
    public var scale: CGFloat
    public var preferIslandCrop: Bool
    public var speciesId: String
    public var growthStage: GrowthStage

    public init(
        mood: PetMood,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        scale: CGFloat = 1,
        preferIslandCrop: Bool = false,
        speciesId: String = "nubby",
        growthStage: GrowthStage = .nubby
    ) {
        self.mood = mood
        self.pose = pose
        self.isSleeping = isSleeping
        self.scale = scale
        self.preferIslandCrop = preferIslandCrop
        self.speciesId = speciesId
        self.growthStage = growthStage
    }

    public var body: some View {
        let effective: PetPose = (isSleeping || pose == .sleep) ? .sleep : pose
        let interval = Self.interval(for: effective)
        let stageScale = CGFloat(growthStage.bodyScaleMultiplier)
        TimelineView(.animation(minimumInterval: interval, paused: false)) { context in
            let frames = Self.frameNames(speciesId: speciesId, growthStage: growthStage, pose: effective)
            let tick = Int(context.date.timeIntervalSinceReferenceDate / interval)
            let name: String = {
                if preferIslandCrop {
                    let island = Self.islandCropName(speciesId: speciesId, growthStage: growthStage)
                    if Self.assetExists(island) { return island }
                    if Self.assetExists("island-compact-crop") { return "island-compact-crop" }
                }
                return frames[tick % max(frames.count, 1)]
            }()

            let baseSide = 32 * scale * stageScale * 3
            // Home hero (scale ≥1.9) targets ~200–240pt; widgets/avatars stay on baseSide.
            let displaySide = scale >= 1.9 ? max(baseSide, 220) : (scale >= 1.45 ? max(baseSide, 140) : baseSide)
            // Visible idle bob ≥2pt logical (Canvas unit + whole-view offset).
            let bobY: CGFloat = {
                switch effective {
                case .walk, .play, .clean:
                    return (tick % 2 == 0) ? -6 : 3
                case .eat:
                    return (tick % 2 == 0) ? 2 : 0
                case .sleep:
                    return 0
                case .idle:
                    // Dense bob — never frozen (15-video-density)
                    let phase = tick % 4
                    if phase == 0 { return -4 }
                    if phase == 1 { return 0 }
                    if phase == 2 { return 3 }
                    return -1
                }
            }()
            let blink = !isSleeping && effective == .idle && (tick % 4 == 2)
            ZStack(alignment: .topTrailing) {
                Group {
                    if Self.assetExists(name) {
                        Image(name)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: displaySide, height: displaySide)
                    } else {
                        // bobOffset is in 16ths of canvas — ~0.35 units ≈ 2pt+ at home scale
                        let unitBob: CGFloat = {
                            switch effective {
                            case .walk, .play, .clean: return (tick % 2 == 0) ? -0.55 : 0.25
                            case .eat: return (tick % 2 == 0) ? 0.35 : 0
                            case .sleep: return 0
                            case .idle:
                                let phase = tick % 4
                                if phase == 1 { return -0.45 }
                                if phase == 3 { return 0.30 }
                                return 0
                            }
                        }()
                        PixelPetView(
                            mood: effective == .sleep ? .sleepy : mood,
                            scale: scale >= 1.9 ? max(scale * stageScale, 2.1) : (scale >= 1.45 ? max(scale * stageScale, 1.45) : scale * stageScale),
                            blinking: blink || effective == .sleep,
                            bobOffset: unitBob,
                            speciesId: speciesId
                        )
                    }
                }
                .offset(y: bobY)
                if effective == .clean {
                    Image(systemName: "bubble.fill")
                        .font(.system(size: 14 * scale))
                        .foregroundStyle(.cyan.opacity(0.85))
                        .offset(x: 4, y: -2)
                }
            }
            .accessibilityLabel("\(speciesId) the pixel pet, \(mood.label)")
        }
    }

    private static func interval(for pose: PetPose) -> TimeInterval {
        switch pose {
        case .idle: return 0.33
        case .eat: return 0.30
        case .sleep: return 0.60
        case .walk, .play: return 0.18
        case .clean: return 0.28
        }
    }

    private static func islandCropName(speciesId: String, growthStage: GrowthStage) -> String {
        if speciesId == "pip" { return "island-pip-compact" }
        if growthStage == .nubbyPlus { return "island-nubby-plus-compact" }
        return "island-compact-crop"
    }

    private static func frameNames(speciesId: String, growthStage: GrowthStage, pose: PetPose) -> [String] {
        if speciesId == "pip" {
            switch pose {
            case .sleep:
                return firstExisting(["pip-sleep-0", "pip-sleep-1"], fallback: ["pip-idle-0", "pip-idle-1"])
            case .eat, .walk, .play, .clean, .idle:
                return ["pip-idle-0", "pip-idle-1", "pip-idle-2", "pip-idle-3"]
            }
        }
        switch growthStage {
        case .kit:
            switch pose {
            case .sleep:
                return firstExisting(["nubby-sleep-0", "nubby-sleep-1"], fallback: ["nubby-kit-idle-0", "nubby-kit-idle-1"])
            default:
                return firstExisting(
                    ["nubby-kit-idle-0", "nubby-kit-idle-1", "nubby-kit-idle-2", "nubby-kit-idle-3"],
                    fallback: ["nubby-idle-0", "nubby-idle-1", "nubby-idle-2", "nubby-idle-3"]
                )
            }
        case .nubbyPlus:
            switch pose {
            case .sleep:
                return firstExisting(
                    ["nubby-nubby_plus-sleep-0", "nubby-nubby_plus-sleep-1"],
                    fallback: ["nubby-sleep-0", "nubby-sleep-1"]
                )
            case .eat:
                return firstExisting(
                    ["nubby-eat-0", "nubby-eat-1", "nubby-eat-2"],
                    fallback: ["nubby-nubby_plus-idle-0", "nubby-nubby_plus-idle-1", "nubby-nubby_plus-idle-2"]
                )
            case .walk, .play:
                return firstExisting(
                    ["nubby-walk-0", "nubby-walk-1", "nubby-walk-2", "nubby-walk-3"],
                    fallback: ["nubby-nubby_plus-idle-0", "nubby-nubby_plus-idle-1", "nubby-nubby_plus-idle-2", "nubby-nubby_plus-idle-3"]
                )
            case .clean:
                return firstExisting(
                    ["nubby-nubby_plus-idle-0", "nubby-walk-1", "nubby-nubby_plus-idle-2"],
                    fallback: ["nubby-idle-0", "nubby-walk-1", "nubby-idle-2"]
                )
            case .idle:
                return firstExisting(
                    ["nubby-nubby_plus-idle-0", "nubby-nubby_plus-idle-1", "nubby-nubby_plus-idle-2", "nubby-nubby_plus-idle-3"],
                    fallback: ["nubby-idle-0", "nubby-idle-1", "nubby-idle-2", "nubby-idle-3"]
                )
            }
        case .nubby:
            switch pose {
            case .idle: return ["nubby-idle-0", "nubby-idle-1", "nubby-idle-2", "nubby-idle-3"]
            case .eat: return ["nubby-eat-0", "nubby-eat-1", "nubby-eat-2"]
            case .sleep: return ["nubby-sleep-0", "nubby-sleep-1"]
            case .walk, .play: return ["nubby-walk-0", "nubby-walk-1", "nubby-walk-2", "nubby-walk-3"]
            case .clean: return ["nubby-idle-0", "nubby-walk-1", "nubby-idle-2"]
            }
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
