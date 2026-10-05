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
                    Text(IslandCareCopy.blurb(for: context.state))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.petName)
                            .font(.headline)
                        Text(context.state.mood.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    islandBottom(isSleeping: context.state.isSleeping || context.state.petPose == .sleep)
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
    private func islandBottom(isSleeping: Bool) -> some View {
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
                .accessibilityLabel(isSleeping ? "Wake" : "Sleep")
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
                Text(IslandCareCopy.blurb(for: context.state))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

/// Dense Island / Lock Screen care copy — pose first, then App Group lastAction.
enum IslandCareCopy {
    static func blurb(for state: PetActivityAttributes.ContentState) -> String {
        if state.isSleeping || state.petPose == .sleep {
            return "Sleeping"
        }
        // Prefer App Group lastAction so Feed/Pet/Lull and in-app care share copy.
        if let snap = PetSnapshot.load(), !snap.lastAction.isEmpty {
            switch state.petPose {
            case .eat, .play, .clean:
                return snap.lastAction
            default:
                break
            }
        }
        switch state.petPose {
        case .eat: return "Eating"
        case .play: return "Playing"
        case .clean: return "Bath time"
        default: break
        }
        if let snap = PetSnapshot.load(), !snap.lastAction.isEmpty {
            return snap.lastAction
        }
        return state.mood.label
    }
}
