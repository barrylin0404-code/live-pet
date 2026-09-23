import SwiftUI

/// Original "Sun Nook" room — geometric Canvas scene (not third-party art).
public struct RoomSceneView<PetContent: View>: View {
    public var mood: PetMood
    @ViewBuilder public var pet: () -> PetContent

    public init(mood: PetMood = .content, @ViewBuilder pet: @escaping () -> PetContent) {
        self.mood = mood
        self.pet = pet
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { context, size in
                    drawRoom(context: context, size: size)
                }
                pet()
                    .position(x: geo.size.width * 0.52, y: geo.size.height * 0.62)
            }
        }
        .aspectRatio(1.35, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        )
        .accessibilityLabel("Sun Nook room with Nubby")
    }

    private func drawRoom(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height

        // Back wall
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(Color(red: 0.93, green: 0.90, blue: 0.84))
        )

        // Floor
        let floorY = h * 0.62
        context.fill(
            Path(CGRect(x: 0, y: floorY, width: w, height: h - floorY)),
            with: .color(Color(red: 0.72, green: 0.55, blue: 0.38))
        )
        // Floorboards
        for i in 0..<8 {
            let y = floorY + CGFloat(i) * ((h - floorY) / 8)
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: w, y: y))
            context.stroke(line, with: .color(.black.opacity(0.08)), lineWidth: 1)
        }

        // Window frame
        let win = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.36, height: h * 0.32)
        context.fill(Path(win.insetBy(dx: -6, dy: -6)), with: .color(Color(red: 0.55, green: 0.40, blue: 0.28)))
        // Sky
        context.fill(
            Path(win),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.55, green: 0.75, blue: 0.95),
                    Color(red: 0.85, green: 0.92, blue: 1.0)
                ]),
                startPoint: CGPoint(x: win.midX, y: win.minY),
                endPoint: CGPoint(x: win.midX, y: win.maxY)
            )
        )
        // Sun
        context.fill(
            Path(ellipseIn: CGRect(x: win.maxX - win.width * 0.35, y: win.minY + 8, width: 22, height: 22)),
            with: .color(Color(red: 1.0, green: 0.85, blue: 0.35))
        )
        // Window mullion
        var v = Path()
        v.move(to: CGPoint(x: win.midX, y: win.minY))
        v.addLine(to: CGPoint(x: win.midX, y: win.maxY))
        context.stroke(v, with: .color(Color(red: 0.55, green: 0.40, blue: 0.28)), lineWidth: 4)
        var hz = Path()
        hz.move(to: CGPoint(x: win.minX, y: win.midY))
        hz.addLine(to: CGPoint(x: win.maxX, y: win.midY))
        context.stroke(hz, with: .color(Color(red: 0.55, green: 0.40, blue: 0.28)), lineWidth: 4)

        // Rug
        let rug = CGRect(x: w * 0.28, y: h * 0.72, width: w * 0.44, height: h * 0.12)
        context.fill(Path(roundedRect: rug, cornerRadius: 8), with: .color(Color(red: 0.35, green: 0.55, blue: 0.48)))
        context.stroke(Path(roundedRect: rug, cornerRadius: 8), with: .color(.white.opacity(0.25)), lineWidth: 2)

        // Plant pot
        let potX = w * 0.78
        let potY = floorY - 8
        context.fill(
            Path(CGRect(x: potX, y: potY - 28, width: 18, height: 22)),
            with: .color(Color(red: 0.25, green: 0.55, blue: 0.35))
        )
        context.fill(
            Path(CGRect(x: potX + 2, y: potY - 8, width: 14, height: 14)),
            with: .color(Color(red: 0.70, green: 0.42, blue: 0.32))
        )

        // Shelf
        context.fill(
            Path(CGRect(x: w * 0.58, y: h * 0.28, width: w * 0.28, height: 6)),
            with: .color(Color(red: 0.55, green: 0.40, blue: 0.28))
        )
        // Tiny blocks on shelf (decor)
        context.fill(Path(CGRect(x: w * 0.62, y: h * 0.22, width: 12, height: 12)), with: .color(Color(red: 0.95, green: 0.55, blue: 0.35)))
        context.fill(Path(CGRect(x: w * 0.72, y: h * 0.20, width: 10, height: 14)), with: .color(Color(red: 0.45, green: 0.60, blue: 0.90)))
    }
}

/// Convenience when you only need the default Nubby pet.
public struct SunNookScene: View {
    public var mood: PetMood
    public var pose: PetPose
    public var isSleeping: Bool
    public var petScale: CGFloat

    public init(
        mood: PetMood = .content,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        petScale: CGFloat = 1.1
    ) {
        self.mood = mood
        self.pose = pose
        self.isSleeping = isSleeping
        self.petScale = petScale
    }

    public var body: some View {
        RoomSceneView(mood: mood) {
            AnimatedPixelPetView(
                mood: mood,
                pose: pose,
                isSleeping: isSleeping,
                scale: petScale
            )
        }
    }
}

#Preview {
    SunNookScene(mood: .happy)
        .padding()
}
