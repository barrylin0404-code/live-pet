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
    var onFinished: (_ catches: Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private let gameDuration: Double = 15
    private let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let coral = Color(red: 0xFA / 255.0, green: 0x85 / 255.0, blue: 0x6B / 255.0)
    private let mint = Color(red: 0xC8 / 255.0, green: 0xDC / 255.0, blue: 0xC4 / 255.0)

    @State private var paddleX: CGFloat = 0.5
    @State private var orbs: [FallingOrb] = []
    @State private var catches = 0
    @State private var misses = 0
    @State private var elapsed: Double = 0
    @State private var running = false
    @State private var finished = false
    @State private var loopTask: Task<Void, Never>?
    @State private var showIntro = true
    @State private var paddleFlash = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.78, blue: 0.95),
                    Color(red: 0.90, green: 0.95, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                playfield
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                footerHint
            }

            if showIntro { introOverlay }
            if finished { resultOverlay }
        }
        .onDisappear { loopTask?.cancel() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hit the Island")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(ink)
                Text("Live Pet · bounce for \(petName)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ink.opacity(0.55))
            }
            Spacer()
            Text("\(max(0, Int(ceil(gameDuration - elapsed))))s")
                .font(.title3.weight(.heavy).monospacedDigit())
                .foregroundStyle(coral)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(cream, in: Capsule())
            Button {
                endGame(early: true)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var playfield: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(mint.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .padding(.horizontal, 12)

                HStack {
                    Label("\(catches)", systemImage: "star.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0))
                    Spacer()
                    Text("Drag to bounce")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ink.opacity(0.45))
                }
                .padding(.horizontal, 28)
                .padding(.top, 18)
                .frame(maxHeight: .infinity, alignment: .top)

                ForEach(orbs) { orb in
                    Image(systemName: "basketball.fill")
                        .font(.system(size: orb.size))
                        .foregroundStyle(orb.color)
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                        .position(
                            x: geo.size.width * orb.x,
                            y: geo.size.height * orb.y
                        )
                }

                VStack(spacing: 2) {
                    AnimatedPixelPetView(
                        mood: mood,
                        pose: .play,
                        isSleeping: false,
                        speciesId: speciesId,
                        growthStage: growthStage,
                        scale: 0.85
                    )
                    Capsule()
                        .fill(coral)
                        .frame(width: paddleFlash ? 76 : 68, height: paddleFlash ? 14 : 11)
                        .shadow(color: coral.opacity(0.45), radius: 3, y: 1)
                        .scaleEffect(paddleFlash ? 1.08 : 1.0)
                }
                .position(
                    x: geo.size.width * paddleX,
                    y: geo.size.height * 0.86
                )
                .animation(.spring(response: 0.22, dampingFraction: 0.5), value: paddleFlash)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard running, !finished else { return }
                        paddleX = min(0.88, max(0.12, value.location.x / max(geo.size.width, 1)))
                    }
            )
            .accessibilityHint("Drag left and right to bounce balls")
        }
        .padding(.bottom, 8)
    }

    private var footerHint: some View {
        Text("Original Live Pet sports toy · no ads · no paywall")
            .font(.caption2.weight(.medium))
            .foregroundStyle(ink.opacity(0.4))
            .padding(.bottom, 10)
    }

    private var introOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Hit the Island")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(ink)
                Text("Drag \(petName) under falling balls.\nBounce them skyward — 15 seconds!")
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
                .padding(.horizontal, 8)
            }
            .padding(24)
            .background(cream, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 32)
        }
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color(red: 1.0, green: 0.30, blue: 0.43))
                Text(catches > 0 ? "Nice bounce!" : "Good try!")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(ink)
                Text("\(catches) catch\(catches == 1 ? "" : "es") · Feeling up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ink.opacity(0.7))
                Button {
                    PetSound.shared.play(.heartPop)
                    #if canImport(UIKit)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                    onFinished(catches)
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(ink, in: Capsule())
                }
                .buttonStyle(PressScaleButtonStyle())
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
            .padding(24)
            .background(cream, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding(.horizontal, 32)
        }
    }

    private func startLoop() {
        running = true
        finished = false
        catches = 0
        misses = 0
        elapsed = 0
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
        let catchRadius: CGFloat = 0.13
        let g: CGFloat = 0.55
        for var orb in orbs {
            orb.vy += g * CGFloat(dt)
            orb.y += orb.vy * CGFloat(dt)
            orb.x += orb.vx * CGFloat(dt)
            if orb.x < 0.1 { orb.x = 0.1; orb.vx = abs(orb.vx) }
            if orb.x > 0.9 { orb.x = 0.9; orb.vx = -abs(orb.vx) }

            if orb.vy > 0, orb.y >= paddleY, orb.y <= paddleY + 0.09, abs(orb.x - paddleX) <= catchRadius {
                orb.vy = -abs(orb.vy) * 0.92 - 0.10
                orb.vx += (orb.x - paddleX) * 0.85
                orb.bounces += 1
                paddleFlash = true
                PetSound.shared.play(.ballHit)
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                #endif
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    paddleFlash = false
                }
                if orb.bounces >= 2 {
                    catches += 1
                    PetSound.shared.play(.heartPop)
                    continue
                }
            }
            if orb.y > 1.08 {
                misses += 1
                continue
            }
            if orb.y < -0.12, orb.bounces > 0 {
                catches += 1
                continue
            }
            next.append(orb)
        }
        orbs = next
    }

    private func endGame(early: Bool) {
        guard !finished else { return }
        running = false
        loopTask?.cancel()
        if early && catches == 0 && elapsed < 1 {
            onFinished(0)
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
