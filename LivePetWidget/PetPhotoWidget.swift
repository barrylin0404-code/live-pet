import SwiftUI
import WidgetKit
#if canImport(UIKit)
import UIKit
#endif

struct PetPhotoEntry: TimelineEntry {
    let date: Date
    let snapshot: PetSnapshot
    let hasPhoto: Bool
}

struct PetPhotoProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetPhotoEntry {
        PetPhotoEntry(date: .now, snapshot: .placeholder, hasPhoto: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetPhotoEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetPhotoEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now)
            ?? .now.addingTimeInterval(21600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> PetPhotoEntry {
        let has: Bool = {
            guard let url = AppGroup.petFrameURL else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        }()
        return PetPhotoEntry(
            date: .now,
            snapshot: PetSnapshot.load() ?? .placeholder,
            hasPhoto: has
        )
    }
}

struct PetPhotoWidgetView: View {
    var entry: PetPhotoEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let snap = entry.snapshot
        HStack(alignment: .bottom, spacing: 12) {
            polaroid
                .frame(maxWidth: family == .systemSmall ? .infinity : 150)

            if family != .systemSmall {
                VStack(alignment: .leading, spacing: 6) {
                    Spacer(minLength: 0)
                    Text(snap.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(WidgetChrome.ink)
                        .lineLimit(1)
                    FeelingMiniHearts(moodScore: snap.moodScore)
                    if !entry.hasPhoto {
                        Text("Add a photo in Settings")
                            .font(.caption2)
                            .foregroundStyle(WidgetChrome.secondaryInk)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .overlay(alignment: .bottomTrailing) {
            WidgetPetForeground(snapshot: snap, size: 36)
                .offset(x: -4, y: -2)
        }
        .widgetURL(WidgetChrome.homeURL)
    }

    @ViewBuilder
    private var polaroid: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white)
                .shadow(color: WidgetChrome.creamDeep.opacity(0.9), radius: 2, y: 2)

            Group {
                if entry.hasPhoto, let image = loadFrameImage() {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [
                            WidgetChrome.mint,
                            WidgetChrome.creamDeep,
                            Color(red: 0.85, green: 0.90, blue: 0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(WidgetChrome.secondaryInk.opacity(0.7))
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .padding(8)
            .padding(.bottom, 14)
        }
        .aspectRatio(0.82, contentMode: .fit)
    }

    #if canImport(UIKit)
    private func loadFrameImage() -> Image? {
        guard let url = AppGroup.petFrameURL,
              let ui = UIImage(contentsOfFile: url.path) else { return nil }
        return Image(uiImage: ui).interpolation(.medium)
    }
    #else
    private func loadFrameImage() -> Image? { nil }
    #endif
}

struct PetPhotoWidget: Widget {
    let kind = "PetPhotoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetPhotoProvider()) { entry in
            PetPhotoWidgetView(entry: entry)
                .livePetWidgetBackground()
        }
        .configurationDisplayName("Pet Photo")
        .description("Your photo + pet")
        .supportedFamilies([.systemSmall, .systemMedium])
        // Photo may be the visual background → pin for this family only.
        .containerBackgroundRemovable(false)
    }
}
