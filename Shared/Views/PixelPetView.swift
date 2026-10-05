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
