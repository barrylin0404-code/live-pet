import SwiftUI
import WidgetKit

struct PetWeatherEntry: TimelineEntry {
    let date: Date
    let snapshot: PetSnapshot
    let weather: WeatherCache
}

struct PetWeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetWeatherEntry {
        PetWeatherEntry(date: .now, snapshot: .placeholder, weather: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetWeatherEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetWeatherEntry>) -> Void) {
        let entry = makeEntry()
        // ~30–60 min cadence + reload on care.
        let next = Calendar.current.date(byAdding: .minute, value: 45, to: .now)
            ?? .now.addingTimeInterval(2700)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> PetWeatherEntry {
        PetWeatherEntry(
            date: .now,
            snapshot: PetSnapshot.load() ?? .placeholder,
            weather: WeatherCache.load() ?? .empty
        )
    }
}

struct PetWeatherWidgetView: View {
    var entry: PetWeatherEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snap = entry.snapshot
        let w = entry.weather
        let tip = WeatherCozyTip.line(
            moodBand: snap.moodRaw,
            conditionLabel: w.hasObservation ? w.conditionLabel : "Outside",
            petName: snap.name
        )

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: w.conditionSymbol)
                    .font(.title2)
                    .foregroundStyle(WidgetChrome.ink)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if let temp = w.displayTemperature {
                            Text(temp)
                                .font(.title2.bold())
                                .foregroundStyle(WidgetChrome.ink)
                        }
                        if w.hasObservation {
                            Text(w.conditionLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(WidgetChrome.secondaryInk)
                                .lineLimit(1)
                        }
                    }
                    Text(tip)
                        .font(.caption)
                        .foregroundStyle(WidgetChrome.ink)
                        .lineLimit(family == .systemSmall ? 2 : 2)
                }

                Spacer(minLength: 0)
                if family != .systemSmall {
                    WidgetPetForeground(snapshot: snap, size: 48)
                }
            }

            HStack(spacing: 6) {
                FeelingMiniHearts(moodScore: snap.moodScore, size: 9)
                Text(WidgetChrome.feelingPhrase(mood: snap.mood))
                    .font(.caption2)
                    .foregroundStyle(WidgetChrome.secondaryInk)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if family == .systemSmall {
                    WidgetPetForeground(snapshot: snap, size: 36)
                }
            }

            // Apple Weather attribution (~12pt footer)
            Text("Weather data provided by Apple Weather")
                .font(.system(size: 9))
                .foregroundStyle(WidgetChrome.secondaryInk.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .widgetURL(WidgetChrome.homeURL)
    }
}

struct PetWeatherWidget: Widget {
    let kind = "PetWeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetWeatherProvider()) { entry in
            PetWeatherWidgetView(entry: entry)
                .livePetWidgetBackground()
        }
        .configurationDisplayName("Pet Weather")
        .description("Forecast + a cozy tip")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
