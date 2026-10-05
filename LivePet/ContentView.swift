import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject private var store: PetStore
    @EnvironmentObject private var activityManager: PetLiveActivityManager

    @State private var roomDim = false
    @State private var playBounce: CGFloat = 0
    @State private var poseClearTask: Task<Void, Never>?

    // Console sheets
    @State private var showSettings = false
    @State private var showFood = false
    @State private var showGames = false
    @State private var showPets = false
    @State private var showScenes = false
    @State private var showWidgets = false
    @State private var showShop = false
    @State private var showInventory = false
    @State private var showInfo = false

    // Continuous walk (≥40pt across room)
    @State private var petX: CGFloat = 0.52
    @State private var facingLeft = false
    @State private var walkTask: Task<Void, Never>?
    @State private var careBusy = false

    // Drop-to-room
    @State private var droppedSymbol: String?
    @State private var droppedX: CGFloat = 0.70
    @State private var ballVisible = false
    @State private var ballX: CGFloat = 0.72
    @State private var ballY: CGFloat = 0.70
    @State private var wandVisible = false
    @State private var wandSpriteName = "prop-wand"
    @State private var wandInteractive = false
    @State private var wandX: CGFloat = 0.55
    @State private var wandY: CGFloat = 0.38
    @State private var showHitIsland = false
    @State private var brain = PetBrain()
    @State private var pendingFoodId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                roomBackground.ignoresSafeArea()

                // Rebuild: the room is the app. No console dashboard.
                ZStack(alignment: .bottom) {
                    roomViewport
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        if store.isGrowEligible {
                            growChip.padding(.bottom, 8)
                        }
                        InventoryPanel(
                            store: store,
                            onFood: { item in
                                dropFoodAndEat(item)
                            },
                            onToy: { item in
                                switch item.id {
                                case "twinkle_ball":
                                    store.play(itemID: item.id)
                                    startPlayBall()
                                case "soft_square", "bounce_block":
                                    dropToyAndPlay(item)
                                default:
                                    dropToyAndPlay(item)
                                }
                            },
                            onClean: {
                                performClean()
                            }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                        toyDock
                    }
                }


                // Cream food/play overlays (layout 21 R4 — prefer overlay; console stays visible)
                if showFood {
                    Color.black.opacity(0.45).ignoresSafeArea()
                        .onTapGesture { showFood = false }
                        .zIndex(19)
                    SelectFoodSheet(store: store, onPick: { item in
                        showFood = false
                        dropFoodAndEat(item)
                    }, onClose: { showFood = false })
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(20)
                }
                if showGames {
                    Color.black.opacity(0.45).ignoresSafeArea()
                        .onTapGesture { showGames = false }
                        .zIndex(19)
                    SelectGameSheet(
                        petName: store.pet.name,
                        onPlayBall: { showGames = false; startPlayBall() },
                        onFollowWand: { showGames = false; startFollowWand() },
                        onHitIsland: {
                            showGames = false
                            PetSound.shared.play(.islandStart)
                            showHitIsland = true
                        },
                        onClose: { showGames = false }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(20)
                }

            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showHitIsland) {
                HitIslandGameView(
                    petName: store.pet.name,
                    speciesId: store.pet.petGlyph,
                    growthStage: store.pet.growthStage,
                    mood: store.pet.mood
                ) { catches in
                    finishHitIsland(catches: catches)
                }
            }
            .sheet(isPresented: $showPets) {
                PetsSheet(store: store) { syncActivity() }
            }
            .sheet(isPresented: $showScenes) {
                ScenesSheet(store: store, onPets: {
                    showScenes = false
                    showPets = true
                }, onWidgets: {
                    showScenes = false
                    showWidgets = true
                }, onShop: {
                    showScenes = false
                    showShop = true
                }, onInventory: {
                    showScenes = false
                    showInventory = true
                }, onSettings: {
                    showScenes = false
                    showSettings = true
                })
            }
            .sheet(isPresented: $showInfo) {
                InfoHowToSheet()
            }
            .sheet(isPresented: $showWidgets) {
                WidgetsGallerySheet()
            }
            .sheet(isPresented: $showShop) {
                ShopSheet(store: store, onFood: { item in
                    showShop = false
                    dropFoodAndEat(item)
                }, onPlayBall: {
                    showShop = false
                    startPlayBall()
                }, onFollowWand: {
                    showShop = false
                    startFollowWand()
                }, onHitIsland: {
                    showShop = false
                    PetSound.shared.play(.islandStart)
                    showHitIsland = true
                })
            }
            .sheet(isPresented: $showInventory) {
                InventorySheet(store: store, onFood: { item in
                    showInventory = false
                    dropFoodAndEat(item)
                }, onToy: { item in
                    showInventory = false
                    switch item.id {
                    case "twinkle_ball":
                        store.play(itemID: item.id)
                        startPlayBall()
                    case "soft_square":
                        store.play(itemID: item.id)
                        startFollowWand(showSoftSquare: true)
                    case "bounce_block":
                        dropToyAndPlay(item)
                    default:
                        dropToyAndPlay(item)
                    }
                })
            }
            .sheet(isPresented: $store.showGrowCelebration) {
                GrowCelebrationSheet(pet: store.pet) {
                    store.dismissGrowCelebration()
                }
            }
            .sheet(isPresented: $store.showMeetPip) {
                MeetPipSheet(
                    onMeet: { store.meetPip(switchActive: true) },
                    onSkip: { store.skipMeetPip() }
                )
            }
            .onAppear {
                store.onPetChange = { pet in
                    if activityManager.isActivityActive {
                        activityManager.renewIfNeeded(pet: pet)
                        activityManager.update(pet: pet)
                    }
                }
                store.startTicking()
                activityManager.renewIfNeeded(pet: store.pet)
                syncActivity()
                startBrain()
            }
            .onDisappear {
                store.stopTicking()
                poseClearTask?.cancel()
                walkTask?.cancel()
            }
            #if canImport(UIKit)
            .background(ShakeDetector().frame(width: 0, height: 0))
            .onReceive(NotificationCenter.default.publisher(for: .livePetDidShake)) { _ in
                performSleep()
            }
            #endif
        }
    }


    // MARK: - Room

    private var roomViewport: some View {
        PetRoomSceneView(
            scene: store.selectedScene,
            mood: store.pet.mood,
            pose: displayPose,
            isSleeping: store.pet.isSleeping,
            petScale: 2.1,
            speciesId: store.pet.petGlyph,
            growthStage: store.pet.growthStage,
            firefliesUnlocked: store.firefliesUnlocked,
            showFireflies: store.showFireflies,
            bounceOffset: playBounce,
            petXFraction: brain.x,
            facingLeft: brain.player.facingLeft,
            clipAnim: brain.player.anim,
            clipFrame: brain.player.frame,
            droppedSymbol: droppedSymbol,
            droppedXFraction: droppedX,
            ballVisible: ballVisible,
            ballXFraction: ballX,
            ballYFraction: ballY,
            onBallTap: { bounceBallHit() },
            wandVisible: wandVisible,
            wandSpriteName: wandSpriteName,
            wandXFraction: wandX,
            wandYFraction: wandY,
            onRoomDrag: wandInteractive ? { fx, fy in
                wandX = fx
                wandY = fy
            } : nil,
            onPetTap: { performPetTap() },
            onPetDoubleTap: { performPetDoubleTap() },
            onPetDrag: { performPetStroke() }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if roomDim {
                Color.black.opacity(0.10)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .allowsHitTesting(false)
            }
        }
    }

    /// Prefer care pose from store; otherwise walk when pacing.
    private var displayPose: PetPose {
        if store.pet.isSleeping || store.pet.pose == .sleep { return .sleep }
        if careBusy { return store.pet.pose }
        switch store.pet.pose {
        case .eat, .play, .clean: return store.pet.pose
        default: return careBusy ? store.pet.pose : .walk
        }
    }

    private var growChip: some View {
        Button {
            store.confirmGrow()
            syncActivity()
        } label: {
            HStack(spacing: 8) {
                ClipPetView(
                    speciesId: store.pet.petGlyph,
                    anim: .happy,
                    frame: 0,
                    facingLeft: false,
                    displaySize: 40
                )
                Text("Grow")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 1.0, green: 0.85, blue: 0.55), in: Capsule())
            }
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(store.growBannerTitle)
    }

    // MARK: - Continuous walk (P0 density)

    private func startBrain() {
        walkTask?.cancel()
        var last = Date()
        walkTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                let now = Date()
                let dt = now.timeIntervalSince(last)
                last = now
                brain.tick(dt: dt, sleeping: store.pet.isSleeping, mood: store.pet.mood)
                petX = brain.x
                facingLeft = brain.player.facingLeft
                if brain.consumeFeedReady(), let id = pendingFoodId {
                    pendingFoodId = nil
                    store.feed(itemID: id)
                    droppedSymbol = nil
                    PetSound.shared.play(.eatCrunch)
                    PetSound.shared.play(.meow)
                    pulseHeart(crumbs: true)
                    if store.lastUsedFavorite {
                        brain.reactFavoriteFood()
                    }
                    syncActivity()
                }
                if brain.consumeNapReady(), !store.pet.isSleeping, !careBusy, pendingFoodId == nil {
                    store.sleep()
                    PetSound.shared.play(.sleep)
                    pulseZzz()
                    syncActivity()
                }
                if brain.consumePlayReady() {
                    ballVisible = false
                    droppedSymbol = nil
                    store.playDefault()
                    pulseHeart(crumbs: false)
                    spawnPlayBurst()
                    careBusy = false
                    syncActivity()
                }
            }
        }
    }

    private var toyDock: some View {
        HStack(spacing: 8) {
            dockButton("ctrl-feed", "Feed") { showFood = true }
            dockButton("ctrl-play", "Play") { showGames = true }
            dockButton("ctrl-pet", "Pet") { performPetTap() }
            dockButton("ctrl-bath", "Bath") { performClean() }
            dockButton("ctrl-sleep", "Sleep") { performSleep() }
            dockButton("ctrl-more", "More") { showScenes = true }
        }
        .padding(.bottom, 10)
    }

    private func dockButton(_ image: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            PetSound.shared.play(.uiTick)
            action()
        } label: {
            Image(image)
                .resizable()
                .interpolation(.none)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func startIdleWalk() {
        walkTask?.cancel()
        walkTask = Task { @MainActor in
            while !Task.isCancelled {
                if careBusy || store.pet.isSleeping {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    continue
                }
                // Pace L/R across ~0.22...0.78 — denser never-static walk
                let target: CGFloat = facingLeft ? 0.22 : 0.78
                let start = petX
                let distance = abs(target - start)
                let steps = max(10, Int(distance * 36))
                for i in 1...steps {
                    if Task.isCancelled || careBusy || store.pet.isSleeping { break }
                    let t = CGFloat(i) / CGFloat(steps)
                    petX = start + (target - start) * t
                    try? await Task.sleep(nanoseconds: 42_000_000)
                }
                if careBusy || store.pet.isSleeping { continue }
                facingLeft.toggle()
                // Short edge pause — keep motion dense
                try? await Task.sleep(nanoseconds: 160_000_000)
            }
        }
    }

    // MARK: - Drop-to-room food

    private func dropFoodAndEat(_ item: InventoryItem) {
        careBusy = true
        pendingFoodId = item.id
        droppedX = brain.player.facingLeft ? 0.32 : 0.68
        brain.noticeFood(at: droppedX)
        droppedSymbol = item.pixelSpriteName ?? (store.pet.petGlyph == "pip" ? "prop-berry" : "prop-fish")
        PetSound.shared.play(.feed)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        Task { @MainActor in
            // Brain walks to the food and calls feed when the eat clip finishes.
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if pendingFoodId != nil {
                // Fail-safe if the clip never completes.
                if let id = pendingFoodId {
                    pendingFoodId = nil
                    store.feed(itemID: id)
                    droppedSymbol = nil
                    syncActivity()
                }
            }
            careBusy = false
            spawnPlayBurst()

            try? await Task.sleep(nanoseconds: 1_300_000_000)
            careBusy = false
        }
    }

    /// Drop a pixel toy in the room; pet walks over and plays (same path as food).
    private func dropToyAndPlay(_ item: InventoryItem) {
        guard !careBusy else { return }
        careBusy = true
        let dropX: CGFloat = brain.x < 0.5 ? 0.68 : 0.32
        // Soft Square must land as prop-soft (never wand / bounce fallback).
        if item.id == "soft_square" {
            droppedSymbol = "prop-soft"
        } else {
            droppedSymbol = item.pixelSpriteName ?? "prop-bounce"
        }
        droppedX = dropX
        brain.noticeToy(at: dropX)
        store.play(itemID: item.id)
        PetSound.shared.play(.play)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_500_000_000)
            if droppedSymbol != nil {
                droppedSymbol = nil
                syncActivity()
            }
            careBusy = false
        }
    }

    // MARK: - Play Ball (spawn → run → hit ≥1.5s + heart)

    private func startPlayBall() {
        guard !careBusy else { return }
        careBusy = true
        let dropX: CGFloat = brain.x < 0.5 ? 0.70 : 0.30
        ballX = dropX
        ballY = 0.22
        ballVisible = true
        brain.noticeToy(at: dropX)
        PetSound.shared.play(.play)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        Task { @MainActor in
            withAnimation(.easeIn(duration: 0.28)) { ballY = 0.70 }
            try? await Task.sleep(nanoseconds: 280_000_000)
            PetSound.shared.play(.ballBounce)
            // The brain walks to the ball. This only covers a clip that never finishes.
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            if ballVisible {
                ballVisible = false
                store.playDefault()
                syncActivity()
            }
            careBusy = false
        }
    }

    private func bounceBallHit() {
        guard ballVisible, !careBusy else { return }
        bouncePetPlay()
        pulseHeart(crumbs: false)
        spawnPlayBurst()
        PetSound.shared.play(.ballBoing)
        store.playDefault()
        schedulePoseClear(holdMs: 1100)
        syncActivity()
    }

    // MARK: - Follow the wand (drift + track ≥1.5s + heart)

    private func startFollowWand(showSoftSquare: Bool = false) {
        guard !careBusy else { return }
        careBusy = true
        brain.hold(3.2)
        wandX = 0.50
        wandY = 0.36
        wandSpriteName = showSoftSquare ? "prop-soft" : "prop-wand"
        if showSoftSquare {
            droppedSymbol = nil
        }
        wandVisible = true
        wandInteractive = true
        PetSound.shared.play(.play)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        Task { @MainActor in
            // Finger-follow: drag moves wand; pet tracks for ≥2s
            let duration: Double = 2.4
            let tick: UInt64 = 40_000_000
            var elapsed: Double = 0
            while elapsed < duration {
                if Task.isCancelled { break }
                let dx = wandX - brain.x
                let next = min(0.88, max(0.12, brain.x + dx * 0.22))
                brain.place(at: next, facingLeft: wandX < brain.x)
                // Soft hop while tracking
                if Int(elapsed * 10) % 4 == 0 {
                    bouncePet()
                }
                try? await Task.sleep(nanoseconds: tick)
                elapsed += Double(tick) / 1_000_000_000
            }
            wandInteractive = false
            store.playDefault()
            bouncePetPlay()
            pulseHeart(crumbs: false)
            spawnPlayBurst()
            schedulePoseClear(holdMs: 1600)
            syncActivity()
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation { wandVisible = false }
            wandSpriteName = "prop-wand"
            careBusy = false
        }
    }

    // MARK: - Hit the Island finish

    private func finishHitIsland(catches: Int) {
        showHitIsland = false
        // Completing the mini-game always bumps Feeling (play pose for Island sync).
        store.playDefault()
        bouncePet()
        if catches > 0 {
            pulseHeart(crumbs: false)
        }
        schedulePoseClear(holdMs: 1400)
        syncActivity()
    }

    // MARK: - Care (Clean / Sleep / tap)

    private func performClean() {
        careBusy = true
        brain.reactBath()
        store.clean()
        PetSound.shared.play(.clean)
        pulseBubbles()
        schedulePoseClear(holdMs: 3200)
        syncActivity()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            careBusy = false
        }
    }

    private func performSleep() {
        careBusy = true
        brain.reactSleep(on: true)
        store.sleep()
        PetSound.shared.play(.sleep)
        pulseZzz()
        syncActivity()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            careBusy = false
        }
    }

    private func performPetTap() {
        brain.reactPet()
        store.petTap()
        PetSound.shared.play(.pet)
        PetSound.shared.play(.meow)
        bouncePetPlay()
        pulseHeart(crumbs: false)
        spawnPlayBurst()
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        schedulePoseClear(holdMs: 1100)
        syncActivity()
    }

    /// Drag/stroke petting — denser bob + hearts, longer reaction ≥0.8–1.2s
    private func performPetStroke() {
        brain.reactGrab()
        store.petTap()
        PetSound.shared.play(.pet)
        PetSound.shared.play(.meow)
        bouncePetPlay()
        pulseHeart(crumbs: false)
        spawnPlayBurst()
        schedulePoseClear(holdMs: 1200)
        syncActivity()
    }

    /// Double-tap — jump or curious glance (brain picks).
    private func performPetDoubleTap() {
        brain.reactDoubleTap()
        store.petTap()
        PetSound.shared.play(.pet)
        PetSound.shared.play(.meow)
        bouncePetPlay()
        pulseHeart(crumbs: false)
        spawnPlayBurst()
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        schedulePoseClear(holdMs: 1100)
        syncActivity()
    }


    // MARK: - Feedback helpers

    private func bouncePet() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
            playBounce = -8
        }
        Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    playBounce = 0
                }
            }
        }
    }

    /// Clearer play pose bob — taller hop for ball chase / petting density
    private func bouncePetPlay() {
        withAnimation(.spring(response: 0.20, dampingFraction: 0.42)) {
            playBounce = -16
        }
        Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                    playBounce = -4
                }
            }
            try? await Task.sleep(nanoseconds: 140_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
                    playBounce = 0
                }
            }
        }
    }

    private func spawnPlayBurst() {
        // App Lead: floating star burst rejected — playing/happy sheets only.
    }

    private func pulseHeart(crumbs: Bool) {
        // App Lead: floating heart/star/crumbs rejected — happy sheet + sound only.
        PetSound.shared.play(.heartPop)
        _ = crumbs
    }

    private func pulseBubbles() {
        // App Lead: cyan bubble floaters rejected — bathing sheet only.
    }

    private func pulseZzz() {
        // App Lead: floating Zz rejected — sleep sheets only; soft room dim stays.
        withAnimation(.easeOut(duration: 0.2)) { roomDim = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.35)) { roomDim = false }
            }
        }
    }


    private func schedulePoseClear(holdMs: UInt64 = 900) {
        poseClearTask?.cancel()
        poseClearTask = Task {
            try? await Task.sleep(nanoseconds: holdMs * 1_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                store.clearTransientCarePose()
                syncActivity()
            }
        }
    }

    private func syncActivity() {
        guard activityManager.isActivityActive else { return }
        activityManager.renewIfNeeded(pet: store.pet)
        activityManager.update(pet: store.pet)
    }

    private var roomBackground: some View {
        switch store.selectedScene {
        case .sunNook:
            return AnyView(LinearGradient(
                colors: [Color(red: 0.98, green: 0.94, blue: 0.88), Color(red: 0.90, green: 0.95, blue: 0.92)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        case .moonPorch:
            return AnyView(LinearGradient(
                colors: [Color(red: 0x2C / 255.0, green: 0x3A / 255.0, blue: 0x4A / 255.0), Color(red: 0.18, green: 0.22, blue: 0.30)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        case .tideGlass:
            return AnyView(LinearGradient(
                colors: [Color(red: 0x7e / 255.0, green: 0xc8 / 255.0, blue: 0xc8 / 255.0).opacity(0.55), Color(red: 0.90, green: 0.95, blue: 0.93)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        case .skylineDusk:
            return AnyView(LinearGradient(
                colors: [Color(red: 0xc4 / 255.0, green: 0xa0 / 255.0, blue: 0xc8 / 255.0), Color(red: 0.28, green: 0.20, blue: 0.34)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        case .meadowWalk:
            return AnyView(LinearGradient(
                colors: [Color(red: 0xA8 / 255.0, green: 0xD4 / 255.0, blue: 0xF0 / 255.0), Color(red: 0xD6 / 255.0, green: 0xEA / 255.0, blue: 0xF8 / 255.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        case .snowPorch:
            return AnyView(LinearGradient(
                colors: [Color(red: 0.86, green: 0.90, blue: 0.94), Color(red: 0.74, green: 0.80, blue: 0.86)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        case .coralShelf:
            return AnyView(LinearGradient(
                colors: [Color(red: 0.86, green: 0.86, blue: 0.88), Color(red: 0.70, green: 0.70, blue: 0.72)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(PetStore())
        .environmentObject(PetLiveActivityManager())
}
