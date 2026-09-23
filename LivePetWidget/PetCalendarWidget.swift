import SwiftUI
import WidgetKit

struct PetCalendarEntry: TimelineEntry {
    let date: Date
    let snapshot: PetSnapshot
    let ageDays: Int
}

struct PetCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetCalendarEntry {
        PetCalendarEntry(date: .now, snapshot: .placeholder, ageDays: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetCalendarEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetCalendarEntry>) -> Void) {
        let entry = makeEntry()
        // Midnight-ish refresh for "today" + care reloads.
        let cal = Calendar.current
        let tomorrow = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: .now) ?? .now)
        let fallback = cal.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(21600)
        let next = min(tomorrow, fallback)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> PetCalendarEntry {
        PetCalendarEntry(
            date: .now,
            snapshot: PetSnapshot.load() ?? .placeholder,
            ageDays: WidgetChrome.ageDaysFromAppGroup()
        )
    }
}

struct PetCalendarWidgetView: View {
    var entry: PetCalendarEntry
    @Environment(\.widgetFamily) private var family

    private var careTip: String {
        if entry.snapshot.satiety < 34 {
            return "Feed if Satiety low"
        }
        if entry.snapshot.moodScore < 34 {
            return "A little care goes far"
        }
        return "Today · care when free"
    }

    var body: some View {
        let snap = entry.snapshot
        Group {
            switch family {
            case .systemMedium:
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(entry.date, format: .dateTime.month(.abbreviated))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WidgetChrome.secondaryInk)
                            Text(entry.date, format: .dateTime.day())
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(WidgetChrome.ink)
                            Text(entry.date, format: .dateTime.weekday(.wide))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(WidgetChrome.ink)
                                .lineLimit(1)
                        }
                        Text(careTip)
                            .font(.caption)
                            .foregroundStyle(WidgetChrome.secondaryInk)
                        HStack(spacing: 8) {
                            Text("Feeling")
                                .font(.caption2)
                                .foregroundStyle(WidgetChrome.secondaryInk)
                            FeelingMiniHearts(moodScore: snap.moodScore, size: 9)
                            Text("·  Day \(entry.ageDays)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(WidgetChrome.secondaryInk)
                        }
                        SatietyMiniBar(satiety: snap.satiety)
                    }
                    Spacer(minLength: 0)
                    WidgetPetForeground(snapshot: snap, size: 52)
                }
                .padding(14)
            default:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.date, format: .dateTime.day())
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetChrome.ink)
                    Text(entry.date, format: .dateTime.weekday(.abbreviated))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WidgetChrome.secondaryInk)
                    Spacer(minLength: 0)
                    HStack {
                        FeelingMiniHearts(moodScore: snap.moodScore, size: 8)
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

struct PetCalendarWidget: Widget {
    let kind = "PetCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetCalendarProvider()) { entry in
            PetCalendarWidgetView(entry: entry)
                .livePetWidgetBackground()
        }
        .configurationDisplayName("Pet Day")
        .description("Today + care nudge")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
