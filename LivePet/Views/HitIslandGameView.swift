import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Short full-screen catch mini-game (~10–20s). Original Live Pet branding only.
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
                sliderBar
                footerHint
            }

            if showIntro {
                introOverlay
            }
            if finished {
                resultOverlay
            }
        }
        .onDisappear { loopTask?.cancel() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hit the Island")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(ink)
                Text("Live Pet · catch for \(petName)")
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

                // Score chips
                HStack {
                    Label("\(catches)", systemImage: "star.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(red: 0xE8 / 255.0, green: 0xC5 / 255.0, blue: 0x47 / 255.0))
                    Spacer()
                    Text("Feeling+")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ink.opacity(0.45))
                }
                .padding(.horizontal, 28)
                .padding(.top, 18)
                .frame(maxHeight: .infinity, alignment: .top)

                ForEach(orbs) { orb in
                    Image(systemName: "circle.fill")
                        .font(.system(size: orb.size))
                        .foregroundStyle(orb.color)
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                        .position(
                            x: geo.size.width * orb.x,
                            y: geo.size.height * orb.y
                        )
                }

                // Catcher pet
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
                        .frame(width: 64, height: 10)
                        .shadow(color: coral.opacity(0.4), radius: 3, y: 1)
                }
                .position(
                    x: geo.size.width * paddleX,
                    y: geo.size.height * 0.86
                )
            }
        }
    }

    private var sliderBar: some View {
        VStack(spacing: 6) {
            Text("Slide to catch")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ink.opacity(0.6))
            Slider(value: $paddleX, in: 0.12...0.88)
                .tint(coral)
                .padding(.horizontal, 24)
                .disabled(!running || finished)
        }
        .padding(.vertical, 10)
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
                Text("Slide \(petName) under falling stars.\nCatch as many as you can — 15 seconds!")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ink.opacity(0.75))
                Button {
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
                Text(catches > 0 ? "Nice catch!" : "Good try!")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(ink)
                Text("\(catches) catch\(catches == 1 ? "" : "es") · Feeling up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ink.opacity(0.7))
                Button {
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
            speed: CGFloat.random(in: 0.28...0.42),
            size: CGFloat.random(in: 16...24),
            color: [
                Color(red: 1.0, green: 0.85, blue: 0.35),
                Color(red: 0x7E / 255.0, green: 0xC8 / 255.0, blue: 0xE3 / 255.0),
                Color(red: 1.0, green: 0.30, blue: 0.43),
                Color(red: 0.55, green: 0.85, blue: 0.45)
            ].randomElement()!
        )
        orbs.append(orb)
    }

    private func advanceOrbs(dt: Double) {
        var next: [FallingOrb] = []
        let catchY: CGFloat = 0.82
        let catchRadius: CGFloat = 0.11
        for var orb in orbs {
            orb.y += orb.speed * CGFloat(dt)
            if orb.y >= catchY && abs(orb.x - paddleX) <= catchRadius {
                catches += 1
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                continue
            }
            if orb.y > 1.05 {
                misses += 1
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
    var speed: CGFloat
    var size: CGFloat
    var color: Color
}
