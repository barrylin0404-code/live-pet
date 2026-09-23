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
                guard phase == .active else { return }
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
