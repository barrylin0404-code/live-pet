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
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snap = entry.snapshot
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.94, blue: 0.88),
                    Color(red: 0.90, green: 0.95, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            switch family {
            case .systemMedium:
                HStack(spacing: 14) {
                    petBlock(snap, size: 72)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(snap.name)
                            .font(.headline.bold())
                        Label(snap.mood.label, systemImage: snap.mood.symbolName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        meter(label: "Feeling", value: snap.moodScore, tint: .pink)
                        meter(label: "Satiety", value: snap.satiety, tint: .orange)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
            default:
                VStack(spacing: 6) {
                    petBlock(snap, size: family == .systemSmall ? 56 : 48)
                    Text(snap.name)
                        .font(.caption.bold())
                        .lineLimit(1)
                    Text(snap.mood.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.pink)
                        Text("\(snap.moodScore)")
                        Image(systemName: "fork.knife")
                            .foregroundStyle(.orange)
                        Text("\(snap.satiety)")
                    }
                    .font(.caption2.monospacedDigit())
                }
                .padding(10)
            }
        }
    }

    private func petBlock(_ snap: PetSnapshot, size: CGFloat) -> some View {
        AnimatedPixelPetView(
            mood: snap.mood,
            pose: .idle,
            isSleeping: snap.mood == .sleepy,
            speciesId: snap.petGlyph,
            growthStage: snap.resolvedGrowthStage,
            scale: size / 64
        )
        .frame(width: size, height: size)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
    }

    private func meter(label: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            ProgressView(value: Double(value), total: 100)
                .tint(tint)
        }
    }
}

struct PetHomeWidget: Widget {
    let kind = "PetHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetHomeProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                PetHomeWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                PetHomeWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Live Pet")
        .description("See Nubby’s Feeling and Satiety on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
