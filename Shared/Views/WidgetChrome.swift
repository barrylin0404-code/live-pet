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

/// Which sheet + frame a widget pet shows for a (projected) snapshot at a 6 fps tick.
/// Hungry / sad hold their sheets and sleep breathes. Happy / playful play one happy beat, then
/// idle (blinks) a couple of seconds: the happy sheet is a one-shot, and looped nonstop it read
/// as a pet bouncing in place on the Home Screen.
enum WidgetMoodClip {
    /// 6 fps ticks per happy cycle (~3 s): 4 happy frames, then the 6-frame idle twice.
    static let happyCycle = 16

    static func clip(for snapshot: PetSnapshot, tick: Int) -> (anim: PetAnim, frame: Int) {
        if snapshot.isSleeping == true || snapshot.mood == .sleepy {
            return (.sleeping, tick)
        }
        switch snapshot.mood {
        case .hungry:
            return (.hungry, tick)
        case .low:
            return (.sad, tick)
        case .playful, .happy:
            let phase = ((tick % happyCycle) + happyCycle) % happyCycle
            let happyFrames = PetAnimCatalog.clip(for: .happy).frameCount
            return phase < happyFrames ? (.happy, phase) : (.idle, phase - happyFrames)
        default:
            return (.idle, tick)
        }
    }
}

/// Side-view sheet for the projected mood (`WidgetMoodClip`). Missing frames fall back to that species' idle.
struct WidgetPetForeground: View {
    let snapshot: PetSnapshot
    var size: CGFloat = 48

    var body: some View {
        let stage = snapshot.resolvedGrowthStage
        TimelineView(.animation(minimumInterval: 1.0 / 6.0, paused: false)) { context in
            let tick = Int(context.date.timeIntervalSinceReferenceDate * 6)
            let shown = WidgetMoodClip.clip(for: snapshot, tick: tick)
            ClipPetView(
                speciesId: snapshot.petGlyph == "pip" ? "pip" : "nubby",
                anim: shown.anim,
                frame: shown.frame,
                facingLeft: false,
                displaySize: size,
                growthStage: stage
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
