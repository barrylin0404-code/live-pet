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

    public init(
        mood: PetMood,
        scale: CGFloat = 1,
        blinking: Bool = false,
        bobOffset: CGFloat = 0
    ) {
        self.mood = mood
        self.scale = scale
        self.blinking = blinking
        self.bobOffset = bobOffset
    }

    public var body: some View {
        Canvas { context, size in
            let unit = size.width / 16
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * unit, y: (y + bobOffset) * unit, width: w * unit, height: h * unit)
            }
            let bodyColor = Color(red: 0.98, green: 0.52, blue: 0.42)
            let earColor = Color(red: 0.92, green: 0.38, blue: 0.32)
            let belly = Color(red: 1.0, green: 0.82, blue: 0.72)

            context.fill(Path(rect(5, 2, 2.5, 2.8)), with: .color(earColor))
            context.fill(Path(rect(8.5, 2, 2.5, 2.8)), with: .color(earColor))
            context.fill(Path(rect(4, 4.5, 8, 7.5)), with: .color(bodyColor))
            context.fill(Path(rect(5.5, 7.5, 5, 3.5)), with: .color(belly))

            if blinking || mood == .sleepy {
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 6.2 * unit, y: (7 + bobOffset) * unit))
                        p.addLine(to: CGPoint(x: 7.4 * unit, y: (7 + bobOffset) * unit))
                        p.move(to: CGPoint(x: 8.6 * unit, y: (7 + bobOffset) * unit))
                        p.addLine(to: CGPoint(x: 9.8 * unit, y: (7 + bobOffset) * unit))
                    },
                    with: .color(.black.opacity(0.75)),
                    lineWidth: max(1, unit * 0.35)
                )
            } else {
                context.fill(Path(ellipseIn: rect(6.2, 6.5, 1.2, 1.4)), with: .color(.black.opacity(0.85)))
                context.fill(Path(ellipseIn: rect(8.6, 6.5, 1.2, 1.4)), with: .color(.black.opacity(0.85)))
            }

            if mood == .happy || mood == .playful {
                context.fill(Path(rect(4.5, 8.5, 1.4, 0.9)), with: .color(.pink.opacity(0.45)))
                context.fill(Path(rect(10.1, 8.5, 1.4, 0.9)), with: .color(.pink.opacity(0.45)))
            }
        }
        .frame(width: 96 * scale, height: 96 * scale)
        .accessibilityLabel("Nubby the pixel pet, \(mood.label)")
    }
}

/// Timeline-driven sprite loops from design-pack Asset Catalog frames.
/// Idle / walk / eat / sleep — never push Activity updates for frame animation.
public struct AnimatedPixelPetView: View {
    public var mood: PetMood
    public var pose: PetPose
    public var isSleeping: Bool
    public var scale: CGFloat
    /// Prefer Island crop asset when compact.
    public var preferIslandCrop: Bool

    public init(
        mood: PetMood,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        scale: CGFloat = 1,
        preferIslandCrop: Bool = false
    ) {
        self.mood = mood
        self.pose = pose
        self.isSleeping = isSleeping
        self.scale = scale
        self.preferIslandCrop = preferIslandCrop
    }

    public var body: some View {
        let effective: PetPose = (isSleeping || pose == .sleep) ? .sleep : pose
        let interval = Self.interval(for: effective)
        TimelineView(.animation(minimumInterval: interval, paused: false)) { context in
            let frames = Self.frameNames(for: effective)
            let tick = Int(context.date.timeIntervalSinceReferenceDate / interval)
            let name: String = {
                if preferIslandCrop, Self.assetExists("island-compact-crop") {
                    return "island-compact-crop"
                }
                return frames[tick % frames.count]
            }()

            ZStack(alignment: .topTrailing) {
                Group {
                    if Self.assetExists(name) {
                        Image(name)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32 * scale * 3, height: 32 * scale * 3)
                    } else {
                        let blink = !isSleeping && effective == .idle && (tick % 8 == 0)
                        let bob: CGFloat = {
                            switch effective {
                            case .walk, .play, .clean: return (tick % 2 == 0) ? -0.35 : 0.15
                            case .eat: return (tick % 2 == 0) ? 0.2 : 0
                            case .sleep: return 0
                            case .idle: return (tick % 10 == 0) ? -0.1 : 0
                            }
                        }()
                        PixelPetView(
                            mood: effective == .sleep ? .sleepy : mood,
                            scale: scale,
                            blinking: blink || effective == .sleep,
                            bobOffset: bob
                        )
                    }
                }
                if effective == .clean {
                    Image(systemName: "bubble.fill")
                        .font(.system(size: 14 * scale))
                        .foregroundStyle(.cyan.opacity(0.85))
                        .offset(x: 4, y: -2)
                }
            }
            .accessibilityLabel("Nubby the pixel pet, \(mood.label)")
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

    private static func frameNames(for pose: PetPose) -> [String] {
        switch pose {
        case .idle:
            return ["nubby-idle-0", "nubby-idle-1", "nubby-idle-2", "nubby-idle-3"]
        case .eat:
            return ["nubby-eat-0", "nubby-eat-1", "nubby-eat-2"]
        case .sleep:
            return ["nubby-sleep-0", "nubby-sleep-1"]
        case .walk, .play:
            return ["nubby-walk-0", "nubby-walk-1", "nubby-walk-2", "nubby-walk-3"]
        case .clean:
            // Placeholder until clean sheets land: idle + walk sparkle feel.
            return ["nubby-idle-0", "nubby-walk-1", "nubby-idle-2"]
        }
    }

    private static func assetExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }
}

#Preview {
    HStack {
        ForEach(PetMood.allCases, id: \.self) { mood in
            AnimatedPixelPetView(mood: mood, scale: 0.7)
        }
    }
    .padding()
}
