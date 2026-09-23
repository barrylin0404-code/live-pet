import ActivityKit
import Foundation

/// Starts, updates, and ends the pet Live Activity from the main app.
/// Renew recipe (Researcher / Reviewer gate): one Activity; staleDate ~8h;
/// at ≥7h end then immediately request with the same App Group snapshot.
@MainActor
final class PetLiveActivityManager: ObservableObject {
    @Published private(set) var isActivityActive = false
    @Published private(set) var lastError: String?

    private var currentActivity: Activity<PetActivityAttributes>?
    private var renewTask: Task<Void, Never>?

    /// Renew before the hard ~8h ActivityKit cap (restart at 7h).
    private static let renewAfter: TimeInterval = 7 * 60 * 60
    /// staleDate ≈ 8h from start (renewAfter + 1h).
    private static let staleLeeway: TimeInterval = 60 * 60
    private static let startedKey = "livepet.v1.activityStartedAt"

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(pet: Pet) {
        lastError = nil
        guard areActivitiesEnabled else {
            lastError = "Live Activities are disabled in Settings."
            return
        }
        renewTask?.cancel()
        renewTask = nil
        Task { await endThenRequest(pet: pet) }
    }

    func update(pet: Pet) {
        lastError = nil
        if needsRenew {
            start(pet: pet)
            return
        }
        guard let activity = currentActivity else { return }

        let stale = renewDeadline ?? Date().addingTimeInterval(Self.staleLeeway)
        let content = ActivityContent(state: pet.activityState, staleDate: stale)
        Task {
            await activity.update(content)
        }
    }

    func renewIfNeeded(pet: Pet) {
        guard isActivityActive || currentActivity != nil else { return }
        if needsRenew {
            start(pet: pet)
        }
    }

    /// Alias for Iphone App Build / App Lead call sites (≥7h renew).
    func ensureFresh(pet: Pet) {
        renewIfNeeded(pet: pet)
    }

    func end(dismissalPolicy: ActivityUIDismissalPolicy = .default, cancelRenew: Bool = true) {
        lastError = nil
        if cancelRenew {
            renewTask?.cancel()
            renewTask = nil
        }
        guard let activity = currentActivity else {
            isActivityActive = false
            return
        }

        let finalContent = ActivityContent(
            state: activity.content.state,
            staleDate: nil
        )
        Task {
            await activity.end(finalContent, dismissalPolicy: dismissalPolicy)
        }
        currentActivity = nil
        isActivityActive = false
        AppGroup.defaults.removeObject(forKey: Self.startedKey)
    }

    func restoreIfNeeded() {
        if let existing = Activity<PetActivityAttributes>.activities.first {
            currentActivity = existing
            isActivityActive = true
            if AppGroup.defaults.object(forKey: Self.startedKey) == nil {
                AppGroup.defaults.set(Date(), forKey: Self.startedKey)
            }
        } else {
            isActivityActive = false
        }
    }

    private var needsRenew: Bool {
        guard let started = AppGroup.defaults.object(forKey: Self.startedKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(started) >= Self.renewAfter
    }

    private var renewDeadline: Date? {
        guard let started = AppGroup.defaults.object(forKey: Self.startedKey) as? Date else {
            return nil
        }
        return started.addingTimeInterval(Self.renewAfter + Self.staleLeeway)
    }

    /// Gate: await end, then request — avoids racing a still-active Activity.
    private func endThenRequest(pet: Pet) async {
        let finalState = currentActivity?.content.state ?? pet.activityState
        if let activity = currentActivity {
            let finalContent = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(finalContent, dismissalPolicy: .immediate)
            currentActivity = nil
        }
        // Clear orphans so we keep exactly one Activity.
        for orphan in Activity<PetActivityAttributes>.activities {
            let finalContent = ActivityContent(state: orphan.content.state, staleDate: nil)
            await orphan.end(finalContent, dismissalPolicy: .immediate)
        }

        let attributes = PetActivityAttributes(
            petName: pet.name,
            petGlyph: pet.petGlyph
        )
        let stale = Date().addingTimeInterval(Self.renewAfter + Self.staleLeeway)
        let content = ActivityContent(state: pet.activityState, staleDate: stale)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            isActivityActive = true
            AppGroup.defaults.set(Date(), forKey: Self.startedKey)
            scheduleRenew(pet: pet)
        } catch {
            lastError = error.localizedDescription
            isActivityActive = false
        }
    }

    private func scheduleRenew(pet: Pet) {
        renewTask?.cancel()
        guard let started = AppGroup.defaults.object(forKey: Self.startedKey) as? Date else { return }
        let remaining = Self.renewAfter - Date().timeIntervalSince(started)
        let delay = max(60, remaining)
        let fallback = pet
        renewTask = Task { [weak self] in
            let ns = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                let latest: Pet
                if let data = AppGroup.defaults.data(forKey: AppGroup.petKey),
                   let decoded = try? JSONDecoder().decode(Pet.self, from: data) {
                    latest = decoded
                } else {
                    latest = fallback
                }
                self?.start(pet: latest)
            }
        }
    }
}
