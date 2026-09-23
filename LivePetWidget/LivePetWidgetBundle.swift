import SwiftUI
import WidgetKit

@main
struct LivePetWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetHomeWidget()
        PetClockWidget()
        PetWeatherWidget()
        PetCalendarWidget()
        PetDailyMessageWidget()
        PetPhotoWidget()
        PetLiveActivityWidget()
        PetAccessoryWidget()
    }
}
