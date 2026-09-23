import ActivityKit
import SwiftUI
import WidgetKit

struct PetLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            LockScreenPetView(context: context)
                .activityBackgroundTint(.black.opacity(0.35))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AnimatedPixelPetView(
                        mood: context.state.mood,
                        pose: context.state.petPose,
                        isSleeping: context.state.isSleeping,
                        scale: 0.55
                    )
                    .padding(.leading, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: context.state.mood.symbolName)
                            .font(.title3)
                        Text(context.state.mood.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.petName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    let snap = PetSnapshot.load()
                    HStack(spacing: 10) {
                        MetricChip(
                            title: "Feeling",
                            value: snap?.moodScore ?? bandFallback(context.state.mood),
                            tint: .pink
                        )
                        MetricChip(
                            title: "Satiety",
                            value: snap?.satiety ?? (context.state.mood == .hungry ? 18 : 60),
                            tint: .orange
                        )
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                AnimatedPixelPetView(
                    mood: context.state.mood,
                    pose: context.state.petPose,
                    isSleeping: context.state.isSleeping,
                    scale: 0.28,
                    preferIslandCrop: true
                )
            } compactTrailing: {
                Image(systemName: context.state.mood.symbolName)
            } minimal: {
                Image(systemName: context.state.isSleeping ? "moon.zzz" : "square.fill")
                    .foregroundStyle(Color(red: 0.98, green: 0.52, blue: 0.42))
            }
            .keylineTint(Color(red: 0.98, green: 0.52, blue: 0.42))
        }
    }

}

private func bandFallback(_ mood: PetMood) -> Int {
    switch mood {
    case .happy, .playful: return 80
    case .content: return 60
    case .hungry, .low: return 22
    case .sleepy: return 40
    }
}

private struct LockScreenPetView: View {
    let context: ActivityViewContext<PetActivityAttributes>

    var body: some View {
        let snap = PetSnapshot.load()
        HStack(spacing: 14) {
            AnimatedPixelPetView(
                mood: context.state.mood,
                pose: context.state.petPose,
                isSleeping: context.state.isSleeping,
                scale: 0.7
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.petName)
                    .font(.headline)
                Text(context.state.mood.label + (context.state.isSleeping ? " · Sleeping" : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Label("\(snap?.moodScore ?? 60)%", systemImage: "heart.fill")
                    Label("\(snap?.satiety ?? 60)%", systemImage: "fork.knife")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

private struct MetricChip: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            ProgressView(value: Double(value), total: 100)
                .tint(tint)
            Text("\(value)%")
                .font(.caption2.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
