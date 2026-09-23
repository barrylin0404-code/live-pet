import SwiftUI
import WidgetKit

@main
struct LivePetWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetHomeWidget()
        PetLiveActivityWidget()
    }
}
