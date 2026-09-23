import SwiftUI
import WidgetKit

struct PetDailyMessageEntry: TimelineEntry {
    let date: Date
    let snapshot: PetSnapshot
    let message: String
}

struct PetDailyMessageProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetDailyMessageEntry {
        let snap = PetSnapshot.placeholder
        return PetDailyMessageEntry(
            date: .now,
            snapshot: snap,
            message: DailyMessages.message(petName: snap.name)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PetDailyMessageEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetDailyMessageEntry>) -> Void) {
        let entry = makeEntry()
        let cal = Calendar.current
        let tomorrow = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: .now) ?? .now)
        completion(Timeline(entries: [entry], policy: .after(tomorrow)))
    }

    private func makeEntry() -> PetDailyMessageEntry {
        let snap = PetSnapshot.load() ?? .placeholder
        return PetDailyMessageEntry(
            date: .now,
            snapshot: snap,
            message: DailyMessages.message(petName: snap.name)
        )
    }
}

struct PetDailyMessageWidgetView: View {
    var entry: PetDailyMessageEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snap = entry.snapshot
        Group {
            switch family {
            case .systemMedium:
                HStack(alignment: .center, spacing: 12) {
                    WidgetPetForeground(snapshot: snap, size: 52)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("“\(entry.message)”")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(WidgetChrome.ink)
                            .lineLimit(3)
                        Text("— \(snap.name)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WidgetChrome.secondaryInk)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
            default:
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        WidgetPetForeground(snapshot: snap, size: 40)
                        Spacer(minLength: 0)
                    }
                    Text(entry.message)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WidgetChrome.ink)
                        .lineLimit(3)
                    Text("— \(snap.name)")
                        .font(.caption2)
                        .foregroundStyle(WidgetChrome.secondaryInk)
                }
                .padding(12)
            }
        }
        .widgetURL(WidgetChrome.homeURL)
    }
}

struct PetDailyMessageWidget: Widget {
    let kind = "PetDailyMessageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetDailyMessageProvider()) { entry in
            PetDailyMessageWidgetView(entry: entry)
                .livePetWidgetBackground()
        }
        .configurationDisplayName("Pet Note")
        .description("A daily hello")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
