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

    var body: some View {
        let snap = entry.snapshot
        let sleeping = snap.isSleeping == true || snap.mood == .sleepy
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.92
            TimelineView(.animation(minimumInterval: 1.0 / 6.0, paused: false)) { context in
                let tick = Int(context.date.timeIntervalSinceReferenceDate * 6)
                ClipPetView(
                    speciesId: snap.petGlyph == "pip" ? "pip" : "nubby",
                    anim: sleeping ? .sleeping : .idle,
                    frame: tick,
                    facingLeft: false,
                    displaySize: side
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
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
        .configurationDisplayName("Pet Feeling")
        .description("See how they’re doing")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
