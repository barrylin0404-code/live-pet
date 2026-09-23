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
                    PixelPetView(mood: context.state.mood, scale: 0.55)
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
                    HStack(spacing: 10) {
                        MetricChip(title: "Mood", value: context.state.moodScore, tint: .pink)
                        MetricChip(title: "Satiety", value: context.state.satiety, tint: .orange)
                        MetricChip(title: "Energy", value: context.state.energy, tint: .green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                Image(systemName: "square.fill")
                    .foregroundStyle(Color(red: 0.98, green: 0.52, blue: 0.42))
            } compactTrailing: {
                Image(systemName: context.state.mood.symbolName)
            } minimal: {
                Image(systemName: "square.fill")
                    .foregroundStyle(Color(red: 0.98, green: 0.52, blue: 0.42))
            }
            .keylineTint(Color(red: 0.98, green: 0.52, blue: 0.42))
        }
    }
}

private struct LockScreenPetView: View {
    let context: ActivityViewContext<PetActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            PixelPetView(mood: context.state.mood, scale: 0.7)
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.petName)
                    .font(.headline)
                Text("\(context.state.mood.label) · \(context.state.lastAction)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 10) {
                    Label("\(context.state.moodScore)%", systemImage: "heart.fill")
                    Label("\(context.state.satiety)%", systemImage: "fork.knife")
                    Label("\(context.state.energy)%", systemImage: "bolt.fill")
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
