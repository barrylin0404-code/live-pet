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
            // Several statements: this closure is not a builder, so it needs an explicit return.
            let look = IslandLook(state: context.state, petName: context.attributes.petName)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    IslandWalkPetView(
                        mood: look.mood,
                        pose: look.pose,
                        isSleeping: look.isSleeping,
                        speciesId: context.state.speciesId,
                        growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                        scale: 0.6,
                        forceWalkWhenIdle: true,
                        travelAmplitude: 12,
                        slotHeight: 64,
                        walkEpoch: look.walkEpoch
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(IslandCareCopy.blurb(for: look))
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
                        Text(look.mood.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    islandBottom(isSleeping: look.isSleeping)
                }
            } compactLeading: {
                // Dense walk + edge flip (TimelineView) — not a static island crop.
                IslandWalkPetView(
                    mood: look.mood,
                    pose: look.pose,
                    isSleeping: look.isSleeping,
                    speciesId: context.state.speciesId,
                    growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                    scale: 0.34,
                    forceWalkWhenIdle: true,
                    travelAmplitude: 4,
                    slotHeight: 36,
                    walkEpoch: look.walkEpoch
                )
            } compactTrailing: {
                // Same side-view pet, paced inside this slot. It does not cross the camera.
                IslandWalkPetView(
                    mood: look.mood,
                    pose: look.pose,
                    isSleeping: look.isSleeping,
                    speciesId: context.state.speciesId,
                    growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                    scale: 0.34,
                    forceWalkWhenIdle: true,
                    travelAmplitude: 4,
                    slotHeight: 36,
                    walkEpoch: look.walkEpoch
                )
            } minimal: {
                IslandWalkPetView(
                    mood: look.mood,
                    pose: look.pose,
                    isSleeping: look.isSleeping,
                    speciesId: context.state.speciesId,
                    growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                    scale: 0.28,
                    forceWalkWhenIdle: true,
                    travelAmplitude: 0,
                    slotHeight: 30,
                    walkEpoch: look.walkEpoch
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
        let look = IslandLook(state: context.state, petName: context.attributes.petName)
        HStack(spacing: 14) {
            IslandWalkPetView(
                mood: look.mood,
                pose: look.pose,
                isSleeping: look.isSleeping,
                speciesId: context.state.speciesId,
                growthStage: GrowthStage(rawValue: context.state.growthStage ?? "nubby") ?? .nubby,
                scale: 0.7,
                forceWalkWhenIdle: true,
                travelAmplitude: 14,
                slotHeight: 72,
                walkEpoch: look.walkEpoch
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.petName)
                    .font(.headline)
                // Same mood word as expanded Island center — advances with ContentState flips.
                Text(look.mood.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(IslandCareCopy.blurb(for: look))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

/// What the Island draws right now. `ContentState` is only as fresh as the last
/// `Activity.update`, and nothing updates it while the app is closed — a pet left all afternoon
/// kept strolling content, and a nap that ended on its own kept the sleeping sheet until launch.
/// When the App Group snapshot is this pet, use it projected to now (same `PetDecay` as the
/// widgets): hungry / sad / wake show up on the Island on their own. Care poses (eat / play /
/// bath) are always fresh writes, so they pass straight through.
struct IslandLook {
    var mood: PetMood
    var pose: PetPose
    var isSleeping: Bool
    var name: String
    /// Projected snapshot for this pet, if any (blurb source).
    var snapshot: PetSnapshot?
    /// A nap that ended since the last write (projection woke a pet saved asleep).
    var wokeOnItsOwn: Bool
    /// Roam clock for IslandWalkPetView (Activity epoch, or centered after a projected wake).
    var walkEpoch: Double?
    /// Clock for care-blurb hold (same ~1 min window as `Pet.awakeTickBlurb`).
    var now: Date

    init(state: PetActivityAttributes.ContentState, petName: String, now: Date = .now) {
        let sleeping = state.isSleeping || state.petPose == .sleep
        mood = state.mood
        pose = state.petPose
        isSleeping = sleeping
        name = petName
        snapshot = nil
        wokeOnItsOwn = false
        walkEpoch = state.walkEpoch
        self.now = now
        guard let saved = PetSnapshot.loadSaved(),
              saved.name == petName,
              (saved.petGlyph == "pip") == (state.speciesId == "pip") else { return }
        let projected = saved.projected(to: now)
        snapshot = projected
        switch state.petPose {
        case .eat, .play, .clean:
            return
        default:
            break
        }
        // Only trust the snapshot's nap state when it agrees with the Activity's last write.
        guard (saved.isSleeping == true) == sleeping else { return }
        if sleeping, projected.isSleeping != true {
            isSleeping = false
            pose = .walk
            wokeOnItsOwn = true
            // Sleep sheet was centered — resume stroll from x=0, not wall-clock.
            walkEpoch = PetActivityAttributes.ContentState.centeredWalkEpoch(
                at: now.timeIntervalSinceReferenceDate,
                mood: projected.mood
            )
        }
        mood = projected.mood
        // Activity band still hungry/low while projection recovered (snapshot care, no
        // Activity write yet): hold sheets sit at x=0 — resume stroll centered, same as
        // islandUpdate after care→walk / projected wake. Do not touch walk→walk ticks.
        if !wokeOnItsOwn,
           !isSleeping,
           pose != .eat, pose != .play, pose != .clean, pose != .sleep,
           !mood.holdsIslandStroll {
            if state.mood.holdsIslandStroll {
                pose = .walk
                walkEpoch = PetActivityAttributes.ContentState.centeredWalkEpoch(
                    at: now.timeIntervalSinceReferenceDate,
                    mood: mood
                )
            } else if state.mood.islandEdgePause != mood.islandEdgePause {
                // Stale Activity band (e.g. playful) vs projected content/sleepy changes
                // park length — same clock would teleport on the compact / Lock stroll.
                walkEpoch = PetActivityAttributes.ContentState.centeredWalkEpoch(
                    at: now.timeIntervalSinceReferenceDate,
                    mood: mood
                )
            }
        }
    }
}

/// Dense Island / Lock Screen care copy — pose first, then App Group lastAction.
/// After care, the line holds ~1 min then becomes hungry / needs care / hanging out — same
/// vocabulary as `Pet.awakeTickBlurb`. Mood word on the banner stays `look.mood.label`.
enum IslandCareCopy {
    /// Matches ~3×20s `blurbTicks` before a care line yields to hanging out.
    static let careHoldSeconds: TimeInterval = 60

    static func blurb(for look: IslandLook) -> String {
        if look.isSleeping || look.pose == .sleep {
            return "Sleeping"
        }
        let snap = look.snapshot ?? PetSnapshot.load()
        // Prefer App Group lastAction so Feed/Pet/Lull and in-app care share copy.
        if let snap, !snap.lastAction.isEmpty {
            switch look.pose {
            case .eat, .play, .clean:
                return snap.lastAction
            default:
                break
            }
        }
        switch look.pose {
        case .eat: return "Eating"
        case .play: return "Playing"
        case .clean: return "Bath time"
        default: break
        }
        // Same lines `Pet.tick` writes once the app catches up — the Island says it first.
        if look.wokeOnItsOwn {
            return "\(look.name) woke up"
        }
        switch look.mood {
        case .hungry: return "\(look.name) is hungry"
        case .low: return "\(look.name) needs care"
        default: break
        }
        let hangingOut = "\(look.name) is hanging out"
        guard let snap, !snap.lastAction.isEmpty else {
            return hangingOut
        }
        // Leftover sleep copy while awake (Activity already woke) — same as Pet.tick.
        let sleepLine = snap.lastAction == "\(look.name) is sleeping"
            || snap.lastAction == "\(look.name) tucked in"
        if sleepLine {
            return hangingOut
        }
        // Care line holds ~1 min after the App Group write, then hanging out.
        let age = look.now.timeIntervalSince(snap.lastUpdated)
        if age < careHoldSeconds {
            return snap.lastAction
        }
        return hangingOut
    }
}
