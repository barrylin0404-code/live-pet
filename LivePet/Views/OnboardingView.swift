import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: PetStore
    @State private var name: String = "Nubby"

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("sun-nook-plate")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: geo.size.width, height: geo.size.height)
                TimelineView(.animation(minimumInterval: 1.0 / 6.0)) { context in
                    let frame = Int(context.date.timeIntervalSinceReferenceDate * 6)
                    ClipPetView(
                        speciesId: "nubby",
                        anim: .idle,
                        frame: frame,
                        facingLeft: false,
                        displaySize: 140
                    )
                }
                .position(x: geo.size.width * 0.52, y: geo.size.height * 0.62)
            }
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("Meet your pixel pet")
                    .font(.title2.bold())
                    .foregroundStyle(Color(red: 0.29, green: 0.25, blue: 0.21))

                TextField("Nubby", text: $name)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(red: 0xE8 / 255.0, green: 0xD4 / 255.0, blue: 0xC4 / 255.0), lineWidth: 2)
                    )
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
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.98, green: 0.52, blue: 0.42), in: Capsule())
                }
                .buttonStyle(PressScaleButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 28)
            }
        }
    }

    private var ctaTitle: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = trimmed.isEmpty ? "Nubby" : trimmed
        return "Meet \(display)"
    }
}
