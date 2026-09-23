import SwiftUI

@main
struct LivePetApp: App {
    @StateObject private var store = PetStore()
    @StateObject private var activityManager = PetLiveActivityManager()

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
            }
        }
    }
}
