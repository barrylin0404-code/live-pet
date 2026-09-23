import SwiftUI

/// Original geometric pixel pet "Nubby" — drawn with Canvas rectangles (no third-party art).
public struct PixelPetView: View {
    public var mood: PetMood
    public var scale: CGFloat
    public var blinking: Bool

    public init(mood: PetMood = .content, scale: CGFloat = 1, blinking: Bool = false) {
        self.mood = mood
        self.scale = scale
        self.blinking = blinking
    }

    public var body: some View {
        Canvas { context, size in
            let unit = min(size.width, size.height) / 16
            let origin = CGPoint(
                x: (size.width - unit * 16) / 2,
                y: (size.height - unit * 16) / 2
            )

            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(
                    x: origin.x + x * unit,
                    y: origin.y + y * unit,
                    width: w * unit,
                    height: h * unit
                )
            }

            // Shadow
            context.fill(Path(rect(4, 14, 8, 1.2)), with: .color(.black.opacity(0.18)))

            // Body — soft coral square with darker outline pixels
            let body = Color(red: 0.98, green: 0.52, blue: 0.42)
            let outline = Color(red: 0.72, green: 0.28, blue: 0.22)
            let belly = Color(red: 1.0, green: 0.78, blue: 0.62)

            context.fill(Path(rect(3, 4, 10, 9)), with: .color(outline))
            context.fill(Path(rect(4, 5, 8, 7)), with: .color(body))
            context.fill(Path(rect(5, 8, 6, 3)), with: .color(belly))

            // Ears / nubs
            context.fill(Path(rect(4, 3, 2, 2)), with: .color(body))
            context.fill(Path(rect(10, 3, 2, 2)), with: .color(body))
            context.fill(Path(rect(4.3, 3.3, 1.4, 1.4)), with: .color(outline.opacity(0.35)))
            context.fill(Path(rect(10.3, 3.3, 1.4, 1.4)), with: .color(outline.opacity(0.35)))

            // Feet
            context.fill(Path(rect(5, 12, 2, 2)), with: .color(outline))
            context.fill(Path(rect(9, 12, 2, 2)), with: .color(outline))

            // Eyes / expression by mood
            let eyeY: CGFloat = mood == .sleepy ? 7.2 : 6.5
            if blinking || mood == .sleepy {
                context.fill(Path(rect(5.5, eyeY + 0.4, 2, 0.6)), with: .color(.black.opacity(0.85)))
                context.fill(Path(rect(8.5, eyeY + 0.4, 2, 0.6)), with: .color(.black.opacity(0.85)))
            } else {
                context.fill(Path(rect(5.5, eyeY, 2, 2)), with: .color(.white))
                context.fill(Path(rect(8.5, eyeY, 2, 2)), with: .color(.white))
                let pupilOffset: CGFloat = mood == .playful ? 0.4 : 0.2
                context.fill(Path(rect(6 + pupilOffset, eyeY + 0.5, 1, 1.2)), with: .color(.black))
                context.fill(Path(rect(9 + pupilOffset, eyeY + 0.5, 1, 1.2)), with: .color(.black))
            }

            // Mouth
            switch mood {
            case .happy, .playful:
                context.fill(Path(rect(7, 10, 2, 0.7)), with: .color(outline))
                context.fill(Path(rect(6.5, 9.6, 0.7, 0.7)), with: .color(outline))
                context.fill(Path(rect(8.8, 9.6, 0.7, 0.7)), with: .color(outline))
            case .hungry, .low:
                context.fill(Path(rect(7, 9.5, 2, 1.2)), with: .color(outline.opacity(0.7)))
            case .sleepy:
                context.fill(Path(rect(7.2, 10, 1.6, 0.5)), with: .color(outline.opacity(0.5)))
            case .content:
                context.fill(Path(rect(7, 10, 2, 0.5)), with: .color(outline))
            }

            // Cheek blush when happy / playful
            if mood == .happy || mood == .playful {
                context.fill(Path(rect(4.5, 8.5, 1.4, 0.9)), with: .color(.pink.opacity(0.45)))
                context.fill(Path(rect(10.1, 8.5, 1.4, 0.9)), with: .color(.pink.opacity(0.45)))
            }
        }
        .frame(width: 96 * scale, height: 96 * scale)
        .accessibilityLabel("Nubby the pixel pet, \(mood.label)")
    }
}

#Preview {
    HStack {
        ForEach(PetMood.allCases, id: \.self) { mood in
            PixelPetView(mood: mood, scale: 0.7)
        }
    }
    .padding()
}
