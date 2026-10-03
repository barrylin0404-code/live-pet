import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject private var store: PetStore
    @EnvironmentObject private var activityManager: PetLiveActivityManager

    @State private var showFloatingHeart = false
    @State private var showFloatingStar = false
    @State private var showBubbles = false
    @State private var showZzz = false
    @State private var crumbDots: [CareParticle] = []
    @State private var bubbleParticles: [CareParticle] = []
    @State private var roomDim = false
    @State private var playBounce: CGFloat = 0
    @State private var heartRise: CGFloat = 0
    @State private var poseClearTask: Task<Void, Never>?

    // Console sheets
    @State private var showSettings = false
    @State private var showFood = false
    @State private var showGames = false
    @State private var showPets = false
    @State private var showScenes = false
    @State private var showWidgets = false
    @State private var showInfo = false
    @State private var comingSoonText: String?

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
    @State private var wandInteractive = false
    @State private var playParticles: [CareParticle] = []
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
                        roomHUD
                        Spacer(minLength: 0)
                        if store.isGrowEligible {
                            growChip.padding(.bottom, 8)
                        }
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

                floatingFeedback.allowsHitTesting(false)

                if let soon = comingSoonText {
                    VStack {
                        Spacer()
                        ComingSoonBanner(title: soon)
                            .padding(.bottom, 120)
                    }
                    .transition(.opacity)
                    .allowsHitTesting(false)
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
                ScenesSheet(store: store)
            }
            .sheet(isPresented: $showInfo) {
                InfoHowToSheet()
            }
            .sheet(isPresented: $showWidgets) {
                WidgetsGallerySheet()
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


    // MARK: - Room HUD (layout 21 R10 / M10)

    private var roomHUD: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.30, blue: 0.43))
                Text("∞")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.82), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.5), lineWidth: 1))
            .accessibilityLabel("Hearts, unlimited — free forever")

            Spacer(minLength: 0)

            Button {
                PetSound.shared.play(.uiTick)
                showInfo = true
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.92))
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Info — how to play, free forever")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
            wandXFraction: wandX,
            wandYFraction: wandY,
            onRoomDrag: wandInteractive ? { fx, fy in
                wandX = fx
                wandY = fy
            } : nil,
            onPetTap: { performPetTap() },
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
                Image(systemName: "arrow.up.heart.fill")
                    .foregroundStyle(Color(red: 1.0, green: 0.30, blue: 0.43))
                Text(store.growBannerTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                Spacer(minLength: 0)
                Text("Grow")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 1.0, green: 0.85, blue: 0.55), in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(red: 1.0, green: 0.97, blue: 0.90), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var floatingFeedback: some View {
        GeometryReader { geo in
            let cx = geo.size.width * petX
            let cy = geo.size.height * 0.32

            ZStack {
                if showFloatingHeart {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.30, blue: 0.43))
                        .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                        .position(x: cx, y: cy + heartRise)
                        .transition(.opacity)
                }
                if showFloatingStar {
                    Image(systemName: "star.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0))
                        .position(x: cx + 28, y: cy - 18 + heartRise * 0.6)
                        .transition(.scale.combined(with: .opacity))
                }
                if showZzz {
                    Text("Zzz")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0x7B / 255.0, green: 0x6B / 255.0, blue: 0x9E / 255.0))
                        .position(x: cx + 40, y: cy - 36)
                        .transition(.opacity)
                }
                ForEach(crumbDots) { p in
                    Circle()
                        .fill(Color(red: 0.85, green: 0.55, blue: 0.30).opacity(p.opacity))
                        .frame(width: p.size, height: p.size)
                        .position(x: cx + p.x, y: cy + 18 + p.y)
                }
                ForEach(bubbleParticles) { p in
                    Circle()
                        .strokeBorder(Color.cyan.opacity(p.opacity), lineWidth: 1.5)
                        .background(Circle().fill(Color.cyan.opacity(0.15)))
                        .frame(width: p.size, height: p.size)
                        .position(x: cx + p.x, y: cy + p.y)
                }
                ForEach(playParticles) { p in
                    Image(systemName: p.size > 8 ? "heart.fill" : "star.fill")
                        .font(.system(size: p.size, weight: .bold))
                        .foregroundStyle(p.size > 8
                            ? Color(red: 1.0, green: 0.30, blue: 0.43).opacity(p.opacity)
                            : Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0).opacity(p.opacity))
                        .position(x: cx + p.x, y: cy + p.y + heartRise * 0.35)
                }
            }
        }
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
        HStack(spacing: 14) {
            dockButton("fork.knife", "Feed") { showFood = true }
            dockButton("tennisball", "Play") { showGames = true }
            dockButton("hand.point.up", "Pet") { performPetTap() }
            dockButton("drop", "Bath") { performClean() }
            dockButton("moon", "Sleep") { performSleep() }
            dockButton("gearshape", "More") { showSettings = true }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.28), in: Capsule())
        .padding(.bottom, 12)
    }

    private func dockButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            PetSound.shared.play(.uiTick)
            action()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(label)
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(width: 48, height: 40)
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
        droppedSymbol = item.symbolName
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

    private func startFollowWand() {
        guard !careBusy else { return }
        careBusy = true
        brain.hold(3.2)
        wandX = 0.50
        wandY = 0.36
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
        schedulePoseClear(holdMs: 1000)
        syncActivity()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
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

    private func showComingSoon(_ text: String) {
        withAnimation { comingSoonText = text }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation { comingSoonText = nil }
        }
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
        playParticles = (0..<6).map { i in
            CareParticle(
                id: UUID(),
                x: CGFloat([-22, -8, 6, 18, -14, 12][i]),
                y: CGFloat([4, -6, 8, -2, 12, -10][i]),
                size: CGFloat([12, 7, 14, 6, 10, 8][i]),
                opacity: 0.95
            )
        }
        withAnimation(.easeOut(duration: 0.7)) {
            playParticles = playParticles.map {
                CareParticle(id: $0.id, x: $0.x * 1.35, y: $0.y - 36, size: $0.size, opacity: 0.05)
            }
        }
        Task {
            try? await Task.sleep(nanoseconds: 750_000_000)
            await MainActor.run { playParticles = [] }
        }
    }

    private func pulseHeart(crumbs: Bool) {
        heartRise = 0
        PetSound.shared.play(.heartPop)
        withAnimation(.easeOut(duration: 0.15)) {
            showFloatingHeart = true
            showFloatingStar = store.lastUsedFavorite
        }
        withAnimation(.easeOut(duration: 0.6)) {
            heartRise = -48
        }
        if crumbs { spawnCrumbs() }
        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    showFloatingHeart = false
                    showFloatingStar = false
                    crumbDots = []
                }
            }
        }
    }

    private func pulseBubbles() {
        spawnBubbles()
        withAnimation(.easeOut(duration: 0.15)) { showBubbles = true }
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    showBubbles = false
                    bubbleParticles = []
                }
            }
        }
    }

    private func pulseZzz() {
        withAnimation(.easeOut(duration: 0.2)) {
            showZzz = true
            roomDim = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.35)) {
                    showZzz = false
                    roomDim = false
                }
            }
        }
    }

    private func spawnCrumbs() {
        crumbDots = (0..<4).map { i in
            CareParticle(
                id: UUID(),
                x: CGFloat([-18, -6, 8, 16][i]),
                y: CGFloat([6, 12, 4, 10][i]),
                size: CGFloat([5, 4, 6, 3][i]),
                opacity: 0.85
            )
        }
        withAnimation(.easeOut(duration: 0.55)) {
            crumbDots = crumbDots.map {
                CareParticle(id: $0.id, x: $0.x * 1.2, y: $0.y + 16, size: $0.size, opacity: 0.15)
            }
        }
    }

    private func spawnBubbles() {
        bubbleParticles = (0..<7).map { i in
            let angle = Double(i) * (.pi * 2 / 7.0)
            return CareParticle(
                id: UUID(),
                x: CGFloat(cos(angle) * 10),
                y: CGFloat(sin(angle) * 6),
                size: CGFloat([10, 14, 8, 12, 9, 11, 13][i]),
                opacity: 0.9
            )
        }
        withAnimation(.easeOut(duration: 0.65)) {
            bubbleParticles = bubbleParticles.enumerated().map { i, p in
                let angle = Double(i) * (.pi * 2 / 7.0)
                return CareParticle(
                    id: p.id,
                    x: CGFloat(cos(angle) * 36),
                    y: CGFloat(sin(angle) * 28) - 24,
                    size: p.size * 1.15,
                    opacity: 0.1
                )
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
        case .snowPorch, .coralShelf:
            return AnyView(LinearGradient(
                colors: [Color(red: 0.98, green: 0.94, blue: 0.88), Color(red: 0.90, green: 0.95, blue: 0.92)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
        }
    }
}

private struct CareParticle: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
}

#Preview {
    ContentView()
        .environmentObject(PetStore())
        .environmentObject(PetLiveActivityManager())
}
