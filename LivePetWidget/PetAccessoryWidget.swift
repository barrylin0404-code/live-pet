import SwiftUI
import WidgetKit
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Timeline

struct PetAccessoryEntry: TimelineEntry {
    let date: Date
    let snapshot: PetSnapshot
    let ageDays: Int
}

struct PetAccessoryProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetAccessoryEntry {
        PetAccessoryEntry(date: .now, snapshot: .placeholder, ageDays: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetAccessoryEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetAccessoryEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)
            ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> PetAccessoryEntry {
        let snap = PetSnapshot.load() ?? .placeholder
        return PetAccessoryEntry(date: .now, snapshot: snap, ageDays: Self.ageDaysFromAppGroup())
    }

    /// Reads createdAt from App Group pet JSON without depending on app-target `Pet`.
    private static func ageDaysFromAppGroup() -> Int {
        struct AgeProbe: Codable {
            var createdAt: Date?
            var lastUpdated: Date?
        }
        guard let data = AppGroup.defaults.data(forKey: AppGroup.petKey),
              let probe = try? JSONDecoder().decode(AgeProbe.self, from: data) else {
            return 1
        }
        let created = probe.createdAt ?? probe.lastUpdated ?? .now
        let cal = Calendar.current
        let start = cal.startOfDay(for: created)
        let end = cal.startOfDay(for: .now)
        let days = cal.dateComponents([.day], from: start, to: end).day ?? 0
        return max(1, days + 1)
    }
}

// MARK: - Hearts (1…4 filled dots from Feeling 0…100)

private enum AccessoryHearts {
    static func filledCount(moodScore: Int) -> Int {
        min(4, max(1, (moodScore + 24) / 25))
    }
}

// MARK: - Circular (grayscale silhouette + heart dots)

struct PetAccessoryCircularView: View {
    let entry: PetAccessoryEntry

    var body: some View {
        let filled = AccessoryHearts.filledCount(moodScore: entry.snapshot.moodScore)
        ZStack {
            AccessorySilhouette(compact: true)
                .frame(width: 26, height: 26)
                .offset(y: -4)

            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < filled ? Color.primary : Color.primary.opacity(0.25))
                        .frame(width: 4, height: 4)
                }
            }
            .offset(y: 14)
        }
        .accessibilityLabel("\(entry.snapshot.name), Feeling \(entry.snapshot.moodScore) percent")
    }
}

// MARK: - Rectangular (name + mono hearts + age)

struct PetAccessoryRectangularView: View {
    let entry: PetAccessoryEntry

    var body: some View {
        let filled = AccessoryHearts.filledCount(moodScore: entry.snapshot.moodScore)
        HStack(spacing: 8) {
            AccessorySilhouette()
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.snapshot.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i < filled ? Color.primary : Color.primary.opacity(0.25))
                            .frame(width: 5, height: 5)
                    }
                    Text("\(entry.ageDays)d")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityLabel("\(entry.snapshot.name), Feeling \(entry.snapshot.moodScore) percent, day \(entry.ageDays)")
    }
}

/// Vibrant-grayscale Nubby — Designer mono crops from `12-lock-screen-mono.md`.
private struct AccessorySilhouette: View {
    var compact: Bool = false

    private var assetName: String {
        compact ? "lock-nubby-mono-compact" : "lock-nubby-mono"
    }

    var body: some View {
        #if canImport(UIKit)
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .opacity(0.95)
        } else if UIImage(named: "island-compact-crop") != nil {
            Image("island-compact-crop")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .luminanceToAlpha()
                .opacity(0.95)
        } else {
            canvasFallback
        }
        #else
        canvasFallback
        #endif
    }

    private var canvasFallback: some View {
        Canvas { context, size in
            let u = size.width / 16
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * u, y: y * u, width: w * u, height: h * u)
            }
            let ink = Color.primary
            context.fill(Path(r(5, 2, 2.5, 2.8)), with: .color(ink.opacity(0.85)))
            context.fill(Path(r(8.5, 2, 2.5, 2.8)), with: .color(ink.opacity(0.85)))
            context.fill(Path(r(4, 4.5, 8, 7.5)), with: .color(ink))
            context.fill(Path(ellipseIn: r(6.2, 6.5, 1.2, 1.4)), with: .color(ink.opacity(0.35)))
            context.fill(Path(ellipseIn: r(8.6, 6.5, 1.2, 1.4)), with: .color(ink.opacity(0.35)))
        }
    }
}

// MARK: - Widget

struct PetAccessoryWidget: Widget {
    let kind = "PetAccessoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetAccessoryProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                AccessoryFamilyView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                AccessoryFamilyView(entry: entry)
            }
        }
        .configurationDisplayName("Live Pet Lock Screen")
        .description("Grayscale Nubby with Feeling dots on your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

private struct AccessoryFamilyView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PetAccessoryEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            PetAccessoryRectangularView(entry: entry)
        default:
            PetAccessoryCircularView(entry: entry)
        }
    }
}
