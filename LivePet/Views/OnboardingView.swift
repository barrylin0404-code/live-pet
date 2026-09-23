import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: PetStore
    @State private var name: String = "Nubby"

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.94, blue: 0.88),
                    Color(red: 0.90, green: 0.95, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                AnimatedPixelPetView(mood: .happy, pose: .idle, isSleeping: false, scale: 1.4)
                    .frame(height: 140)

                Text("Meet your pixel pet")
                    .font(.title2.bold())
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))

                TextField("Nubby", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .accessibilityLabel("Pet name")
                    .onChange(of: name) { _, newValue in
                        if newValue.count > 16 {
                            name = String(newValue.prefix(16))
                        }
                    }

                Button {
                    store.completeOnboarding(name: name)
                } label: {
                    Text(ctaTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.98, green: 0.52, blue: 0.42))
                .padding(.horizontal, 40)

                Text("You can rename later in Settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
        }
    }

    private var ctaTitle: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = trimmed.isEmpty ? "Nubby" : trimmed
        return "Meet \(display)"
    }
}
