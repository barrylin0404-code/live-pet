import SwiftUI

@main
struct LivePetApp: App {
    @StateObject private var store = PetStore()
    @StateObject private var activityManager = PetLiveActivityManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if store.hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(store)
            .environmentObject(activityManager)
            .onAppear {
                activityManager.restoreIfNeeded()
                if activityManager.isActivityActive {
                    activityManager.renewIfNeeded(pet: store.pet)
                    activityManager.update(pet: store.pet)
                }
                Task {
                    await WeatherFetchService.shared.refresh()
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase == .background {
                    // A suspended tick must not wake later and overwrite Island care.
                    store.stopTicking()
                    return
                }
                guard phase == .active else { return }
                // Island care + background decay first, so the Activity sync sends fresh state.
                store.syncOnBecomeActive()
                if store.hasCompletedOnboarding {
                    store.startTicking()
                }
                // Enumerate → update-only if fresh; end→request only if missing/stale + Island on.
                activityManager.syncOnBecomeActive(pet: store.pet)
                Task {
                    await WeatherFetchService.shared.refresh()
                }
            }
            .onOpenURL { _ in
                // livepet://home (and any livepet://) → Pet Home; ContentView is already root after onboarding.
            }
        }
    }
}
