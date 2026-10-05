import SwiftUI
import WidgetKit

struct PetClockEntry: TimelineEntry {
    let date: Date
    let snapshot: PetSnapshot
}

struct PetClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetClockEntry {
        PetClockEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetClockEntry) -> Void) {
        completion(PetClockEntry(date: .now, snapshot: PetSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetClockEntry>) -> Void) {
        // Clock face uses SwiftUI date styles — no per-minute spam. Mood still projects so a
        // long absence can flip hungry/sad/happy on the pet chip without opening the app.
        let now = Date()
        let entries = PetSnapshot.projectedTimeline(from: now, stepMinutes: 20, throughMinutes: 120).map {
            PetClockEntry(date: $0.date, snapshot: $0.snapshot)
        }
        let next = now.addingTimeInterval(2 * 60 * 60)
        completion(Timeline(entries: entries, policy: .after(next)))
    }
}

struct PetClockWidgetView: View {
    var entry: PetClockEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snap = entry.snapshot
        Group {
            switch family {
            case .systemMedium:
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.date, style: .time)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(WidgetChrome.ink)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                            .font(.caption)
                            .foregroundStyle(WidgetChrome.secondaryInk)
                    }
                    Spacer(minLength: 0)
                    WidgetPetForeground(snapshot: snap, size: 56)
                }
                .padding(14)
            default:
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date, style: .time)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetChrome.ink)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom) {
                        Text(entry.date, format: .dateTime.weekday(.abbreviated).day())
                            .font(.caption2)
                            .foregroundStyle(WidgetChrome.secondaryInk)
                        Spacer(minLength: 0)
                        WidgetPetForeground(snapshot: snap, size: 40)
                    }
                }
                .padding(12)
            }
        }
        .widgetURL(WidgetChrome.homeURL)
    }
}

struct PetClockWidget: Widget {
    let kind = "PetClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetClockProvider()) { entry in
            PetClockWidgetView(entry: entry)
                .livePetWidgetBackground()
        }
        .configurationDisplayName("Pet Clock")
        .description("Time with your pet")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
