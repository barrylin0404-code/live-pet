import SwiftUI
import WidgetKit
#if canImport(UIKit)
import UIKit
#endif

/// Shared cream/mint chrome + helpers for Home Screen widgets (Wave 4).
enum WidgetChrome {
    static let cream = Color(red: 0.98, green: 0.94, blue: 0.88)
    static let creamDeep = Color(red: 0.94, green: 0.88, blue: 0.78)
    static let mint = Color(red: 0.90, green: 0.95, blue: 0.92)
    static let ink = Color(red: 0.29, green: 0.25, blue: 0.21)
    static let secondaryInk = Color(red: 0x8B / 255.0, green: 0x73 / 255.0, blue: 0x55 / 255.0)
    static let heartFill = Color(red: 1.0, green: 0.30, blue: 0.43)
    static let heartEmpty = Color(red: 1.0, green: 0.70, blue: 0.76)

    /// Deep link → app Pet Home.
    static let homeURL = URL(string: "livepet://home")!

    /// Age days from App Group pet JSON (widget-safe; no Pet type dependency).
    static func ageDaysFromAppGroup() -> Int {
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

    /// Mini Feeling hearts for utility widgets (0…3). Allows 0 at moodScore ≤ 0.
    static func miniHeartCount(moodScore: Int) -> Int {
        guard moodScore > 0 else { return 0 }
        switch moodScore {
        case 67...100: return 3
        case 34..<67: return 2
        default: return 1
        }
    }

    static func feelingPhrase(mood: PetMood) -> String {
        switch mood {
        case .happy: return "Feeling sunny"
        case .content: return "Feeling ok"
        case .hungry: return "Feeling peckish"
        case .sleepy: return "Feeling drowsy"
        case .playful: return "Feeling warm"
        case .low: return "Needs a hug"
        }
    }
}

// MARK: - Backgrounds

struct WidgetMaterialBackground: View {
    var body: some View {
        ZStack {
            WidgetChrome.cream.opacity(0.92)
            LinearGradient(
                colors: [
                    WidgetChrome.mint.opacity(0.55),
                    WidgetChrome.creamDeep.opacity(0.35),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            #if canImport(UIKit)
            if #available(iOS 17.0, iOSApplicationExtension 17.0, *) {
                Rectangle().fill(.ultraThinMaterial).opacity(0.35)
            }
            #endif
        }
    }
}

struct WidgetCreamFallbackBackground: View {
    var body: some View {
        LinearGradient(
            colors: [WidgetChrome.cream, WidgetChrome.mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Applies iOS 17+ containerBackground materials; older solid cream — never crash.
/// Note: `containerBackgroundRemovable` is a WidgetConfiguration API — set on the widget body, not here.
struct WidgetBackgroundModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, iOSApplicationExtension 17.0, *) {
            content
                .containerBackground(for: .widget) {
                    WidgetMaterialBackground()
                }
        } else {
            content.background(WidgetCreamFallbackBackground())
        }
    }
}

extension View {
    func livePetWidgetBackground() -> some View {
        modifier(WidgetBackgroundModifier())
    }
}

// MARK: - Mini chrome

struct FeelingMiniHearts: View {
    let moodScore: Int
    var size: CGFloat = 10

    var body: some View {
        let filled = WidgetChrome.miniHeartCount(moodScore: moodScore)
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < filled ? "heart.fill" : "heart")
                    .font(.system(size: size))
                    .foregroundStyle(i < filled ? WidgetChrome.heartFill : WidgetChrome.heartEmpty)
            }
        }
        .accessibilityLabel("Feeling, \(moodScore) percent, \(filled) of 3 hearts")
    }
}

struct SatietyMiniBar: View {
    let satiety: Int

    var body: some View {
        ProgressView(value: Double(max(0, min(100, satiety))), total: 100)
            .tint(.orange)
            .frame(maxWidth: 72)
            .accessibilityLabel("Satiety \(satiety) percent")
    }
}

/// Idle/sleep pet crop ~40–56pt, nearest-neighbor when assets exist.
struct WidgetPetForeground: View {
    let snapshot: PetSnapshot
    var size: CGFloat = 48

    var body: some View {
        let sleeping = snapshot.isSleeping == true || snapshot.mood == .sleepy
        AnimatedPixelPetView(
            mood: snapshot.mood,
            pose: sleeping ? .sleep : .idle,
            isSleeping: sleeping,
            speciesId: snapshot.petGlyph,
            growthStage: snapshot.resolvedGrowthStage,
            scale: size / 64
        )
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
