import ActivityKit
import SwiftUI
import WidgetKit

struct PetLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            // Lock Screen / banner presentation
            LockScreenPetView(context: context)
                .activityBackgroundTint(.black.opacity(0.35))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.speciesEmoji)
                        .font(.largeTitle)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.mood.emoji)
                            .font(.title2)
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
                    HStack(spacing: 16) {
                        MetricChip(title: "Hunger", value: context.state.hunger, tint: .orange)
                        MetricChip(title: "Energy", value: context.state.energy, tint: .green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                Text(context.attributes.speciesEmoji)
            } compactTrailing: {
                Text(context.state.mood.emoji)
            } minimal: {
                Text(context.attributes.speciesEmoji)
            }
            .keylineTint(.orange)
        }
    }
}

private struct LockScreenPetView: View {
    let context: ActivityViewContext<PetActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            Text(context.attributes.speciesEmoji)
                .font(.system(size: 40))
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.petName)
                    .font(.headline)
                Text("\(context.state.mood.emoji) \(context.state.mood.label) · \(context.state.lastAction)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 12) {
                    Label("\(context.state.hunger)%", systemImage: "fork.knife")
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
