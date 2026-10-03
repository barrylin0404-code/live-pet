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
                TimelineView(.animation(minimumInterval: 1.0 / 8.0)) { context in
                    let frame = Int(context.date.timeIntervalSinceReferenceDate * 8)
                    ClipPetView(
                        speciesId: pet.petGlyph,
                        anim: .happy,
                        frame: frame,
                        facingLeft: false,
                        displaySize: 140
                    )
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
                Text("Pip is the mint duck. Switch pets from the rooms list.")
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
