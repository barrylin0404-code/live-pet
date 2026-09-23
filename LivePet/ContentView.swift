import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PetStore
    @EnvironmentObject private var activityManager: PetLiveActivityManager

    @State private var showFloatingHeart = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        roomCard
                        StatusStripView(pet: store.pet)
                        quickActions
                        InventoryPanel(store: store) {
                            syncActivity()
                        }
                        if let error = activityManager.lastError {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Text(store.pet.lastAction)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }

                if showFloatingHeart {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.30, blue: 0.43))
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.94, blue: 0.88),
                        Color(red: 0.90, green: 0.95, blue: 0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Sun Nook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
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
            }
            .onDisappear {
                store.stopTicking()
            }
        }
    }

    private var roomCard: some View {
        VStack(spacing: 8) {
            SunNookScene(
                mood: store.pet.mood,
                pose: store.pet.pose,
                isSleeping: store.pet.isSleeping,
                petScale: 1.15
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            HStack {
                Label(store.pet.mood.label, systemImage: store.pet.mood.symbolName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Sun Nook")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Color(red: 0.91, green: 0.96, blue: 0.89).opacity(0.9),
                        in: Capsule()
                    )
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(
            Color(red: 0.91, green: 0.96, blue: 0.89).opacity(0.55),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color(red: 0.77, green: 0.85, blue: 0.75), lineWidth: 2)
        )
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            ActionButton(title: "Feed", systemImage: "fork.knife", tint: .orange) {
                store.feedDefault()
                pulseHeart()
                syncActivity()
            }
            ActionButton(title: "Play", systemImage: "gamecontroller", tint: .indigo) {
                store.playDefault()
                pulseHeart()
                syncActivity()
            }
            ActionButton(title: "Sleep", systemImage: "moon.zzz", tint: .purple) {
                store.sleep()
                syncActivity()
            }
        }
    }

    private func pulseHeart() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            showFloatingHeart = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    showFloatingHeart = false
                }
            }
        }
    }

    private func syncActivity() {
        guard activityManager.isActivityActive else { return }
        activityManager.renewIfNeeded(pet: store.pet)
        activityManager.update(pet: store.pet)
    }
}

private struct ActionButton: View {
    let title: String
    let systemImage: String
    var tint: Color = .accentColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    ContentView()
        .environmentObject(PetStore())
        .environmentObject(PetLiveActivityManager())
}
