import SwiftUI

/// Soft cream celebration after Grow — title “All grown!” — never Evolve.
struct GrowCelebrationSheet: View {
    let pet: Pet
    var onDone: () -> Void

    private let cream = Color(red: 1.0, green: 0.98, blue: 0.94)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    // Match Meet Pip / Scenes — ink stroke card, not bare cream (no beige leftover).
    private let border = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)

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
            // Happy sheet alone — no forever scale pulse (leftover chrome vs Meet Pip / cream sheets).
            VStack(spacing: 10) {
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
                }
                .frame(height: 160)
                Text(pet.speciesDisplayName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(border, lineWidth: 2)
            )
            .padding(.horizontal, 20)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}

/// Skippable Meet Pip sheet after first Grow — cream card, no system nav chrome.
struct MeetPipSheet: View {
    var onMeet: () -> Void
    var onSkip: () -> Void

    private let cream = Color(red: 1.0, green: 0.98, blue: 0.94)
    private let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    // Match Scenes / Food / Onboarding — ink stroke, not beige leftover.
    private let border = Color(red: 0x4A / 255.0, green: 0x3F / 255.0, blue: 0x35 / 255.0)
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
                        anim: .happy,
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
                .background(Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(border, lineWidth: 2)
                )
                .padding(.horizontal, 20)

                Button(action: {
                    PetSound.shared.play(.meow)
                    onMeet()
                }) {
                    Text("Meet Pip")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(pipBlue, in: Capsule())
                }
                .buttonStyle(PressScaleButtonStyle())
                .padding(.horizontal, 20)

                Button("Skip for now") {
                    PetSound.shared.play(.uiTick)
                    onSkip()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ink.opacity(0.55))

                Spacer(minLength: 8)
            }
            .padding(.bottom, 20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
}
