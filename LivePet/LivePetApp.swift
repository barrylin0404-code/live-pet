import SwiftUI

@main
struct LivePetApp: App {
    @StateObject private var activityManager = PetLiveActivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(activityManager)
                .onAppear {
                    activityManager.restoreIfNeeded()
                }
        }
    }
}
