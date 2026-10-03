import ActivityKit
import AppIntents
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
                    IslandWalkPetView(
                        mood: context.state.mood,
                        pose: context.state.petPose,
                        isSleeping: context.state.isSleeping,
                        speciesId: context.state.speciesId,
                        growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                        scale: 0.6,
                        forceWalkWhenIdle: true,
                        travelAmplitude: 12,
                        slotHeight: 64
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.mood.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.petName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    islandBottom()
                }
            } compactLeading: {
                // Dense walk + edge flip (TimelineView) — not a static island crop.
                IslandWalkPetView(
                    mood: context.state.mood,
                    pose: context.state.petPose,
                    isSleeping: context.state.isSleeping,
                    speciesId: context.state.speciesId,
                    growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                    scale: 0.34,
                    forceWalkWhenIdle: true,
                    travelAmplitude: 4,
                    slotHeight: 36
                )
            } compactTrailing: {
                // Same side-view pet, paced inside this slot. It does not cross the camera.
                IslandWalkPetView(
                    mood: context.state.mood,
                    pose: context.state.petPose,
                    isSleeping: context.state.isSleeping,
                    speciesId: context.state.speciesId,
                    growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                    scale: 0.34,
                    forceWalkWhenIdle: true,
                    travelAmplitude: 4,
                    slotHeight: 36
                )
            } minimal: {
                IslandWalkPetView(
                    mood: context.state.mood,
                    pose: context.state.petPose,
                    isSleeping: context.state.isSleeping,
                    speciesId: context.state.speciesId,
                    growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                    scale: 0.28,
                    forceWalkWhenIdle: true,
                    travelAmplitude: 0,
                    slotHeight: 30
                )
            }
            .keylineTint(Color(red: 0.98, green: 0.52, blue: 0.42))
        }
    }

    @ViewBuilder
    private func islandBottom() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            HStack(spacing: 16) {
                Button(intent: FeedPetIntent()) {
                    islandTile("ctrl-feed")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Feed")

                Button(intent: PetPetIntent()) {
                    islandTile("ctrl-pet")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pet")

                Button(intent: LullPetIntent()) {
                    islandTile("ctrl-sleep")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sleep")
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        } else {
            HStack(spacing: 16) {
                islandTile("ctrl-feed")
                islandTile("ctrl-pet")
                islandTile("ctrl-sleep")
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
    }

    private func islandTile(_ name: String) -> some View {
        Image(name)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
    }
}

private struct LockScreenPetView: View {
    let context: ActivityViewContext<PetActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            IslandWalkPetView(
                mood: context.state.mood,
                pose: context.state.petPose,
                isSleeping: context.state.isSleeping,
                speciesId: context.state.speciesId,
                growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                scale: 0.7,
                forceWalkWhenIdle: true,
                travelAmplitude: 14,
                slotHeight: 72
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.petName)
                    .font(.headline)
                Text(context.state.mood.label + (context.state.isSleeping ? " · Sleeping" : ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}
