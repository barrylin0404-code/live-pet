import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Original room Canvas scenes (not third-party art). Indoor quartet + Meadow Walk (pass 18).
public struct RoomSceneView<PetContent: View>: View {
    public var scene: PetRoomScene
    public var mood: PetMood
    public var firefliesUnlocked: Int
    public var showFireflies: Bool
    /// 0...1 horizontal pet placement (0.5 = center). Continuous walk drives this.
    public var petXFraction: CGFloat
    public var facingLeft: Bool
    public var droppedSymbol: String?
    public var droppedXFraction: CGFloat
    public var ballVisible: Bool
    public var ballXFraction: CGFloat
    public var ballYFraction: CGFloat
    public var onBallTap: (() -> Void)?
    public var wandVisible: Bool
    public var wandXFraction: CGFloat
    public var wandYFraction: CGFloat
    public var onRoomDrag: ((CGFloat, CGFloat) -> Void)?
    public var onPetDrag: (() -> Void)?
    @ViewBuilder public var pet: () -> PetContent

    public init(
        scene: PetRoomScene = .sunNook,
        mood: PetMood = .content,
        firefliesUnlocked: Int = 0,
        showFireflies: Bool = true,
        petXFraction: CGFloat = 0.52,
        facingLeft: Bool = false,
        droppedSymbol: String? = nil,
        droppedXFraction: CGFloat = 0.7,
        ballVisible: Bool = false,
        ballXFraction: CGFloat = 0.72,
        ballYFraction: CGFloat = 0.70,
        onBallTap: (() -> Void)? = nil,
        wandVisible: Bool = false,
        wandXFraction: CGFloat = 0.5,
        wandYFraction: CGFloat = 0.4,
        onRoomDrag: ((CGFloat, CGFloat) -> Void)? = nil,
        onPetDrag: (() -> Void)? = nil,
        @ViewBuilder pet: @escaping () -> PetContent
    ) {
        self.scene = scene
        self.mood = mood
        self.firefliesUnlocked = firefliesUnlocked
        self.showFireflies = showFireflies
        self.petXFraction = petXFraction
        self.facingLeft = facingLeft
        self.droppedSymbol = droppedSymbol
        self.droppedXFraction = droppedXFraction
        self.ballVisible = ballVisible
        self.ballXFraction = ballXFraction
        self.ballYFraction = ballYFraction
        self.onBallTap = onBallTap
        self.wandVisible = wandVisible
        self.wandXFraction = wandXFraction
        self.wandYFraction = wandYFraction
        self.onRoomDrag = onRoomDrag
        self.onPetDrag = onPetDrag
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
                    case .tideGlass:
                        drawTideGlass(context: context, size: size)
                    case .skylineDusk:
                        drawSkylineDusk(context: context, size: size)
                    case .meadowWalk:
                        drawMeadowWalk(context: context, size: size)
                    case .snowPorch, .coralShelf:
                        // Stubs: not selectable; fall back to Sun Nook art if decoded.
                        drawSunNook(context: context, size: size)
                    }
                }
                let feetY = CGFloat(scene.petFeetYFraction)
                if let symbol = droppedSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.orange)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .position(x: geo.size.width * droppedXFraction, y: geo.size.height * (feetY + 0.10))
                        .transition(.scale.combined(with: .opacity))
                }
                if ballVisible {
                    Image(systemName: "tennisball.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color(red: 0.85, green: 0.92, blue: 0.35))
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        .position(x: geo.size.width * ballXFraction, y: geo.size.height * ballYFraction)
                        .onTapGesture { onBallTap?() }
                }
                if wandVisible {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color(red: 0.75, green: 0.45, blue: 0.95))
                        .shadow(color: Color(red: 0.75, green: 0.45, blue: 0.95).opacity(0.45), radius: 6, y: 1)
                        .position(x: geo.size.width * wandXFraction, y: geo.size.height * wandYFraction)
                        .transition(.scale.combined(with: .opacity))
                }
                pet()
                    .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
                    .position(x: geo.size.width * petXFraction, y: geo.size.height * feetY)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard wandVisible || onRoomDrag != nil else { return }
                                let fx = min(0.92, max(0.08, value.location.x / max(geo.size.width, 1)))
                                let fy = min(0.85, max(0.18, value.location.y / max(geo.size.height, 1)))
                                onRoomDrag?(fx, fy)
                            }
                    )
                    .allowsHitTesting(wandVisible && onRoomDrag != nil)
                if showFireflies && firefliesUnlocked > 0 {
                    FirefliesOverlay(count: firefliesUnlocked)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Layout 21: flush into console seam — not a floating card
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .accessibilityLabel("\(scene.displayName) room with Nubby")
    }


    /// Layout 21 R6 — sofa / curtains / TV / plant / wall art on margins only (mid-band 0.22–0.78 clear).
    private func drawIndoorFurnitureDensity(context: GraphicsContext, size: CGSize, floorY: CGFloat, win: CGRect, night: Bool) {
        let w = size.width
        let h = size.height
        let wood = night ? Color(red: 0.35, green: 0.28, blue: 0.24) : Color(red: 0.55, green: 0.40, blue: 0.28)
        let fabric = night ? Color(red: 0.40, green: 0.34, blue: 0.52) : Color(red: 0xF5 / 255.0, green: 0xC6 / 255.0, blue: 0xA8 / 255.0)
        let screen = night ? Color(red: 0.35, green: 0.55, blue: 0.70) : Color(red: 0.45, green: 0.65, blue: 0.85)

        // Curtains — flush to window sides (wall band)
        let curtainW = max(8, win.width * 0.12)
        context.fill(Path(CGRect(x: win.minX - curtainW - 2, y: win.minY - 4, width: curtainW, height: win.height + 10)), with: .color(fabric.opacity(0.9)))
        context.fill(Path(CGRect(x: win.maxX + 2, y: win.minY - 4, width: curtainW, height: win.height + 10)), with: .color(fabric.opacity(0.85)))
        // Curtain rod
        context.fill(Path(CGRect(x: win.minX - curtainW - 4, y: win.minY - 6, width: win.width + curtainW * 2 + 8, height: 3)), with: .color(wood))

        // Sofa — left margin only (≤0.20), seat on floor
        let sofaX = w * 0.02
        let sofaW = w * 0.16
        let sofaH = h * 0.10
        context.fill(Path(roundedRect: CGRect(x: sofaX, y: floorY - sofaH, width: sofaW, height: sofaH), cornerRadius: 6), with: .color(fabric))
        context.fill(Path(roundedRect: CGRect(x: sofaX, y: floorY - sofaH - 10, width: sofaW * 0.22, height: 14), cornerRadius: 3), with: .color(fabric.opacity(0.9)))
        context.fill(Path(roundedRect: CGRect(x: sofaX + sofaW * 0.78, y: floorY - sofaH - 10, width: sofaW * 0.22, height: 14), cornerRadius: 3), with: .color(fabric.opacity(0.9)))
        // Pillows
        context.fill(Path(ellipseIn: CGRect(x: sofaX + 6, y: floorY - sofaH + 4, width: 12, height: 10)), with: .color(Color(red: 0xFA / 255.0, green: 0x85 / 255.0, blue: 0x6B / 255.0).opacity(0.85)))
        context.fill(Path(ellipseIn: CGRect(x: sofaX + sofaW - 20, y: floorY - sofaH + 5, width: 11, height: 9)), with: .color(Color(red: 0.55, green: 0.70, blue: 0.55).opacity(0.9)))

        // TV + stand — right margin (≥0.82)
        let tvX = w * 0.84
        let tvY = floorY - h * 0.22
        context.fill(Path(CGRect(x: tvX, y: floorY - 8, width: w * 0.12, height: 6)), with: .color(wood)) // stand
        context.fill(Path(roundedRect: CGRect(x: tvX + 2, y: tvY, width: w * 0.11, height: h * 0.12), cornerRadius: 3), with: .color(Color(red: 0.18, green: 0.18, blue: 0.20)))
        context.fill(Path(roundedRect: CGRect(x: tvX + 5, y: tvY + 4, width: w * 0.11 - 6, height: h * 0.12 - 10), cornerRadius: 2), with: .color(screen.opacity(0.85)))

        // Extra wall art — upper right wall (outside mid-band)
        let art = CGRect(x: w * 0.78, y: h * 0.12, width: 18, height: 16)
        context.fill(Path(art.insetBy(dx: -2, dy: -2)), with: .color(wood))
        context.fill(Path(art), with: .color(night ? Color(red: 0.55, green: 0.45, blue: 0.70) : Color(red: 0.70, green: 0.80, blue: 0.95)))
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

        // Plant pot — right margin (keep mid-band clear)
        let potX = w * 0.82
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

        // Pass 18 props — margins / wall only (mid-band 0.22–0.78 clear)
        // Window seat cushion (behind pet Y / against wall under window)
        let cushion = CGRect(x: win.minX + 4, y: win.maxY - 2, width: win.width - 8, height: 10)
        context.fill(Path(roundedRect: cushion, cornerRadius: 4), with: .color(Color(red: 0xF5 / 255.0, green: 0xC6 / 255.0, blue: 0xA8 / 255.0)))
        // Picture frame — wall right of shelf
        let frame = CGRect(x: w * 0.88, y: h * 0.18, width: 16, height: 14)
        context.fill(Path(frame.insetBy(dx: -2, dy: -2)), with: .color(Color(red: 0.55, green: 0.40, blue: 0.28)))
        context.fill(Path(frame), with: .color(Color(red: 0.55, green: 0.75, blue: 0.55)))
        // Yarn basket — right margin (outside plant)
        let basketX = w * 0.90
        let basketY = floorY - 4
        context.fill(Path(ellipseIn: CGRect(x: basketX, y: basketY - 14, width: 22, height: 16)), with: .color(Color(red: 0.72, green: 0.55, blue: 0.38)))
        context.fill(Path(ellipseIn: CGRect(x: basketX + 5, y: basketY - 18, width: 10, height: 10)), with: .color(Color(red: 0xFA / 255.0, green: 0x85 / 255.0, blue: 0x6B / 255.0)))
        // Floor pouf — left margin
        context.fill(Path(ellipseIn: CGRect(x: w * 0.06, y: floorY - 6, width: 28, height: 14)), with: .color(Color(red: 0xF5 / 255.0, green: 0xC6 / 255.0, blue: 0xA8 / 255.0).opacity(0.95)))
        context.fill(Path(ellipseIn: CGRect(x: w * 0.08, y: floorY - 10, width: 22, height: 10)), with: .color(Color(red: 0.93, green: 0.70, blue: 0.55)))

        // R6 indoor density
        drawIndoorFurnitureDensity(context: context, size: size, floorY: floorY, win: win, night: false)
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

        // Night bloom pot — right margin (upgrade plant)
        let potX = w * 0.86
        let potY = floorY - 8
        context.fill(
            Path(CGRect(x: potX, y: potY - 30, width: 16, height: 20)),
            with: .color(Color(red: 0.28, green: 0.48, blue: 0.42))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: potX + 3, y: potY - 36, width: 10, height: 10)),
            with: .color(Color(red: 0.85, green: 0.88, blue: 0.95))
        )
        context.fill(
            Path(CGRect(x: potX + 1, y: potY - 10, width: 14, height: 12)),
            with: .color(Color(red: 0.45, green: 0.35, blue: 0.30))
        )

        // Pass 18 props — margins / wall / sky only
        // Porch rail — left margin silhouette
        let railX = w * 0.04
        context.fill(Path(CGRect(x: railX, y: floorY - 36, width: 4, height: 36)), with: .color(Color(red: 0.35, green: 0.28, blue: 0.24)))
        context.fill(Path(CGRect(x: railX + 14, y: floorY - 36, width: 4, height: 36)), with: .color(Color(red: 0.35, green: 0.28, blue: 0.24)))
        context.fill(Path(CGRect(x: railX, y: floorY - 38, width: 18, height: 4)), with: .color(Color(red: 0.42, green: 0.34, blue: 0.28)))
        // Hanging lantern — upper right / sky-wall band
        let lanX = w * 0.90
        let lanY = h * 0.14
        context.stroke(
            Path { p in
                p.move(to: CGPoint(x: lanX + 6, y: h * 0.10))
                p.addLine(to: CGPoint(x: lanX + 6, y: lanY))
            },
            with: .color(.white.opacity(0.35)),
            lineWidth: 1.5
        )
        context.fill(Path(ellipseIn: CGRect(x: lanX, y: lanY, width: 14, height: 16)), with: .color(lamp.opacity(0.9)))
        context.fill(Path(ellipseIn: CGRect(x: lanX - 4, y: lanY + 2, width: 22, height: 20)), with: .color(lamp.opacity(0.22)))
        // Indigo floor cushion — left margin
        context.fill(Path(ellipseIn: CGRect(x: w * 0.08, y: floorY - 4, width: 26, height: 12)), with: .color(Color(red: 0.32, green: 0.28, blue: 0.42)))
        context.fill(Path(ellipseIn: CGRect(x: w * 0.10, y: floorY - 8, width: 20, height: 9)), with: .color(Color(red: 0.40, green: 0.34, blue: 0.52)))

        drawIndoorFurnitureDensity(context: context, size: size, floorY: floorY, win: win, night: true)
    }
    /// Soft teal `#7ec8c8` water window, sand floor — Tide Glass.
    private func drawTideGlass(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let teal = Color(red: 0x7e/255.0, green: 0xc8/255.0, blue: 0xc8/255.0)
        let sand = Color(red: 0.90, green: 0.82, blue: 0.62)
        let wall = Color(red: 0.82, green: 0.90, blue: 0.88)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(wall))
        let floorY = h * 0.62
        context.fill(Path(CGRect(x: 0, y: floorY, width: w, height: h - floorY)), with: .color(sand))
        for i in 0..<6 {
            let y = floorY + CGFloat(i) * ((h - floorY) / 6)
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y))
            line.addLine(to: CGPoint(x: w, y: y))
            context.stroke(line, with: .color(.black.opacity(0.06)), lineWidth: 1)
        }
        let win = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.40, height: h * 0.34)
        context.fill(Path(win.insetBy(dx: -6, dy: -6)), with: .color(Color(red: 0.45, green: 0.62, blue: 0.62)))
        context.fill(
            Path(win),
            with: .linearGradient(
                Gradient(colors: [teal, Color(red: 0.55, green: 0.78, blue: 0.82)]),
                startPoint: CGPoint(x: win.midX, y: win.minY),
                endPoint: CGPoint(x: win.midX, y: win.maxY)
            )
        )
        // Soft wave lines
        for i in 0..<3 {
            var wave = Path()
            let yy = win.minY + win.height * (0.35 + CGFloat(i) * 0.18)
            wave.move(to: CGPoint(x: win.minX + 6, y: yy))
            wave.addQuadCurve(to: CGPoint(x: win.maxX - 6, y: yy), control: CGPoint(x: win.midX, y: yy - 6))
            context.stroke(wave, with: .color(.white.opacity(0.35)), lineWidth: 2)
        }
        let rug = CGRect(x: w * 0.28, y: h * 0.72, width: w * 0.44, height: h * 0.12)
        context.fill(Path(roundedRect: rug, cornerRadius: 8), with: .color(teal.opacity(0.45)))

        // Pass 18 props — margins / wall only (water stays in window)
        // Glass float / buoy — wall hook upper right of window
        let floatR = CGRect(x: w * 0.58, y: h * 0.16, width: 16, height: 16)
        context.fill(Path(ellipseIn: floatR), with: .color(teal.opacity(0.85)))
        context.stroke(Path(ellipseIn: floatR.insetBy(dx: 3, dy: 3)), with: .color(.white.opacity(0.45)), lineWidth: 1.5)
        // Shell trio — left margin sand
        let shellY = floorY + 6
        context.fill(Path(ellipseIn: CGRect(x: w * 0.06, y: shellY, width: 10, height: 7)), with: .color(Color(red: 0.95, green: 0.88, blue: 0.78)))
        context.fill(Path(ellipseIn: CGRect(x: w * 0.10, y: shellY + 2, width: 8, height: 6)), with: .color(Color(red: 0.90, green: 0.78, blue: 0.70)))
        context.fill(Path(ellipseIn: CGRect(x: w * 0.14, y: shellY, width: 9, height: 6)), with: .color(Color(red: 0.92, green: 0.85, blue: 0.72)))
        // Seaweed pot — left margin
        context.fill(Path(CGRect(x: w * 0.08, y: floorY - 26, width: 8, height: 18)), with: .color(Color(red: 0.25, green: 0.55, blue: 0.42)))
        context.fill(Path(CGRect(x: w * 0.12, y: floorY - 22, width: 7, height: 14)), with: .color(Color(red: 0.22, green: 0.50, blue: 0.38)))
        context.fill(Path(CGRect(x: w * 0.07, y: floorY - 8, width: 16, height: 10)), with: .color(Color(red: 0.70, green: 0.55, blue: 0.40)))
        // Driftwood stump — right margin
        context.fill(Path(roundedRect: CGRect(x: w * 0.84, y: floorY - 16, width: 28, height: 16), cornerRadius: 4), with: .color(Color(red: 0.55, green: 0.42, blue: 0.30)))
        context.fill(Path(CGRect(x: w * 0.88, y: floorY - 22, width: 10, height: 8)), with: .color(Color(red: 0.48, green: 0.36, blue: 0.26)))

        drawIndoorFurnitureDensity(context: context, size: size, floorY: floorY, win: win, night: false)
    }

    /// Mauve `#c4a0c8` sky, warm windows — Skyline Dusk.
    private func drawSkylineDusk(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let mauve = Color(red: 0xc4/255.0, green: 0xa0/255.0, blue: 0xc8/255.0)
        let wall = Color(red: 0.36, green: 0.28, blue: 0.40)
        let floor = Color(red: 0.30, green: 0.24, blue: 0.28)
        let lamp = Color(red: 1.0, green: 0.85, blue: 0.55)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(wall))
        let floorY = h * 0.62
        context.fill(Path(CGRect(x: 0, y: floorY, width: w, height: h - floorY)), with: .color(floor))
        let win = CGRect(x: w * 0.10, y: h * 0.10, width: w * 0.48, height: h * 0.36)
        context.fill(Path(win.insetBy(dx: -5, dy: -5)), with: .color(Color(red: 0.28, green: 0.22, blue: 0.32)))
        context.fill(
            Path(win),
            with: .linearGradient(
                Gradient(colors: [mauve, Color(red: 0.45, green: 0.30, blue: 0.48)]),
                startPoint: CGPoint(x: win.midX, y: win.minY),
                endPoint: CGPoint(x: win.midX, y: win.maxY)
            )
        )
        // Distant warm windows
        for (x, y) in [(0.18, 0.22), (0.28, 0.30), (0.38, 0.20), (0.45, 0.28)] {
            context.fill(
                Path(CGRect(x: win.minX + win.width * x, y: win.minY + win.height * y, width: 5, height: 7)),
                with: .color(lamp.opacity(0.85))
            )
        }
        let rug = CGRect(x: w * 0.28, y: h * 0.72, width: w * 0.44, height: h * 0.12)
        context.fill(Path(roundedRect: rug, cornerRadius: 8), with: .color(mauve.opacity(0.4)))
        context.fill(
            Path(ellipseIn: CGRect(x: w * 0.68, y: h * 0.20, width: 28, height: 22)),
            with: .color(lamp.opacity(0.3))
        )

        // Pass 18 props — margins / sill / wall
        // City sill planters inside window frame
        context.fill(Path(CGRect(x: win.minX + 8, y: win.maxY - 10, width: 14, height: 6)), with: .color(Color(red: 0.45, green: 0.35, blue: 0.30)))
        context.fill(Path(CGRect(x: win.minX + 12, y: win.maxY - 16, width: 6, height: 8)), with: .color(Color(red: 0.35, green: 0.55, blue: 0.38)))
        context.fill(Path(CGRect(x: win.maxX - 24, y: win.maxY - 10, width: 14, height: 6)), with: .color(Color(red: 0.45, green: 0.35, blue: 0.30)))
        context.fill(Path(CGRect(x: win.maxX - 20, y: win.maxY - 16, width: 6, height: 8)), with: .color(Color(red: 0.32, green: 0.50, blue: 0.36)))
        // Floor lamp — right margin (readable body + warm pool)
        let flX = w * 0.88
        context.fill(Path(ellipseIn: CGRect(x: flX - 10, y: floorY - 52, width: 28, height: 18)), with: .color(lamp.opacity(0.35)))
        context.fill(Path(ellipseIn: CGRect(x: flX - 4, y: floorY - 48, width: 16, height: 12)), with: .color(lamp))
        context.fill(Path(CGRect(x: flX + 2, y: floorY - 38, width: 4, height: 38)), with: .color(Color(red: 0.40, green: 0.32, blue: 0.28)))
        context.fill(Path(ellipseIn: CGRect(x: flX - 6, y: floorY - 4, width: 20, height: 6)), with: .color(Color(red: 0.35, green: 0.28, blue: 0.26)))
        // Throw blanket heap — left margin (under/beside table cluster)
        context.fill(Path(roundedRect: CGRect(x: w * 0.02, y: floorY - 6, width: w * 0.14, height: 11), cornerRadius: 4), with: .color(mauve.opacity(0.85)))
        context.fill(Path(roundedRect: CGRect(x: w * 0.04, y: floorY - 12, width: w * 0.10, height: 7), cornerRadius: 3), with: .color(Color(red: 0xFA / 255.0, green: 0x85 / 255.0, blue: 0x6B / 255.0).opacity(0.75)))
        // Side table + mug — left margin only (≤0.18)
        context.fill(Path(CGRect(x: w * 0.12, y: floorY - 20, width: w * 0.06, height: 4)), with: .color(Color(red: 0.42, green: 0.32, blue: 0.28)))
        context.fill(Path(CGRect(x: w * 0.13, y: floorY - 16, width: 3, height: 16)), with: .color(Color(red: 0.38, green: 0.28, blue: 0.24)))
        context.fill(Path(CGRect(x: w * 0.16, y: floorY - 16, width: 3, height: 16)), with: .color(Color(red: 0.38, green: 0.28, blue: 0.24)))
        context.fill(Path(roundedRect: CGRect(x: w * 0.135, y: floorY - 28, width: 8, height: 7), cornerRadius: 2), with: .color(Color(red: 0.92, green: 0.88, blue: 0.82)))

        drawIndoorFurnitureDensity(context: context, size: size, floorY: floorY, win: win, night: true)
    }

    /// Soft day meadow with dirt path — outdoor horizon (pass 18).
    private func drawMeadowWalk(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let skyTop = Color(red: 0xA8 / 255.0, green: 0xD4 / 255.0, blue: 0xF0 / 255.0)
        let skyBot = Color(red: 0xD6 / 255.0, green: 0xEA / 255.0, blue: 0xF8 / 255.0)
        let hills = Color(red: 0x8F / 255.0, green: 0xBF / 255.0, blue: 0x8A / 255.0)
        let horizon = Color(red: 0x6F / 255.0, green: 0xA0 / 255.0, blue: 0x6A / 255.0)
        let nearGrass = Color(red: 0x7C / 255.0, green: 0xB8 / 255.0, blue: 0x7A / 255.0)
        let grassShadow = Color(red: 0x5A / 255.0, green: 0x94 / 255.0, blue: 0x58 / 255.0)
        let pathFill = Color(red: 0xC4 / 255.0, green: 0xA5 / 255.0, blue: 0x74 / 255.0)
        let pathEdge = Color(red: 0xA8 / 255.0, green: 0x88 / 255.0, blue: 0x58 / 255.0)
        let fenceWood = Color(red: 0x8B / 255.0, green: 0x6B / 255.0, blue: 0x4A / 255.0)
        let fenceHi = Color(red: 0xB0 / 255.0, green: 0x89 / 255.0, blue: 0x60 / 255.0)
        let flowerPink = Color(red: 0xF2 / 255.0, green: 0xA0 / 255.0, blue: 0xB8 / 255.0)
        let flowerYellow = Color(red: 0xF0 / 255.0, green: 0xD0 / 255.0, blue: 0x60 / 255.0)
        let flowerCenter = Color(red: 0xE8 / 255.0, green: 0xA0 / 255.0, blue: 0x40 / 255.0)

        // 1. Sky gradient
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                Gradient(colors: [skyTop, skyBot]),
                startPoint: CGPoint(x: w * 0.5, y: 0),
                endPoint: CGPoint(x: w * 0.5, y: h * 0.55)
            )
        )

        // 2. Clouds (upper sky; left + right — mid-band X free below)
        func cloud(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) {
            context.fill(Path(ellipseIn: CGRect(x: cx, y: cy, width: 22 * s, height: 12 * s)), with: .color(Color.white.opacity(0.85)))
            context.fill(Path(ellipseIn: CGRect(x: cx + 10 * s, y: cy - 4 * s, width: 18 * s, height: 14 * s)), with: .color(Color.white.opacity(0.85)))
            context.fill(Path(ellipseIn: CGRect(x: cx + 20 * s, y: cy + 1 * s, width: 16 * s, height: 11 * s)), with: .color(Color.white.opacity(0.85)))
            context.fill(Path(ellipseIn: CGRect(x: cx + 6 * s, y: cy + 6 * s, width: 20 * s, height: 8 * s)), with: .color(Color(red: 0xE8 / 255.0, green: 0xF0 / 255.0, blue: 0xF8 / 255.0).opacity(0.7)))
        }
        cloud(w * 0.06, h * 0.10, 1.1)
        cloud(w * 0.72, h * 0.14, 1.0)
        cloud(w * 0.40, h * 0.06, 0.75)

        // 3. Distant hills silhouette (~ y = 0.42–0.50)
        var hill = Path()
        hill.move(to: CGPoint(x: 0, y: h * 0.50))
        hill.addQuadCurve(to: CGPoint(x: w * 0.28, y: h * 0.42), control: CGPoint(x: w * 0.12, y: h * 0.40))
        hill.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * 0.46), control: CGPoint(x: w * 0.42, y: h * 0.44))
        hill.addQuadCurve(to: CGPoint(x: w, y: h * 0.44), control: CGPoint(x: w * 0.78, y: h * 0.38))
        hill.addLine(to: CGPoint(x: w, y: h * 0.58))
        hill.addLine(to: CGPoint(x: 0, y: h * 0.58))
        hill.closeSubpath()
        context.fill(hill, with: .color(hills))

        // 4. Horizon grass seam
        let floorY = h * 0.58
        context.fill(Path(CGRect(x: 0, y: floorY - 4, width: w, height: 6)), with: .color(horizon))

        // 5. Near grass floor
        context.fill(Path(CGRect(x: 0, y: floorY, width: w, height: h - floorY)), with: .color(nearGrass))
        // Soft grass clumps (margins + under fence — not mid walk blockers)
        for (gx, gw) in [(0.04, 0.10), (0.88, 0.10), (0.00, 0.06)] as [(CGFloat, CGFloat)] {
            context.fill(Path(ellipseIn: CGRect(x: w * gx, y: floorY + h * 0.08, width: w * gw, height: h * 0.04)), with: .color(grassShadow.opacity(0.35)))
        }

        // 6. Dirt path through mid-band (~14% height, ~60% width)
        let pathH = h * 0.14
        let path = CGRect(x: w * 0.20, y: floorY - pathH * 0.35, width: w * 0.60, height: pathH)
        context.fill(Path(roundedRect: path, cornerRadius: 10), with: .color(pathFill))
        context.stroke(Path(roundedRect: path, cornerRadius: 10), with: .color(pathEdge.opacity(0.55)), lineWidth: 2)

        // 7. Path stones on edges (not centerline)
        let stoneYTop = path.minY + 2
        let stoneYBot = path.maxY - 8
        for (sx, sy) in [
            (0.24, stoneYTop), (0.32, stoneYBot), (0.45, stoneYTop + 2),
            (0.58, stoneYBot), (0.68, stoneYTop), (0.74, stoneYBot - 1)
        ] as [(CGFloat, CGFloat)] {
            context.fill(
                Path(ellipseIn: CGRect(x: w * sx, y: sy, width: 7, height: 5)),
                with: .color(pathEdge.opacity(0.85))
            )
        }

        // 8. Fence — LEFT margin only (posts outside 0.22–0.78)
        let postXs: [CGFloat] = [0.05, 0.11, 0.17]
        for px in postXs {
            let x = w * px
            context.fill(Path(CGRect(x: x, y: floorY - 34, width: 5, height: 34)), with: .color(fenceWood))
            context.fill(Path(CGRect(x: x, y: floorY - 34, width: 5, height: 3)), with: .color(fenceHi))
        }
        context.fill(Path(CGRect(x: w * 0.05, y: floorY - 28, width: w * 0.14, height: 3.5)), with: .color(fenceWood))
        context.fill(Path(CGRect(x: w * 0.05, y: floorY - 16, width: w * 0.14, height: 3.5)), with: .color(fenceWood))
        context.fill(Path(CGRect(x: w * 0.05, y: floorY - 28, width: w * 0.14, height: 1.5)), with: .color(fenceHi.opacity(0.7)))

        // 9. Flower clusters — LEFT + RIGHT margins only
        func flowerCluster(atX fx: CGFloat, baseY: CGFloat) {
            let colors = [flowerPink, flowerYellow, flowerPink, flowerYellow]
            let offsets: [(CGFloat, CGFloat)] = [(-6, -4), (4, -8), (10, -2), (-2, -12)]
            for (i, off) in offsets.enumerated() {
                let r = CGRect(x: fx + off.0, y: baseY + off.1, width: 8, height: 8)
                context.fill(Path(ellipseIn: r), with: .color(colors[i % colors.count]))
                context.fill(Path(ellipseIn: r.insetBy(dx: 2.5, dy: 2.5)), with: .color(flowerCenter))
            }
            // Stems / leaves
            context.fill(Path(CGRect(x: fx + 2, y: baseY, width: 3, height: 10)), with: .color(grassShadow))
            context.fill(Path(CGRect(x: fx + 8, y: baseY + 2, width: 3, height: 8)), with: .color(nearGrass))
        }
        flowerCluster(atX: w * 0.10, baseY: floorY - 6)
        flowerCluster(atX: w * 0.88, baseY: floorY - 4)

        // Optional butterfly mote (cosmetic 2×2)
        context.fill(Path(CGRect(x: w * 0.30, y: h * 0.30, width: 2, height: 2)), with: .color(flowerPink.opacity(0.9)))
        context.fill(Path(CGRect(x: w * 0.70, y: h * 0.26, width: 2, height: 2)), with: .color(flowerYellow.opacity(0.85)))
    }

}

/// Convenience scene host with animated Nubby.
public struct PetRoomSceneView: View {
    public var scene: PetRoomScene
    public var mood: PetMood
    public var pose: PetPose
    public var isSleeping: Bool
    public var petScale: CGFloat
    public var speciesId: String
    public var growthStage: GrowthStage
    public var firefliesUnlocked: Int
    public var showFireflies: Bool
    public var bounceOffset: CGFloat
    public var petXFraction: CGFloat
    public var facingLeft: Bool
    public var droppedSymbol: String?
    public var droppedXFraction: CGFloat
    public var ballVisible: Bool
    public var ballXFraction: CGFloat
    public var ballYFraction: CGFloat
    public var onBallTap: (() -> Void)?
    public var wandVisible: Bool
    public var wandXFraction: CGFloat
    public var wandYFraction: CGFloat
    public var onRoomDrag: ((CGFloat, CGFloat) -> Void)?
    public var onPetTap: (() -> Void)?
    public var onPetDrag: (() -> Void)?

    public init(
        scene: PetRoomScene = .sunNook,
        mood: PetMood = .content,
        pose: PetPose = .idle,
        isSleeping: Bool = false,
        petScale: CGFloat = 1.1,
        speciesId: String = "nubby",
        growthStage: GrowthStage = .nubby,
        firefliesUnlocked: Int = 0,
        showFireflies: Bool = true,
        bounceOffset: CGFloat = 0,
        petXFraction: CGFloat = 0.52,
        facingLeft: Bool = false,
        droppedSymbol: String? = nil,
        droppedXFraction: CGFloat = 0.7,
        ballVisible: Bool = false,
        ballXFraction: CGFloat = 0.72,
        ballYFraction: CGFloat = 0.70,
        onBallTap: (() -> Void)? = nil,
        wandVisible: Bool = false,
        wandXFraction: CGFloat = 0.5,
        wandYFraction: CGFloat = 0.4,
        onRoomDrag: ((CGFloat, CGFloat) -> Void)? = nil,
        onPetTap: (() -> Void)? = nil,
        onPetDrag: (() -> Void)? = nil
    ) {
        self.scene = scene
        self.mood = mood
        self.pose = pose
        self.isSleeping = isSleeping
        self.petScale = petScale
        self.speciesId = speciesId
        self.growthStage = growthStage
        self.firefliesUnlocked = firefliesUnlocked
        self.showFireflies = showFireflies
        self.bounceOffset = bounceOffset
        self.petXFraction = petXFraction
        self.facingLeft = facingLeft
        self.droppedSymbol = droppedSymbol
        self.droppedXFraction = droppedXFraction
        self.ballVisible = ballVisible
        self.ballXFraction = ballXFraction
        self.ballYFraction = ballYFraction
        self.onBallTap = onBallTap
        self.wandVisible = wandVisible
        self.wandXFraction = wandXFraction
        self.wandYFraction = wandYFraction
        self.onRoomDrag = onRoomDrag
        self.onPetTap = onPetTap
        self.onPetDrag = onPetDrag
    }

    public var body: some View {
        RoomSceneView(
            scene: scene,
            mood: mood,
            firefliesUnlocked: firefliesUnlocked,
            showFireflies: showFireflies,
            petXFraction: petXFraction,
            facingLeft: facingLeft,
            droppedSymbol: droppedSymbol,
            droppedXFraction: droppedXFraction,
            ballVisible: ballVisible,
            ballXFraction: ballXFraction,
            ballYFraction: ballYFraction,
            onBallTap: onBallTap,
            wandVisible: wandVisible,
            wandXFraction: wandXFraction,
            wandYFraction: wandYFraction,
            onRoomDrag: onRoomDrag,
            onPetDrag: onPetDrag
        ) {
            TappablePetHost(onTap: onPetTap, onDrag: onPetDrag) {
                AnimatedPixelPetView(
                    mood: mood,
                    pose: pose,
                    isSleeping: isSleeping,
                    scale: petScale,
                    speciesId: speciesId,
                    growthStage: growthStage
                )
                .offset(y: bounceOffset)
            }
        }
    }
}

/// Scales the pet on press and forwards taps (heart/bob without inventory).
private struct TappablePetHost<Content: View>: View {
    var onTap: (() -> Void)?
    var onDrag: (() -> Void)?
    @ViewBuilder var content: () -> Content
    @State private var pressed = false
    @State private var lastDragFire: Date = .distantPast

    var body: some View {
        content()
            .scaleEffect(pressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.48), value: pressed)
            .contentShape(Rectangle().size(width: 140, height: 140))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !pressed {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.48)) { pressed = true }
                        }
                        // Stroke petting: fire while dragging across the pet
                        if hypot(value.translation.width, value.translation.height) > 8 {
                            let now = Date()
                            if now.timeIntervalSince(lastDragFire) > 0.28 {
                                lastDragFire = now
                                #if canImport(UIKit)
                                UIImpactFeedbackGenerator(.light).impactOccurred()
                                #endif
                                onDrag?()
                            }
                        }
                    }
                    .onEnded { value in
                        let traveled = hypot(value.translation.width, value.translation.height)
                        if traveled < 8 {
                            #if canImport(UIKit)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                            onTap?()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) { pressed = false }
                        }
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Pet me")
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


/// Cosmetic 4×4 soft-pixel motes — user copy: Fireflies (not spirits).
struct FirefliesOverlay: View {
    var count: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.45, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<min(count, 2), id: \.self) { i in
                        let phase = t * (0.7 + Double(i) * 0.35) + Double(i)
                        let x = geo.size.width * (0.78 + 0.08 * CGFloat(sin(phase)))
                        let y = geo.size.height * (0.22 + 0.10 * CGFloat(cos(phase * 1.3)))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 1.0, green: 0.92, blue: 0.55).opacity(0.75 + 0.2 * sin(phase)))
                            .frame(width: 4, height: 4)
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
