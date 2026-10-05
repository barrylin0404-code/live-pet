import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Short full-screen basketball-style bounce mini-game (~15s). Drag paddle; orbs bounce.
struct HitIslandGameView: View {
    var petName: String
    var speciesId: String
    var growthStage: GrowthStage
    var mood: PetMood
    /// `nil` = backed out of the intro before playing — no Feeling, no blurb.
    var onFinished: (_ catches: Int?) -> Void
    @Environment(\.dismiss) private var dismiss

    private let gameDuration: Double = 15
    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let stroke = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
    private let coral = Color(red: 0xFA / 255.0, green: 0x85 / 255.0, blue: 0x6B / 255.0)

    @State private var paddleX: CGFloat = 0.5
    @State private var orbs: [FallingOrb] = []
    @State private var catches = 0
    @State private var misses = 0
    @State private var elapsed: Double = 0
    @State private var running = false
    @State private var finished = false
    @State private var loopTask: Task<Void, Never>?
    @State private var showIntro = true
    /// 1 = still; >1 catch pop; <1 miss squash. Spring back via bumpPaddle.
    @State private var paddleBump: CGFloat = 1.0
    /// Short reaction sheet on the paddle pet — happy on a catch, sad on a miss (no floaters).
    @State private var reaction: PetAnim = .playing
    @State private var reactionUntil: Double = 0
    /// Paddle pet runs the way you drag (run sheets) and faces that way when it stops.
    @State private var paddleFacingLeft = false
    @State private var paddleMovedAt: Double = -1

    var body: some View {
        ZStack {
            playfield
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)

            if showIntro { introOverlay }
            if finished { resultOverlay }
        }
        .onDisappear { loopTask?.cancel() }
    }

    private var header: some View {
        HStack {
            Text("Hit the Island")
                .font(.headline.weight(.bold))
                .foregroundStyle(ink)
            Spacer()
            Text("\(max(0, Int(ceil(gameDuration - elapsed))))s")
                .font(.title3.weight(.heavy).monospacedDigit())
                .foregroundStyle(coral)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(cream, in: Capsule())
                .overlay(Capsule().strokeBorder(stroke, lineWidth: 1.5))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var playfield: some View {
        GeometryReader { geo in
            ZStack {
                Image("hit-island-plate")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: geo.size.width, height: geo.size.height)

                HStack {
                    HStack(spacing: 4) {
                        Image("prop-star")
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                        Text("\(catches)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(ink)
                    }
                    Spacer()
                    Text("Drag to bounce")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ink.opacity(0.45))
                }
                .padding(.horizontal, 28)
                .padding(.top, 64)
                .frame(maxHeight: .infinity, alignment: .top)

                ForEach(orbs) { orb in
                    // Spawn picks size 18…26 — draw ~2× so islands vary around the old 48px.
                    let side = orb.size * 2
                    Image("prop-island")
                        .resizable()
                        .interpolation(.none)
                        .frame(width: side, height: side)
                        .position(
                            x: geo.size.width * orb.x,
                            y: geo.size.height * orb.y
                        )
                }

                VStack(spacing: 2) {
                    ClipPetView(
                        speciesId: speciesId,
                        anim: paddleAnim,
                        frame: Int(elapsed * (paddleRunning ? 12 : 6)),
                        facingLeft: paddleFacingLeft,
                        displaySize: 96,
                        growthStage: growthStage
                    )
                    // Kit / plus size comes from ClipPetView, same as in the room.
                    .scaleEffect(paddleBump)
                }
                .position(
                    x: geo.size.width * paddleX,
                    y: geo.size.height * 0.86
                )
                .animation(.spring(response: 0.22, dampingFraction: 0.5), value: paddleBump)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard running, !finished else { return }
                        let next = min(0.88, max(0.12, value.location.x / max(geo.size.width, 1)))
                        let dx = next - paddleX
                        // Ignore finger jitter; a real move turns and runs the pet.
                        if abs(dx) > 0.004 {
                            paddleFacingLeft = dx < 0
                            paddleMovedAt = elapsed
                            // Catch/miss beat was holding the run clip — cut it so drag run resumes.
                            if elapsed < reactionUntil {
                                reactionUntil = elapsed
                            }
                        }
                        paddleX = next
                    }
            )
            .accessibilityHint("Drag left and right to bounce the islands")
        }
        .ignoresSafeArea()
    }


    private var introOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Hit the Island")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ink)
                    Spacer(minLength: 0)
                    Button {
                        PetSound.shared.play(.uiTick)
                        // Backing out before Play is not a run — no "Missed every island".
                        onFinished(nil)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ink)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                VStack(spacing: 14) {
                    Text("Drag \(petName) under the falling islands.\nBounce them skyward — 15 seconds!")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(ink.opacity(0.75))
                    Button {
                        PetSound.shared.play(.islandStart)
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        withAnimation { showIntro = false }
                        startLoop()
                    } label: {
                        Text("Play")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(coral, in: Capsule())
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: 340)
            .background(cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            .padding(.horizontal, 32)
        }
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("Hit the Island")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ink)
                    Spacer(minLength: 0)
                    Button {
                        PetSound.shared.play(.heartPop)
                        #if canImport(UIKit)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        #endif
                        onFinished(catches)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ink)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                VStack(spacing: 12) {
                    TimelineView(.animation(minimumInterval: 1.0 / 6.0, paused: false)) { context in
                        ClipPetView(
                            speciesId: speciesId,
                            anim: catches > 0 ? .happy : .sad,
                            frame: Int(context.date.timeIntervalSinceReferenceDate * 6),
                            facingLeft: false,
                            displaySize: 96,
                            growthStage: growthStage
                        )
                    }
                    .frame(width: 96, height: 96)
                    Text(resultHeadline)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(ink)
                    Text(resultBlurb)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(ink.opacity(0.7))
                    Button {
                        PetSound.shared.play(.heartPop)
                        #if canImport(UIKit)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        #endif
                        onFinished(catches)
                        dismiss()
                    } label: {
                        Text("Back to room")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(coral, in: Capsule())
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: 340)
            .background(cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 2.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            .padding(.horizontal, 32)
        }
    }

    /// Moved within the last ~0.2s of game time — the pet is running under the islands.
    private var paddleRunning: Bool {
        running && elapsed >= reactionUntil && elapsed - paddleMovedAt < 0.2
    }

    /// Catch / miss beat first, then run while dragging, then the playing loop when still.
    private var paddleAnim: PetAnim {
        if elapsed < reactionUntil { return reaction }
        if paddleRunning { return paddleFacingLeft ? .runLeft : .runRight }
        return .playing
    }

    private var resultHeadline: String {
        switch catches {
        case 0: return "No catches"
        case 1: return "1 catch"
        default: return "\(catches) catches"
        }
    }

    private var resultBlurb: String {
        switch catches {
        case 0: return "Try dragging under the fall."
        case 1...2: return "Nice bounce — keep going!"
        case 3...5: return "Solid island hopping!"
        default: return "Island ace!"
        }
    }

    private func startLoop() {

        running = true
        finished = false
        catches = 0
        misses = 0
        elapsed = 0
        reaction = .playing
        reactionUntil = 0
        paddleMovedAt = -1
        orbs = []
        loopTask?.cancel()
        loopTask = Task { @MainActor in
            var spawnAcc: Double = 0
            let tick: Double = 1.0 / 30.0
            while !Task.isCancelled && running {
                try? await Task.sleep(nanoseconds: UInt64(tick * 1_000_000_000))
                elapsed += tick
                spawnAcc += tick
                if spawnAcc >= 0.55 {
                    spawnAcc = 0
                    spawnOrb()
                }
                advanceOrbs(dt: tick)
                if elapsed >= gameDuration {
                    endGame(early: false)
                    break
                }
            }
        }
    }

    private func spawnOrb() {
        let orb = FallingOrb(
            id: UUID(),
            x: CGFloat.random(in: 0.18...0.82),
            y: -0.05,
            vy: CGFloat.random(in: 0.32...0.48),
            vx: CGFloat.random(in: -0.06...0.06),
            size: CGFloat.random(in: 18...26),
            bounces: 0,
            color: [
                Color(red: 0.92, green: 0.45, blue: 0.18),
                Color(red: 1.0, green: 0.85, blue: 0.35),
                Color(red: 0x7E / 255.0, green: 0xC8 / 255.0, blue: 0xE3 / 255.0),
                Color(red: 1.0, green: 0.30, blue: 0.43)
            ].randomElement()!
        )
        orbs.append(orb)
    }

    private func advanceOrbs(dt: Double) {
        var next: [FallingOrb] = []
        let paddleY: CGFloat = 0.82
        // Hitbox tracks spawn size (18…26) so the larger drawn islands from d21192f
        // do not float past the paddle while looking like a catch. Mid-size ≈ old 0.13.
        let g: CGFloat = 0.55
        for var orb in orbs {
            orb.vy += g * CGFloat(dt)
            orb.y += orb.vy * CGFloat(dt)
            orb.x += orb.vx * CGFloat(dt)
            if orb.x < 0.1 { orb.x = 0.1; orb.vx = abs(orb.vx) }
            if orb.x > 0.9 { orb.x = 0.9; orb.vx = -abs(orb.vx) }

            let catchRadius = 0.09 + orb.size * 0.0018
            let catchBand = 0.07 + orb.size * 0.0010
            if orb.vy > 0, orb.y >= paddleY, orb.y <= paddleY + catchBand, abs(orb.x - paddleX) <= catchRadius {
                orb.vy = -abs(orb.vy) * 0.92 - 0.10
                orb.vx += (orb.x - paddleX) * 0.85
                orb.bounces += 1
                bumpPaddle(1.06)
                PetSound.shared.play(.ballHit)
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                #endif
                if orb.bounces >= 2 {
                    catches += 1
                    react(.happy)
                    PetSound.shared.play(.heartPop)
                    continue
                }
            }
            if orb.y > 1.08 {
                misses += 1
                react(.sad)
                PetSound.shared.play(.uiTick)
                // Miss feel matches catch density without floaters — squash + soft tick.
                bumpPaddle(0.94)
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                #endif
                continue
            }
            if orb.y < -0.12, orb.bounces > 0 {
                catches += 1
                react(.happy)
                continue
            }
            next.append(orb)
        }
        orbs = next
    }

    /// Brief paddle pop (catch) or squash (miss), then spring back to 1.
    private func bumpPaddle(_ scale: CGFloat) {
        paddleBump = scale
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 120_000_000)
            if abs(paddleBump - scale) < 0.001 {
                paddleBump = 1.0
            }
        }
    }

    /// Happy beats a pending sad (a catch right after a miss should read as a win).
    private func react(_ anim: PetAnim) {
        if anim == .sad, reaction == .happy, elapsed < reactionUntil { return }
        reaction = anim
        reactionUntil = elapsed + (anim == .happy ? 0.6 : 0.45)
    }

    private func endGame(early: Bool) {
        guard !finished else { return }
        running = false
        loopTask?.cancel()
        if early && catches == 0 && elapsed < 1 {
            onFinished(nil)
            dismiss()
            return
        }
        withAnimation { finished = true }
    }
}

private struct FallingOrb: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var vy: CGFloat
    var vx: CGFloat
    var size: CGFloat
    var bounces: Int
    var color: Color
}
