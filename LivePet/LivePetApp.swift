import SwiftUI

@main
struct LivePetApp: App {
    @StateObject private var store = PetStore()
    @StateObject private var activityManager = PetLiveActivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(activityManager)
                .onAppear {
                    activityManager.restoreIfNeeded()
                    if activityManager.isActivityActive {
                        activityManager.update(pet: store.pet)
                    }
                }
        }
    }
}
