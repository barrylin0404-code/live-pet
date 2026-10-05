import SwiftUI
import WidgetKit

struct PetHomeEntry: TimelineEntry {
    let date: Date
    let snapshot: PetSnapshot
}

struct PetHomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetHomeEntry {
        PetHomeEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetHomeEntry) -> Void) {
        let snap = PetSnapshot.load() ?? .placeholder
        completion(PetHomeEntry(date: .now, snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetHomeEntry>) -> Void) {
        let snap = PetSnapshot.load() ?? .placeholder
        let entry = PetHomeEntry(date: .now, snapshot: snap)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct PetHomeWidgetView: View {
    var entry: PetHomeEntry

    /// Honey floor starts at row 27 of the 40-row plate.
    private static let floorFraction: CGFloat = 27.0 / 40.0
    /// Idle feet sit on this row of the 64-pixel sheet.
    private static let footFraction: CGFloat = 55.0 / 64.0
    /// Small enough that the upper-left window stays clear of the body.
    private static let petFraction: CGFloat = 0.44

    var body: some View {
        let snap = entry.snapshot
        let sleeping = snap.isSleeping == true || snap.mood == .sleepy
        GeometryReader { geo in
            let plateSide = min(geo.size.width, geo.size.height)
            let plateTop = (geo.size.height - plateSide) / 2
            let petSide = plateSide * Self.petFraction
            let petTop = plateTop + plateSide * Self.floorFraction - petSide * Self.footFraction
            ZStack {
                Image("home-widget-plate")
                    .interpolation(.none)
                    .resizable()
                    .frame(width: plateSide, height: plateSide)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                TimelineView(.animation(minimumInterval: 1.0 / 6.0, paused: false)) { context in
                    let tick = Int(context.date.timeIntervalSinceReferenceDate * 6)
                    ClipPetView(
                        speciesId: snap.petGlyph == "pip" ? "pip" : "nubby",
                        anim: sleeping ? .sleeping : .idle,
                        frame: tick,
                        facingLeft: false,
                        displaySize: petSide,
                        growthStage: snap.resolvedGrowthStage
                    )
                }
                .position(x: geo.size.width / 2, y: petTop + petSide / 2)
            }
        }
        .accessibilityLabel(snap.petGlyph == "pip" ? "Pip" : "Nubby")
    }
}

struct PetHomeWidget: Widget {
    let kind = "PetHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetHomeProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                PetHomeWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                PetHomeWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Live Pet")
        .description("Your pet at home")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
