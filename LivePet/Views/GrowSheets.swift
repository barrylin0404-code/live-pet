import SwiftUI

/// Soft cream celebration after Grow — title “All grown!” — never Evolve.
struct GrowCelebrationSheet: View {
    let pet: Pet
    var onDone: () -> Void
    @State private var scale: CGFloat = 1.0

    private let cream = Color(red: 1.0, green: 0.98, blue: 0.94)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("All grown!")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ink)
                Spacer(minLength: 0)
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Spacer(minLength: 8)
            TimelineView(.animation(minimumInterval: 1.0 / 8.0)) { context in
                let frame = Int(context.date.timeIntervalSinceReferenceDate * 8)
                ClipPetView(
                    speciesId: pet.petGlyph,
                    anim: .happy,
                    frame: frame,
                    facingLeft: false,
                    displaySize: 140,
                    growthStage: pet.growthStage
                )
                .scaleEffect(scale)
            }
            .frame(height: 190)
            Text(pet.speciesDisplayName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            Spacer(minLength: 8)
            Button(action: onDone) {
                Text("Back to room")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.98, green: 0.52, blue: 0.42), in: Capsule())
            }
            .buttonStyle(PressScaleButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(cream.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                scale = 1.15
            }
        }
    }
}

/// Skippable Meet Pip sheet after first Grow — cream card, no system nav chrome.
struct MeetPipSheet: View {
    var onMeet: () -> Void
    var onSkip: () -> Void

    private let cream = Color(red: 1.0, green: 0.98, blue: 0.94)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    private let border = Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0)
    private let pipBlue = Color(red: 0x7E / 255.0, green: 0xC8 / 255.0, blue: 0xE3 / 255.0)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer(minLength: 12)
                TimelineView(.animation(minimumInterval: 1.0 / 8.0)) { context in
                    let frame = Int(context.date.timeIntervalSinceReferenceDate * 8)
                    ClipPetView(
                        speciesId: "pip",
                        anim: .idle,
                        frame: frame,
                        facingLeft: false,
                        displaySize: 120
                    )
                }
                .frame(height: 130)

                VStack(spacing: 10) {
                    Text("Meet Pip")
                        .font(.title2.bold())
                        .foregroundStyle(ink)
                    Text("Pip is the mint duck. Switch pets from the rooms list.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(border, lineWidth: 2)
                )
                .padding(.horizontal, 20)

                Button(action: onMeet) {
                    Text("Meet Pip")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(pipBlue, in: Capsule())
                }
                .buttonStyle(PressScaleButtonStyle())
                .padding(.horizontal, 20)

                Button("Skip for now", action: onSkip)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ink.opacity(0.55))

                Spacer(minLength: 8)
            }
            .padding(.bottom, 20)
        }
    }
}
