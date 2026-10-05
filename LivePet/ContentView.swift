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
    /// Retires an in-flight bath/sleep unlock so Wake / pet switch / a finished hold cannot clear a later care.
    @State private var careGeneration = 0
    /// Generation of the active bath/sleep hold — consumeBathReady / sleepSettle end this one only.
    @State private var careHoldGeneration = 0

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
    /// Toy play applies once on consume / fail-safe (same idea as pendingFoodId) — never bump Feeling at drop and again at end.
    @State private var pendingToyId: String?
    /// Retires Soft Square / Bounce / Ball Tasks so a pet-switch mid-lure cannot clear a later careBusy or bump Feeling twice.
    @State private var toySessionGeneration = 0
    /// Last stroke beat that counted as petting (sound + Feeling). Drag repeats in between
    /// only keep the held clip alive so a long stroke is not a meow machine-gun.
    @State private var lastStrokeBeat: Date = .distantPast

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
                                    startPlayBall()
                                case "soft_square":
                                    startFollowWand(showSoftSquare: true)
                                case "bounce_block":
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
                            wakeFromNapIfNeeded()
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
                PetsSheet(store: store) {
                    resetBrainForPetSwitch()
                    syncActivity()
                }
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
                }, onSoftSquare: {
                    showShop = false
                    startFollowWand(showSoftSquare: true)
                }, onBounceBlock: {
                    showShop = false
                    if let bounce = store.toys.first(where: { $0.id == "bounce_block" })
                        ?? InventoryItem.catalog.first(where: { $0.id == "bounce_block" }) {
                        dropToyAndPlay(bounce)
                    }
                }, onHitIsland: {
                    showShop = false
                    wakeFromNapIfNeeded()
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
                        startPlayBall()
                    case "soft_square":
                        startFollowWand(showSoftSquare: true)
                    case "bounce_block":
                        dropToyAndPlay(item)
                    default:
                        dropToyAndPlay(item)
                    }
                }, onClean: {
                    showInventory = false
                    performClean()
                })
            }
            .sheet(isPresented: $store.showGrowCelebration, onDismiss: {
                // Done, Back to room, or a swipe: one happy beat in the room + Grow cue.
                PetSound.shared.play(.meow)
                // Mid-bath Grow used to force happy and cut bath short — bathReady never fired and
                // Feed stayed locked until the 7s fail-safe. Release the hold, then react.
                releaseBathOrSleepHoldForOverlay()
                if !store.pet.isSleeping {
                    brain.reactGrown()
                }
                // Swipe used to skip Meet Pip (binding-only dismiss). Offer Pip after every close.
                store.offerMeetPipIfNeeded()
            }) {
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
            .onChange(of: store.pet.petGlyph) { _ in
                // Pip must not inherit Nubby mid-clip / room position.
                resetBrainForPetSwitch()
                syncActivity()
            }
            .onDisappear {
                store.stopTicking()
                poseClearTask?.cancel()
                walkTask?.cancel()
            }
            #if canImport(UIKit)
            .background(ShakeDetector().frame(width: 0, height: 0))
            .onReceive(NotificationCenter.default.publisher(for: .livePetDidShake)) { _ in
                // Shake only tucks in when awake — never wakes a nap (Sleep dock toggles wake).
                guard !store.pet.isSleeping else { return }
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
                    displaySize: 40,
                    growthStage: store.pet.growthStage
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
                brain.tick(dt: dt, sleeping: store.pet.isSleeping, mood: store.pet.mood, roamPace: store.selectedScene.roamPace, roamIdleHold: store.selectedScene.roamIdleHold, restX: store.selectedScene.restXFraction)
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
                    careBusy = false
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
                    applyPendingToyPlay(session: toySessionGeneration)
                    pulseHeart(crumbs: false)
                    spawnPlayBurst()
                    careBusy = false
                    syncActivity()
                }
                if brain.consumeBathReady() {
                    endCareHold(careHoldGeneration)
                }
                if brain.consumeSleepSettleReady() {
                    endCareHold(careHoldGeneration)
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
            // Island Sleep already toggles Wake — dock a11y matches.
            dockButton("ctrl-sleep", store.pet.isSleeping ? "Wake" : "Sleep") { performSleep() }
            dockButton("ctrl-more", "More") { showScenes = true }
        }
        .padding(.bottom, 10)
    }

    private func dockButton(_ image: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button {
            PetSound.shared.play(.uiTick)
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
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

    // MARK: - Drop-to-room food

    private func dropFoodAndEat(_ item: InventoryItem) {
        guard !careBusy else { return }
        wakeFromNapIfNeeded()
        careBusy = true
        pendingFoodId = item.id
        droppedX = brain.player.facingLeft ? 0.32 : 0.68
        brain.noticeFood(at: droppedX)
        droppedSymbol = item.pixelSpriteName ?? (store.pet.petGlyph == "pip" ? "prop-berry" : "prop-fish")
        PetSound.shared.play(.feed)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        let foodId = item.id
        let failSafe = careFailSafeNanos(to: droppedX, beat: 0.65)
        Task { @MainActor in
            // Brain walks to the food and calls feed when the eat clip finishes (careBusy clears there).
            // Fail-safe is sized to this walk at this room's pace, so calm rooms are not cut short.
            try? await Task.sleep(nanoseconds: failSafe)
            // Mirror toy fail-safe: if the meal already finished (or pet switched), do not feed again.
            guard careBusy, pendingFoodId == foodId else { return }
            pendingFoodId = nil
            brain.abandonFood()
            store.feed(itemID: foodId)
            droppedSymbol = nil
            careBusy = false
            syncActivity()
        }
    }

    /// Drop a pixel toy in the room; pet walks over and plays (same path as food).
    private func dropToyAndPlay(_ item: InventoryItem) {
        guard !careBusy else { return }
        wakeFromNapIfNeeded()
        careBusy = true
        let session = beginToySession()
        pendingToyId = item.id
        let dropX: CGFloat = brain.x < 0.5 ? 0.68 : 0.32
        // Soft Square must land as prop-soft (never wand / bounce fallback).
        if item.id == "soft_square" {
            droppedSymbol = "prop-soft"
        } else {
            droppedSymbol = item.pixelSpriteName ?? "prop-bounce"
        }
        droppedX = dropX
        brain.noticeToy(at: dropX)
        PetSound.shared.play(.play)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        let toyId = item.id
        let toySprite = droppedSymbol
        let failSafe = careFailSafeNanos(to: dropX, beat: 1.15)
        Task { @MainActor in
            // consumePlayReady clears the toy and careBusy as soon as the play beat ends.
            // Fail-safe is sized to this walk + the 1.15s play beat if that never fires.
            try? await Task.sleep(nanoseconds: failSafe)
            guard toySessionGeneration == session else { return }
            guard careBusy, pendingToyId == toyId, droppedSymbol == toySprite else { return }
            brain.abandonToy()
            droppedSymbol = nil
            applyPendingToyPlay(session: session)
            careBusy = false
            syncActivity()
        }
    }

    // MARK: - Play Ball (spawn → run → hit ≥1.5s + heart)

    private func startPlayBall() {
        guard !careBusy else { return }
        wakeFromNapIfNeeded()
        careBusy = true
        // Pending only after the busy gate — ribbon re-taps mid-chase must not steal Feeling.
        let session = beginToySession()
        pendingToyId = "twinkle_ball"
        let dropX: CGFloat = brain.x < 0.5 ? 0.70 : 0.30
        ballX = dropX
        ballY = 0.22
        ballVisible = true
        brain.noticeToy(at: dropX)
        PetSound.shared.play(.play)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        let floorY = CGFloat(store.selectedScene.ballFloorYFraction)
        let failSafe = careFailSafeNanos(to: dropX, beat: 1.15)
        Task { @MainActor in
            withAnimation(.easeIn(duration: 0.28)) { ballY = floorY }
            try? await Task.sleep(nanoseconds: 280_000_000)
            PetSound.shared.play(.ballBounce)
            // Fail-safe if playReady never fires; consumePlayReady usually clears earlier.
            // Sized to this chase at this room's pace + the 1.15s play beat.
            try? await Task.sleep(nanoseconds: failSafe > 280_000_000 ? failSafe - 280_000_000 : 0)
            guard toySessionGeneration == session else { return }
            guard ballVisible else { return }
            brain.abandonToy()
            ballVisible = false
            applyPendingToyPlay(session: session)
            careBusy = false
            syncActivity()
        }
    }

    private func bounceBallHit() {
        // Hits stay live during the chase hold — careBusy alone must not soft-lock the ball.
        guard ballVisible else { return }
        bouncePetPlay()
        pulseHeart(crumbs: false)
        spawnPlayBurst()
        PetSound.shared.play(.ballBoing)
        // Feeling once when the chase ends (applyPendingToyPlay) — not on every bounce.
        schedulePoseClear(holdMs: 900)
        syncActivity()
    }

    // MARK: - Follow the wand (drift + track ≥1.5s + heart)

    private func startFollowWand(showSoftSquare: Bool = false) {
        guard !careBusy else { return }
        wakeFromNapIfNeeded()
        careBusy = true
        // Soft Square only — wand lure leaves pending nil and ends on playWand once.
        // Assign after the busy gate so ribbon re-taps mid-play cannot rewrite Feeling.
        let session = beginToySession()
        if showSoftSquare {
            pendingToyId = "soft_square"
            droppedSymbol = nil
        }
        brain.hold(2.55)
        wandX = 0.50
        wandY = 0.36
        // Soft Square lure = prop-soft; Follow the wand = prop-wand.
        wandSpriteName = showSoftSquare ? "prop-soft" : "prop-wand"
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
                guard toySessionGeneration == session else { return }
                let dx = wandX - brain.x
                let next = min(0.88, max(0.12, brain.x + dx * 0.22))
                // Denser lure chase with existing clips: run when far, play when close, walk mid.
                brain.trackLure(at: next, facingLeft: wandX < brain.x, distance: abs(dx))
                // Soft hop while tracking
                if Int(elapsed * 10) % 4 == 0 {
                    bouncePet()
                }
                try? await Task.sleep(nanoseconds: tick)
                elapsed += Double(tick) / 1_000_000_000
            }
            guard toySessionGeneration == session else { return }
            wandInteractive = false
            if showSoftSquare {
                applyPendingToyPlay(session: session)
            } else {
                store.playWand()
            }
            // Caught the lure: happy sheet in the room, not the walk clip cycling in place.
            brain.reactPlayResult(happy: true)
            bouncePetPlay()
            pulseHeart(crumbs: false)
            spawnPlayBurst()
            schedulePoseClear(holdMs: 1100)
            syncActivity()
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard toySessionGeneration == session else { return }
            withAnimation { wandVisible = false }
            wandSpriteName = "prop-wand"
            careBusy = false
        }
    }

    // MARK: - Hit the Island finish

    private func finishHitIsland(catches: Int?) {
        showHitIsland = false
        // Mid-bath Grow/Hit used to force a room beat, cut the bath chain, and leave Feed locked
        // until the fail-safe — release the hold (and abort bath) before any room reaction.
        releaseBathOrSleepHoldForOverlay()
        // Backed out of the intro: no run, no Feeling, keep the last blurb.
        guard let catches else { return }
        // Catch count drives Feeling + Island blurb — not a generic toy play.
        store.playHitIsland(catches: catches)
        bouncePet()
        if catches > 0 {
            pulseHeart(crumbs: false)
        }
        schedulePoseClear(holdMs: 1400)
        syncActivity()
        // Room pet answers the result card once the cover has slid away — happy after catches,
        // sad after none (sheets, no floaters). Too early and the beat plays behind the cover.
        let won = catches > 0
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !showHitIsland, !store.pet.isSleeping else { return }
            // Bath already aborted above; gate still blocks meal/toy so Feeling once stays clean.
            brain.reactPlayResult(happy: won)
        }
    }

    // MARK: - Care (Clean / Sleep / tap)

    /// Care while napping: wake first so feed/play/bath/pet are not soft-locked.
    private func wakeFromNapIfNeeded() {
        guard store.pet.isSleeping else { return }
        // Drop any sleep-settle careBusy so the care that woke them is not gated by the old hold.
        cancelCareHold()
        brain.reactSleep(on: false)
        store.wake()
        syncActivity()
    }

    private func performClean() {
        guard !careBusy else { return }
        wakeFromNapIfNeeded()
        let gen = beginCareHold()
        brain.reactBath()
        store.clean()
        PetSound.shared.play(.clean)
        pulseBubbles()
        // Hold through bathStart→bathing→wet→shake→bathHappy (+ idle linger).
        schedulePoseClear(holdMs: 4800)
        syncActivity()
        // Unlock on consumeBathReady (bathHappy → idle). Fail-safe only if that never fires.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 7_000_000_000)
            endCareHold(gen)
        }
    }

    private func performSleep() {
        if store.pet.isSleeping {
            // Cancel the sleep-settle hold so Feed/toy right after Wake are not ignored.
            cancelCareHold()
            brain.reactSleep(on: false)
            store.wake()
            PetSound.shared.play(.meow)
            syncActivity()
            return
        }
        guard !careBusy else { return }
        let gen = beginCareHold()
        brain.reactSleep(on: true)
        store.sleep()
        PetSound.shared.play(.sleep)
        pulseZzz()
        syncActivity()
        // Unlock on consumeSleepSettleReady (sleepStart → sleeping). Fail-safe if settle never signals.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            endCareHold(gen)
        }
    }

    private func performPetTap() {
        wakeFromNapIfNeeded()
        // Mid-meal / toy / bath: a soft purr only. No clip, Feeling, pose, or blurb change, so
        // the bath sheet and "Got a soapy bath" are not cut short by a pat.
        guard brain.reactPet() else {
            softCareTap()
            return
        }
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

    /// Drag/stroke petting. Every drag repeat keeps the held clip alive; one beat per
    /// ~0.9s counts as petting (bob, sound, Feeling) so a long stroke reads as one cuddle.
    private func performPetStroke() {
        wakeFromNapIfNeeded()
        // Drag repeats fire fast — stay quiet while busy (no purr machine-gun).
        guard brain.reactGrab() else { return }
        let now = Date()
        guard now.timeIntervalSince(lastStrokeBeat) >= 0.9 else {
            schedulePoseClear(holdMs: 1200)
            return
        }
        lastStrokeBeat = now
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
        wakeFromNapIfNeeded()
        // Mid-jump double-taps let the jump land instead of restarting it.
        guard brain.reactDoubleTap() else { return }
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

    /// Pat while the pet is busy with care: acknowledge the touch, change nothing.
    private func softCareTap() {
        PetSound.shared.play(.pet)
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        #endif
    }

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

    /// Start a bath/sleep care hold. Returns the generation that alone may unlock it.
    @discardableResult
    private func beginCareHold() -> Int {
        careGeneration += 1
        careHoldGeneration = careGeneration
        careBusy = true
        return careGeneration
    }

    /// Unlock only if this hold is still current, then retire the generation so a late fail-safe is a no-op.
    private func endCareHold(_ generation: Int) {
        guard careGeneration == generation else { return }
        careBusy = false
        careGeneration += 1
    }

    /// Wake / pet switch: drop busy and retire any in-flight bath/sleep unlock.
    private func cancelCareHold() {
        careGeneration += 1
        careBusy = false
    }

    /// True while a bath/sleep beginCareHold is current (food/toy set careBusy without bumping gen).
    private var isBathOrSleepHoldActive: Bool {
        careBusy && careHoldGeneration == careGeneration && careGeneration > 0
    }

    /// Grow dismiss / Hit Island finish: retire a live bath/sleep hold and abort the bath chain so
    /// Feed unlocks now — not after a fail-safe waiting on a bathReady that will never fire.
    private func releaseBathOrSleepHoldForOverlay() {
        if isBathOrSleepHoldActive {
            cancelCareHold()
        }
        brain.abortBathIfNeeded()
    }

    /// Fail-safe for a food / toy walk: notice glance + the walk at this room's pace (same
    /// 0.16 speed and pace clamp as PetBrain) + the eat or play beat + a second of slack.
    /// Never shorter than the old flat 5.2s.
    private func careFailSafeNanos(to target: CGFloat, beat: Double) -> UInt64 {
        let pace = min(1.45, max(0.7, store.selectedScene.roamPace))
        let walk = Double(abs(target - brain.x)) / (0.16 * pace)
        let seconds = max(5.2, 0.35 + walk + beat + 1.0)
        return UInt64(seconds * 1_000_000_000)
    }

    /// One Feeling bump per toy session. No pending id = already applied (fail-safe beat the
    /// brain's playReady) — never fall back to another toy and bump twice.
    private func applyPendingToyPlay(session: Int) {
        guard toySessionGeneration == session else { return }
        guard let id = pendingToyId else { return }
        pendingToyId = nil
        store.play(itemID: id)
    }

    @discardableResult
    private func beginToySession() -> Int {
        toySessionGeneration += 1
        return toySessionGeneration
    }

    private func retireToySession() {
        toySessionGeneration += 1
        pendingToyId = nil
    }

    /// Fresh brain so a switch (Pets sheet or Meet Pip) does not keep the prior pet's clip / x.
    private func resetBrainForPetSwitch() {
        brain = PetBrain()
        petX = brain.x
        facingLeft = brain.player.facingLeft
        pendingFoodId = nil
        droppedSymbol = nil
        // Retire Soft Square / Bounce / Ball Tasks so they cannot clear careBusy or bump Feeling on the new pet.
        retireToySession()
        // Retire bath/sleep unlock so a prior timer cannot clear careBusy mid-walk on the new pet.
        cancelCareHold()
        ballVisible = false
        wandVisible = false
        wandInteractive = false
        playBounce = 0
    }

    private func syncActivity() {
        guard activityManager.isActivityActive else { return }
        activityManager.renewIfNeeded(pet: store.pet)
        activityManager.update(pet: store.pet)
    }

    /// Plate is the room — no under-room LinearGradients (App Lead).
    private var roomBackground: some View {
        if let plate = store.selectedScene.plateImageName {
            return AnyView(
                Image(plate)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
            )
        }
        return AnyView(Color(red: 0.98, green: 0.94, blue: 0.88))
    }
}


#Preview {
    ContentView()
        .environmentObject(PetStore())
        .environmentObject(PetLiveActivityManager())
}
