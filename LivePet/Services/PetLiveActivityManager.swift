import ActivityKit
import Foundation

/// Starts, updates, and ends the pet Live Activity from the main app.
@MainActor
final class PetLiveActivityManager: ObservableObject {
    @Published private(set) var isActivityActive = false
    @Published private(set) var lastError: String?

    private var currentActivity: Activity<PetActivityAttributes>?

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(pet: Pet) {
        lastError = nil
        guard areActivitiesEnabled else {
            lastError = "Live Activities are disabled in Settings."
            return
        }

        // End any existing activity so we only show one pet companion.
        end()

        let attributes = PetActivityAttributes(
            petName: pet.name,
            petGlyph: pet.petGlyph
        )
        let state = pet.activityState
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            isActivityActive = true
        } catch {
            lastError = error.localizedDescription
            isActivityActive = false
        }
    }

    func update(pet: Pet) {
        lastError = nil
        guard let activity = currentActivity else { return }

        let content = ActivityContent(state: pet.activityState, staleDate: nil)
        Task {
            await activity.update(content)
        }
    }

    func end(dismissalPolicy: ActivityUIDismissalPolicy = .default) {
        lastError = nil
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
    }

    /// Re-attach to an already-running activity after app relaunch.
    func restoreIfNeeded() {
        if let existing = Activity<PetActivityAttributes>.activities.first {
            currentActivity = existing
            isActivityActive = true
        } else {
            isActivityActive = false
        }
    }
}
