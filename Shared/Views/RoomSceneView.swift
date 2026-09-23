import SwiftUI

/// Original room Canvas scenes (not third-party art). Sun Nook (default) | Moon Porch.
public struct RoomSceneView<PetContent: View>: View {
    public var scene: PetRoomScene
    public var mood: PetMood
    @ViewBuilder public var pet: () -> PetContent

    public init(
        scene: PetRoomScene = .sunNook,
        mood: PetMood = .content,
        @ViewBuilder pet: @escaping () -> PetContent
    ) {
        self.scene = scene
        self.mood = mood
        self.pet = pet
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { context, size in
                    switch scene {
                    case .sunNook:
                        drawSunNook(context: context, size: size)
                    case .moonPorch:
                        drawMoonPorch(context: context, size: size)
                    }
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
        .accessibilityLabel("\(scene.displayName) room with Nubby")
    }

    private func drawSunNook(context: GraphicsContext, size: CGSize) {
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

    /// Cool evening pastel — soft indigo sky `#2C3A4A`, warm lamp `#F4D5A0`.
    private func drawMoonPorch(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let indigo = Color(red: 0x2C / 255.0, green: 0x3A / 255.0, blue: 0x4A / 255.0)
        let lamp = Color(red: 0xF4 / 255.0, green: 0xD5 / 255.0, blue: 0xA0 / 255.0)
        let wall = Color(red: 0.22, green: 0.28, blue: 0.36)
        let floor = Color(red: 0.28, green: 0.24, blue: 0.30)

        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(wall))

        let floorY = h * 0.62
        context.fill(
            Path(CGRect(x: 0, y: floorY, width: w, height: h - floorY)),
            with: .color(floor)
        )
        for i in 0..<8 {
            let y = floorY + CGFloat(i) * ((h - floorY) / 8)
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: w, y: y))
            context.stroke(line, with: .color(.white.opacity(0.06)), lineWidth: 1)
        }

        // Night sky window
        let win = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.36, height: h * 0.32)
        context.fill(Path(win.insetBy(dx: -6, dy: -6)), with: .color(Color(red: 0.35, green: 0.32, blue: 0.40)))
        context.fill(
            Path(win),
            with: .linearGradient(
                Gradient(colors: [
                    indigo,
                    Color(red: 0.18, green: 0.22, blue: 0.32)
                ]),
                startPoint: CGPoint(x: win.midX, y: win.minY),
                endPoint: CGPoint(x: win.midX, y: win.maxY)
            )
        )
        // Moon
        context.fill(
            Path(ellipseIn: CGRect(x: win.maxX - win.width * 0.38, y: win.minY + 10, width: 20, height: 20)),
            with: .color(Color(red: 0.92, green: 0.93, blue: 0.88))
        )
        // Soft stars
        context.fill(Path(ellipseIn: CGRect(x: win.minX + 12, y: win.minY + 14, width: 3, height: 3)), with: .color(.white.opacity(0.85)))
        context.fill(Path(ellipseIn: CGRect(x: win.minX + 28, y: win.minY + 28, width: 2, height: 2)), with: .color(.white.opacity(0.7)))
        context.fill(Path(ellipseIn: CGRect(x: win.midX - 10, y: win.minY + 18, width: 2.5, height: 2.5)), with: .color(.white.opacity(0.75)))

        var v = Path()
        v.move(to: CGPoint(x: win.midX, y: win.minY))
        v.addLine(to: CGPoint(x: win.midX, y: win.maxY))
        context.stroke(v, with: .color(Color(red: 0.35, green: 0.32, blue: 0.40)), lineWidth: 4)
        var hz = Path()
        hz.move(to: CGPoint(x: win.minX, y: win.midY))
        hz.addLine(to: CGPoint(x: win.maxX, y: win.midY))
        context.stroke(hz, with: .color(Color(red: 0.35, green: 0.32, blue: 0.40)), lineWidth: 4)

        // Warm porch rug
        let rug = CGRect(x: w * 0.28, y: h * 0.72, width: w * 0.44, height: h * 0.12)
        context.fill(Path(roundedRect: rug, cornerRadius: 8), with: .color(Color(red: 0.40, green: 0.32, blue: 0.48)))
        context.stroke(Path(roundedRect: rug, cornerRadius: 8), with: .color(lamp.opacity(0.35)), lineWidth: 2)

        // Warm lamp on shelf
        let lampX = w * 0.70
        let lampY = h * 0.22
        context.fill(
            Path(CGRect(x: w * 0.58, y: h * 0.28, width: w * 0.28, height: 6)),
            with: .color(Color(red: 0.35, green: 0.32, blue: 0.40))
        )
        // Lamp glow
        context.fill(
            Path(ellipseIn: CGRect(x: lampX - 14, y: lampY - 6, width: 36, height: 28)),
            with: .color(lamp.opacity(0.35))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: lampX - 4, y: lampY, width: 16, height: 14)),
            with: .color(lamp)
        )
        context.fill(
            Path(CGRect(x: lampX + 2, y: lampY + 12, width: 4, height: 10)),
            with: .color(Color(red: 0.45, green: 0.38, blue: 0.30))
        )

        // Porch plant silhouette
        let potX = w * 0.78
        let potY = floorY - 8
        context.fill(
            Path(CGRect(x: potX, y: potY - 28, width: 18, height: 22)),
            with: .color(Color(red: 0.20, green: 0.40, blue: 0.32))
        )
        context.fill(
            Path(CGRect(x: potX + 2, y: potY - 8, width: 14, height: 14)),
            with: .color(Color(red: 0.45, green: 0.35, blue: 0.30))
        )
    }
}

/// Convenience scene host with animated Nubby.
public struct PetRoomSceneView: View {
    public var scene: PetRoomScene
    public var mood: PetMood
    public var pose: PetPose
    public var isSleeping: Bool
    public var petScale: CGFloat

    public init(
        scene: PetRoomScene = .sunNook,
        mood: PetMood = .content,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        petScale: CGFloat = 1.1
    ) {
        self.scene = scene
        self.mood = mood
        self.pose = pose
        self.isSleeping = isSleeping
        self.petScale = petScale
    }

    public var body: some View {
        RoomSceneView(scene: scene, mood: mood) {
            AnimatedPixelPetView(
                mood: mood,
                pose: pose,
                isSleeping: isSleeping,
                scale: petScale
            )
        }
    }
}

/// Back-compat alias for Sun Nook call sites.
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
        PetRoomSceneView(
            scene: .sunNook,
            mood: mood,
            pose: pose,
            isSleeping: isSleeping,
            petScale: petScale
        )
    }
}

#Preview {
    VStack {
        PetRoomSceneView(scene: .sunNook, mood: .happy)
        PetRoomSceneView(scene: .moonPorch, mood: .content)
    }
    .padding()
}
