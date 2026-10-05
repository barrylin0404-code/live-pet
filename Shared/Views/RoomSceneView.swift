import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Room plate host — Designer plates fill the viewport; props / pet / fireflies overlay.
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
    /// Pixel lure while following — Soft Square uses `prop-soft`.
    public var wandSpriteName: String
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
        wandSpriteName: String = "prop-wand",
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
        self.wandSpriteName = wandSpriteName
        self.wandXFraction = wandXFraction
        self.wandYFraction = wandYFraction
        self.onRoomDrag = onRoomDrag
        self.onPetDrag = onPetDrag
        self.pet = pet
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                if let plate = scene.plateImageName {
                    Image(plate)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)
                }
                let feetY = CGFloat(scene.petFeetYFraction)
                if let symbol = droppedSymbol {
                    DroppedPropView(symbol: symbol)
                        .position(x: geo.size.width * droppedXFraction, y: geo.size.height * (feetY + 0.06))
                        .transition(.scale.combined(with: .opacity))
                }
                if ballVisible {
                    Image("prop-ball")
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 48, height: 48)
                        .position(x: geo.size.width * ballXFraction, y: geo.size.height * ballYFraction)
                        .onTapGesture { onBallTap?() }
                }
                if wandVisible {
                    Image(wandSpriteName)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 32, height: 64)
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
}

/// Food / toy prop that drops in from above, then settles on the floor line.
private struct DroppedPropView: View {
    var symbol: String
    @State private var settled = false

    var body: some View {
        Image(symbol)
            .resizable()
            .interpolation(.none)
            .frame(width: 48, height: 48)
            .offset(y: settled ? 0 : -56)
            .opacity(settled ? 1 : 0.35)
            .onAppear {
                settled = false
                withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                    settled = true
                }
            }
            .onChange(of: symbol) { _ in
                settled = false
                withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                    settled = true
                }
            }
    }
}

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
    public var wandSpriteName: String
    public var wandXFraction: CGFloat
    public var wandYFraction: CGFloat
    public var onRoomDrag: ((CGFloat, CGFloat) -> Void)?
    public var onPetTap: (() -> Void)?
    public var onPetDoubleTap: (() -> Void)?
    public var onPetDrag: (() -> Void)?
    public var clipAnim: PetAnim?
    public var clipFrame: Int

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
        wandSpriteName: String = "prop-wand",
        wandXFraction: CGFloat = 0.5,
        wandYFraction: CGFloat = 0.4,
        onRoomDrag: ((CGFloat, CGFloat) -> Void)? = nil,
        onPetTap: (() -> Void)? = nil,
        onPetDoubleTap: (() -> Void)? = nil,
        onPetDrag: (() -> Void)? = nil,
        clipAnim: PetAnim? = nil,
        clipFrame: Int = 0
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
        self.wandSpriteName = wandSpriteName
        self.wandXFraction = wandXFraction
        self.wandYFraction = wandYFraction
        self.onRoomDrag = onRoomDrag
        self.onPetTap = onPetTap
        self.onPetDoubleTap = onPetDoubleTap
        self.onPetDrag = onPetDrag
        self.clipAnim = clipAnim
        self.clipFrame = clipFrame
    }

    public var body: some View {
        RoomSceneView(
            scene: scene,
            mood: mood,
            firefliesUnlocked: firefliesUnlocked,
            showFireflies: showFireflies,
            petXFraction: petXFraction,
            facingLeft: clipAnim == nil ? facingLeft : false,
            droppedSymbol: droppedSymbol,
            droppedXFraction: droppedXFraction,
            ballVisible: ballVisible,
            ballXFraction: ballXFraction,
            ballYFraction: ballYFraction,
            onBallTap: onBallTap,
            wandVisible: wandVisible,
            wandSpriteName: wandSpriteName,
            wandXFraction: wandXFraction,
            wandYFraction: wandYFraction,
            onRoomDrag: onRoomDrag,
            onPetDrag: onPetDrag
        ) {
            TappablePetHost(onTap: onPetTap, onDoubleTap: onPetDoubleTap, onDrag: onPetDrag) {
                Group {
                    if let clipAnim {
                        ClipPetView(
                            speciesId: speciesId,
                            anim: clipAnim,
                            frame: clipFrame,
                            facingLeft: facingLeft,
                            displaySize: 78 * petScale,
                            growthStage: growthStage
                        )
                    } else {
                        ClipPetView(
                            speciesId: speciesId,
                            anim: .idle,
                            frame: clipFrame,
                            facingLeft: facingLeft,
                            displaySize: 78 * petScale,
                            growthStage: growthStage
                        )
                    }
                }
                .offset(y: bounceOffset)
            }
        }
    }
}

/// Scales the pet on press and forwards taps (heart/bob without inventory).
/// Single tap pets; a second tap within `doubleTapWindow` becomes a jump/curious double-tap.
/// The single tap waits exactly that window, so one gesture never fires both.
private struct TappablePetHost<Content: View>: View {
    var onTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?
    var onDrag: (() -> Void)?
    @ViewBuilder var content: () -> Content
    @State private var pressed = false
    @State private var lastDragFire: Date = .distantPast
    @State private var lastTapAt: Date = .distantPast
    @State private var pendingSingle: DispatchWorkItem?
    private let doubleTapWindow: TimeInterval = 0.26
    private let strokeRepeat: TimeInterval = 0.22

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
                            pendingSingle?.cancel()
                            pendingSingle = nil
                            let now = Date()
                            if now.timeIntervalSince(lastDragFire) > strokeRepeat {
                                lastDragFire = now
                                #if canImport(UIKit)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                            let now = Date()
                            if now.timeIntervalSince(lastTapAt) < doubleTapWindow, onDoubleTap != nil {
                                pendingSingle?.cancel()
                                pendingSingle = nil
                                lastTapAt = .distantPast
                                onDoubleTap?()
                            } else {
                                lastTapAt = now
                                pendingSingle?.cancel()
                                let work = DispatchWorkItem { onTap?() }
                                pendingSingle = work
                                DispatchQueue.main.asyncAfter(deadline: .now() + doubleTapWindow, execute: work)
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.55)) { pressed = false }
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
        TimelineView(.animation(minimumInterval: 0.35, paused: false)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                ZStack {
                    // Up to six soft motes when Fireflies B is unlocked.
                    ForEach(0..<min(max(count, 0), 6), id: \.self) { i in
                        let phase = t * (0.55 + Double(i) * 0.22) + Double(i) * 1.7
                        let baseX: CGFloat = [0.72, 0.84, 0.64, 0.90, 0.76, 0.58][i]
                        let baseY: CGFloat = [0.18, 0.28, 0.24, 0.16, 0.34, 0.22][i]
                        let x = geo.size.width * (baseX + 0.05 * CGFloat(sin(phase)))
                        let y = geo.size.height * (baseY + 0.06 * CGFloat(cos(phase * 1.25)))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 1.0, green: 0.92, blue: 0.55).opacity(0.55 + 0.35 * abs(sin(phase))))
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
