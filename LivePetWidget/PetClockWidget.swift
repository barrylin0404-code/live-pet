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
        // Clock face uses SwiftUI date styles — no per-minute timeline spam.
        // Reload pet on care via WidgetCenter; refresh snapshot periodically.
        let entry = PetClockEntry(date: .now, snapshot: PetSnapshot.load() ?? .placeholder)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now)
            ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
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
                        HStack(spacing: 6) {
                            FeelingMiniHearts(moodScore: snap.moodScore)
                            Text(WidgetChrome.feelingPhrase(mood: snap.mood))
                                .font(.caption2)
                                .foregroundStyle(WidgetChrome.secondaryInk)
                                .lineLimit(1)
                        }
                        SatietyMiniBar(satiety: snap.satiety)
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
