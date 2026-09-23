import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var activityManager: PetLiveActivityManager
    @State private var pet = Pet()
    @State private var tickTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                petCard
                stats
                actions
                liveActivityControls
                if let error = activityManager.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Live Pet")
            .onAppear { startTicking() }
            .onDisappear { tickTask?.cancel() }
        }
    }

    private var petCard: some View {
        VStack(spacing: 12) {
            Text(pet.speciesEmoji)
                .font(.system(size: 72))
            Text(pet.name)
                .font(.largeTitle.bold())
            Text("\(pet.mood.emoji) \(pet.mood.label)")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(pet.lastAction)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var stats: some View {
        VStack(spacing: 12) {
            StatBar(title: "Hunger", value: pet.hunger, tint: .orange)
            StatBar(title: "Energy", value: pet.energy, tint: .green)
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            ActionButton(title: "Feed", systemImage: "fork.knife") {
                pet.feed()
                syncActivity()
            }
            ActionButton(title: "Play", systemImage: "gamecontroller") {
                pet.play()
                syncActivity()
            }
            ActionButton(title: "Rest", systemImage: "moon.zzz") {
                pet.rest()
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
                    activityManager.start(pet: pet)
                } label: {
                    Label("Start in Dynamic Island", systemImage: "platter.filled.top.and.arrow.up.iphone")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!activityManager.areActivitiesEnabled)
            }

            Text(
                activityManager.areActivitiesEnabled
                    ? "Live Activities are enabled on this device."
                    : "Enable Live Activities in Settings → Live Pet."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }

    private func syncActivity() {
        guard activityManager.isActivityActive else { return }
        activityManager.update(pet: pet)
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { return }
                pet.tick()
                syncActivity()
            }
        }
    }
}

private struct StatBar: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
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
        .environmentObject(PetLiveActivityManager())
}
