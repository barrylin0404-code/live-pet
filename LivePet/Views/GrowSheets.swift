import SwiftUI

/// Soft cream celebration after Grow — title “All grown!” — never Evolve.
struct GrowCelebrationSheet: View {
    let pet: Pet
    var onDone: () -> Void
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.98, blue: 0.94).ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                ZStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 56))
                        .foregroundStyle(Color(red: 0xE8/255.0, green: 0xC5/255.0, blue: 0x47/255.0))
                        .offset(y: -64)
                    AnimatedPixelPetView(
                        mood: .happy,
                        pose: .idle,
                        isSleeping: false,
                        scale: 1.3 * scale,
                        speciesId: pet.petGlyph,
                        growthStage: pet.growthStage
                    )
                    Image(systemName: "heart.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(red: 1.0, green: 0.30, blue: 0.43))
                        .offset(y: 72)
                        .scaleEffect(scale)
                }
                .frame(height: 190)
                Text("All grown!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))
                Text(pet.speciesDisplayName)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Back to room", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.98, green: 0.52, blue: 0.42))
                    .padding(.bottom, 28)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                scale = 1.15
            }
        }
    }
}

/// Skippable Meet Pip sheet after first Grow.
struct MeetPipSheet: View {
    var onMeet: () -> Void
    var onSkip: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                AnimatedPixelPetView(
                    mood: .happy,
                    pose: .idle,
                    isSleeping: false,
                    scale: 1.25,
                    speciesId: "pip",
                    growthStage: .nubby
                )
                .frame(height: 130)
                Text("Meet Pip")
                    .font(.title2.bold())
                Text("A soft blue bird unlocked after Nubby’s first Grow. Switch the active pet anytime in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Meet Pip", action: onMeet)
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0x7E/255.0, green: 0xC8/255.0, blue: 0xE3/255.0))
                Button("Skip for now", action: onSkip)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Pip")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
