import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PetStore
    @EnvironmentObject private var activityManager: PetLiveActivityManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    roomCard
                    meters
                    quickActions
                    InventoryPanel(store: store) {
                        syncActivity()
                    }
                    liveActivityControls
                    if let error = activityManager.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.94, blue: 0.88),
                        Color(red: 0.92, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Live Pet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(store.pet.lastAction)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .onAppear {
                store.onPetChange = { pet in
                    if activityManager.isActivityActive {
                        activityManager.update(pet: pet)
                    }
                }
                store.startTicking()
                syncActivity()
            }
            .onDisappear {
                store.stopTicking()
            }
        }
    }

    private var roomCard: some View {
        VStack(spacing: 10) {
            SunNookScene(mood: store.pet.mood, petScale: 1.15)
                .frame(maxWidth: .infinity)
                .frame(height: 220)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.pet.name)
                        .font(.title2.bold())
                    Label(store.pet.mood.label, systemImage: store.pet.mood.symbolName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Sun Nook")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.55), in: Capsule())
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var meters: some View {
        VStack(spacing: 12) {
            StatBar(title: "Feeling", value: store.pet.moodScore, tint: .pink, systemImage: "heart.fill")
            StatBar(title: "Satiety", value: store.pet.satiety, tint: .orange, systemImage: "fork.knife")
            StatBar(title: "Energy", value: store.pet.energy, tint: .green, systemImage: "bolt.fill")
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            ActionButton(title: "Feed", systemImage: "fork.knife", tint: .orange) {
                store.feedDefault()
                syncActivity()
            }
            ActionButton(title: "Play", systemImage: "gamecontroller", tint: .indigo) {
                store.playDefault()
                syncActivity()
            }
            ActionButton(title: "Sleep", systemImage: "moon.zzz", tint: .purple) {
                store.sleep()
                syncActivity()
            }
        }
    }

    private var liveActivityControls: some View {
        VStack(spacing: 10) {
            if activityManager.isActivityActive {
                Button(role: .destructive) {
                    activityManager.end()
                } label: {
                    Label("End Live Activity", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    activityManager.start(pet: store.pet)
                } label: {
                    Label("Start in Dynamic Island", systemImage: "platter.filled.top.and.arrow.up.iphone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!activityManager.areActivitiesEnabled)
            }

            Text(
                activityManager.areActivitiesEnabled
                    ? "Live Activities are enabled. Feed, play, and sleep update the Island."
                    : "Enable Live Activities in Settings → Live Pet."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func syncActivity() {
        guard activityManager.isActivityActive else { return }
        activityManager.update(pet: store.pet)
    }
}

private struct StatBar: View {
    let title: String
    let value: Int
    let tint: Color
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Text("\(value)%")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            ProgressView(value: Double(value), total: 100)
                .tint(tint)
        }
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
