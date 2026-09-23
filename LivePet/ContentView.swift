import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PetStore
    @EnvironmentObject private var activityManager: PetLiveActivityManager

    @State private var showFloatingHeart = false
    @State private var showFloatingSparkles = false
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

                if showFloatingSparkles {
                    Image(systemName: "sparkles")
                        .font(.system(size: 68, weight: .bold))
                        .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.95))
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .background(
                roomBackground
                    .ignoresSafeArea()
            )
            .navigationTitle(store.selectedScene.displayName)
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
            #if canImport(UIKit)
            .background(ShakeDetector().frame(width: 0, height: 0))
            .onReceive(NotificationCenter.default.publisher(for: .livePetDidShake)) { _ in
                store.sleep()
                syncActivity()
            }
            #endif
        }
    }

    private var roomBackground: some View {
        switch store.selectedScene {
        case .sunNook:
            return AnyView(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.94, blue: 0.88),
                        Color(red: 0.90, green: 0.95, blue: 0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .moonPorch:
            return AnyView(
                LinearGradient(
                    colors: [
                        Color(red: 0x2C / 255.0, green: 0x3A / 255.0, blue: 0x4A / 255.0),
                        Color(red: 0.18, green: 0.22, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    private var roomCard: some View {
        VStack(spacing: 8) {
            PetRoomSceneView(
                scene: store.selectedScene,
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
                Text(store.selectedScene.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(sceneChipFill, in: Capsule())
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(
            sceneCardFill.opacity(0.55),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(sceneCardBorder, lineWidth: 2)
        )
    }

    private var sceneChipFill: Color {
        switch store.selectedScene {
        case .sunNook:
            return Color(red: 0.91, green: 0.96, blue: 0.89).opacity(0.9)
        case .moonPorch:
            return Color(red: 0xF4 / 255.0, green: 0xD5 / 255.0, blue: 0xA0 / 255.0).opacity(0.85)
        }
    }

    private var sceneCardFill: Color {
        switch store.selectedScene {
        case .sunNook:
            return Color(red: 0.91, green: 0.96, blue: 0.89)
        case .moonPorch:
            return Color(red: 0.28, green: 0.34, blue: 0.44)
        }
    }

    private var sceneCardBorder: Color {
        switch store.selectedScene {
        case .sunNook:
            return Color(red: 0.77, green: 0.85, blue: 0.75)
        case .moonPorch:
            return Color(red: 0xF4 / 255.0, green: 0xD5 / 255.0, blue: 0xA0 / 255.0).opacity(0.55)
        }
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
            ActionButton(title: "Clean", systemImage: "drop.fill", tint: .cyan) {
                store.clean()
                pulseSparkles()
                syncActivity()
            }
            ActionButton(title: "Sleep", systemImage: "moon.zzz", tint: .purple, accessibilityLabel: "Tuck in") {
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

    private func pulseSparkles() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            showFloatingSparkles = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    showFloatingSparkles = false
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
    var accessibilityLabel: String? = nil
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
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}

#Preview {
    ContentView()
        .environmentObject(PetStore())
        .environmentObject(PetLiveActivityManager())
}
