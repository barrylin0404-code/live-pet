import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Plays `PetAnim` frames. Uses catalog PNGs when present, otherwise original drawn frames
/// (different poses, not one sprite slid across the room).
public struct ClipPetView: View {
    public var speciesId: String
    public var anim: PetAnim
    public var frame: Int
    public var facingLeft: Bool
    public var displaySize: CGFloat

    public init(speciesId: String, anim: PetAnim, frame: Int, facingLeft: Bool, displaySize: CGFloat = 168) {
        self.speciesId = speciesId
        self.anim = anim
        self.frame = frame
        self.facingLeft = facingLeft
        self.displaySize = displaySize
    }

    public var body: some View {
        let shown = PetAnimCatalog.playbackAnim(anim, facingLeft: facingLeft)
        let count = max(1, PetAnimCatalog.clip(for: shown).frameCount)
        let index = ((frame % count) + count) % count
        let name = PetAnimCatalog.assetName(speciesId: speciesId, anim: shown, frame: index)
        let idleFallback = PetAnimCatalog.assetName(speciesId: speciesId, anim: .idle, frame: index % 6)
        // walkLeft sheets already face left. Flipping them again turns the cat around.
        let bakedLeft = shown == .walkLeft || shown == .runLeft || shown == .turnLeft
            || shown == .idleLookLeft || shown == .idleLookRight
        Group {
            #if canImport(UIKit)
            if UIImage(named: name) != nil {
                Image(name)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else if UIImage(named: PetAnimCatalog.assetName(speciesId: speciesId, anim: shown, frame: 0)) != nil {
                Image(PetAnimCatalog.assetName(speciesId: speciesId, anim: shown, frame: 0))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else if UIImage(named: idleFallback) != nil {
                Image(idleFallback)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                drawn
            }
            #else
            drawn
            #endif
        }
        .frame(width: displaySize, height: displaySize)
        .scaleEffect(x: (facingLeft && !bakedLeft) ? -1 : 1, y: 1)
        .accessibilityLabel(speciesId == "pip" ? "Pip" : "Nubby")
    }

    private var drawn: some View {
        Canvas { ctx, size in
            let u = size.width / 16
            let f = frame
            let body = speciesId == "pip"
                ? Color(red: 0.49, green: 0.78, blue: 0.64)
                : Color(red: 1.0, green: 0.545, blue: 0.478)
            let belly = speciesId == "pip"
                ? Color(red: 0.69, green: 0.88, blue: 0.76)
                : Color(red: 1.0, green: 0.88, blue: 0.83)
            let ear = Color(red: 0.91, green: 0.42, blue: 0.36)
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * u, y: y * u, width: w * u, height: h * u)
            }
            let bob: CGFloat = {
                switch anim {
                case .walkLeft, .walkRight, .walkSlow, .walkFast, .walkToFood, .sleepyWalk:
                    return f % 2 == 0 ? 0 : -0.6
                case .happy, .playExcited, .veryHappy, .hop, .jump:
                    return -1.4
                case .eating, .eatFinish:
                    return 0.8
                default:
                    return f % 2 == 0 ? 0 : 0.25
                }
            }()
            let yLift = bob
            if speciesId != "pip" {
                ctx.fill(Path(ellipseIn: r(4.4, 1.2 + yLift, 2.6, 3.0)), with: .color(ear))
                ctx.fill(Path(ellipseIn: r(9.0, 1.2 + yLift, 2.6, 3.0)), with: .color(ear))
            }
            ctx.fill(Path(ellipseIn: r(3.2, 3.6 + yLift, 9.6, 8.6)), with: .color(body))
            ctx.fill(Path(ellipseIn: r(5.0, 7.2 + yLift, 6.0, 4.0)), with: .color(belly))
            let blink = anim == .idleBlink || anim == .sleeping || anim == .sleepBreathing || (anim == .idle && f == 3)
            if blink {
                ctx.stroke(Path { p in
                    p.move(to: CGPoint(x: 5.6 * u, y: (6.6 + yLift) * u))
                    p.addLine(to: CGPoint(x: 7.4 * u, y: (6.6 + yLift) * u))
                    p.move(to: CGPoint(x: 8.6 * u, y: (6.6 + yLift) * u))
                    p.addLine(to: CGPoint(x: 10.4 * u, y: (6.6 + yLift) * u))
                }, with: .color(.black.opacity(0.8)), lineWidth: max(1, u * 0.35))
            } else {
                let look: CGFloat = (anim == .idleLookLeft) ? -0.4 : (anim == .idleLookRight ? 0.4 : 0)
                ctx.fill(Path(ellipseIn: r(5.4 + look, 5.8 + yLift, 2.0, 2.2)), with: .color(.black.opacity(0.88)))
                ctx.fill(Path(ellipseIn: r(8.6 + look, 5.8 + yLift, 2.0, 2.2)), with: .color(.black.opacity(0.88)))
            }
            // Legs change with the walk frame so it is a cycle, not a slide.
            let step = (anim == .walkLeft || anim == .walkRight || anim == .walkToFood || anim == .walkSlow)
            let legA: CGFloat = step ? (f % 2 == 0 ? 12.2 : 13.4) : 12.6
            let legB: CGFloat = step ? (f % 2 == 0 ? 13.4 : 12.2) : 12.6
            ctx.fill(Path(roundedRect: r(5.2, legA + yLift * 0.2, 1.6, 2.2), cornerRadius: 1), with: .color(ear))
            ctx.fill(Path(roundedRect: r(9.0, legB + yLift * 0.2, 1.6, 2.2), cornerRadius: 1), with: .color(ear))
            if anim == .eating || anim == .eatStart || anim == .eatFinish {
                ctx.fill(Path(ellipseIn: r(1.2, 10.2, 2.2, 1.6)), with: .color(Color(red: 0.85, green: 0.55, blue: 0.30)))
            }
            if anim == .happy || anim == .petHappy || anim == .veryHappy {
                ctx.fill(Path(ellipseIn: r(11.5, 3.0, 2.2, 2.0)), with: .color(Color(red: 1, green: 0.35, blue: 0.45)))
            }
        }
    }
}
