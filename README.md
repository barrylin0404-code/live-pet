# Live Pet

Original Dynamic Island pixel-pet companion for iOS 16.2+.

Care for **Nubby** in the **Sun Nook** — feed, play, and sleep while Feeling, Satiety, and Energy stay visible on the **Dynamic Island**, Lock Screen (Live Activity), and a **Home Screen widget**.

> Built as source + [XcodeGen](https://github.com/yonaskolb/XcodeGen) `project.yml`. Generate the `.xcodeproj` on a Mac (no iOS Simulator / Xcode on the Linux scaffold host).
>
> **Original work only** — geometric Canvas pet & room art, original names. Not affiliated with Shimeji / Pixel Shimeji or other desktop pet brands.


## P0 status (Engineer)

- App Group `group.com.barrylin.livepet` shared by app + widget + Live Activity snapshot
- Home Screen widget (small + medium): pet + Feeling / Satiety
- Island: tiny ContentState (`speciesId` / `pose` / `moodBand` / `isSleeping`); meters from App Group snapshot; `TimelineView` idle loops; renew/restart before ~8h
- UI shows Feeling + Satiety only (Energy kept in model for Sleep / decay)
- Island intents (iOS 17+) deferred until after widget ships; Designer art swap next

## V1 features

| Feature | Details |
|--------|---------|
| Needs meters | **Feeling** (mood), **Satiety**, and **Energy** (0–100). Decay on a timer while the app is open, plus offline decay after relaunch. |
| Feed / Play / Sleep | Quick actions (`feedDefault` / `playDefault` / sleep) + inventory picks. Updates in-app state **and** the Live Activity when active. |
| Persistence | `Pet` + inventory + `PetSnapshot` saved in the **App Group** suite `group.com.barrylin.livepet` (`UserDefaults(suiteName:)`). Survives force-quit / relaunch and is readable by the widget. |
| Sleep / rest | Dedicated **Sleep** button restores energy (gesture optional; button is v1). |
| Original pet + room | **Nubby** (Canvas pixel geometry) in **Sun Nook** (window, rug, plant, shelf — all drawn in code). |
| Inventory | 3 foods (Crumb Cake, Berry Cube, Glow Pellet) and 3 toys (Bounce Block, Twinkle Ball, Soft Square). |
| Live Activity | Compact / minimal / expanded Dynamic Island + Lock Screen, sharing `PetActivityAttributes`. Renews before the ~8h OS cap. |
| Home Screen widget | **PetHomeWidget** — small + medium: pet sprite + Feeling/Satiety from shared `PetSnapshot`. `WidgetCenter.shared.reloadAllTimelines()` on care actions. |

**Skipped for this ship:** evolve, arcade/minigames, IAP, multi-pet unlock, Settings rename UI, age-in-days meter.

## App Group & shared state

| Piece | Detail |
|-------|--------|
| App Group ID | `group.com.barrylin.livepet` |
| Targets | Enable **App Groups** for **both** `LivePet` and `LivePetWidget` (entitlements ship in-repo; Mac Xcode must still turn on the capability matching that ID). |
| Shared types | `Shared/AppGroup.swift` — suite helpers, keys, and `PetSnapshot` (name, glyph, mood/satiety/energy, mood raw, last action, last updated). |
| Widget | `LivePetWidget/PetHomeWidget.swift` — small + medium Home Screen widget reading `PetSnapshot` from the suite. |
| Sync | `PetStore` writes the suite + snapshot and calls `WidgetCenter.shared.reloadAllTimelines()` after Feed / Play / Sleep / tick. |

## Repo layout

| Path | Role |
|------|------|
| `LivePet/` | Main SwiftUI app (UI, `PetStore`, Live Activity manager) |
| `LivePet/Models/` | `Pet`, `InventoryItem` |
| `LivePet/Views/` | Inventory panel |
| `LivePet/Services/` | Persistence + ActivityKit manager |
| `LivePetWidget/` | Widget Extension — Live Activity / Dynamic Island + Home Screen widget |
| `Shared/` | `AppGroup` / `PetSnapshot`, `PetActivityAttributes`, `PetMood`, `PixelPetView`, `RoomSceneView` / `SunNookScene` |
| `project.yml` | XcodeGen spec (App + Widget Extension) |

## Requirements (Mac)

- macOS with **Xcode 15+** (iOS 16.2 SDK or newer)
- Physical iPhone with Dynamic Island recommended (14 Pro / 15 / 16 / etc.) — Simulator has limited Live Activity / Island support
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) **or** create targets manually in Xcode

## Open & build on a Mac

### Option A — XcodeGen (recommended)

```bash
git clone https://github.com/barrylin0404-code/live-pet.git
cd live-pet
brew install xcodegen   # once
xcodegen generate
open LivePet.xcodeproj
```

1. Select the **LivePet** scheme.
2. Set your Team under Signing & Capabilities for **both** `LivePet` and `LivePetWidget`.
3. **Enable App Groups** on both targets with ID `group.com.barrylin.livepet` (must match the entitlements / `AppGroup` suite name). XcodeGen may not fully surface the capability UI — add it manually if needed.
4. Build & run on a device (or Simulator for UI / widget gallery only).
5. Tap **Start in Dynamic Island**, then Feed / Play / Sleep (or inventory items) to see Island updates. Add the **Live Pet** Home Screen widget from the widget gallery.

### Option B — Manual Xcode project

1. Create a new **App** project (SwiftUI, iOS 16.2+, product name `LivePet`).
2. Add a **Widget Extension** target named `LivePetWidget` (include Live Activity).
3. Add sources:
   - App target: `LivePet/` + `Shared/`
   - Widget target: `LivePetWidget/` + `Shared/`
4. Confirm `NSSupportsLiveActivities` = `YES` in both Info plists.
5. Add **App Groups** capability (`group.com.barrylin.livepet`) to **both** targets.
6. Set bundle IDs (defaults: `com.barrylin.livepet` / `com.barrylin.livepet.widget`) and your development team.

## How it works

1. `PetStore` loads/saves pet + inventory (+ `PetSnapshot`) via the App Group suite, applies offline decay, ticks needs every ~20s, and reloads widget timelines on change.
2. Feed / play / sleep mutate `Pet` and call `onPetChange`.
3. `PetLiveActivityManager` requests / updates / ends `Activity<PetActivityAttributes>`, sets `staleDate` ~8h out, and **renews (end+restart) at ~7h** so the Island survives the OS lifetime cap.
4. `PetLiveActivityWidget` renders Lock Screen + Dynamic Island from the shared content state; `PetHomeWidget` renders small/medium Home Screen tiles from `PetSnapshot`.
5. Canvas views in `Shared/Views` draw Nubby and Sun Nook for the app (and Nubby on the Island / Lock Screen / widget).

## Limitations

- No `.xcodeproj` checked in (generate on Mac via XcodeGen).
- Cannot compile or run on Linux — no Xcode / Simulator.
- Local ActivityKit updates only (`pushType: nil`); no push-to-update yet.
- Placeholder App Icon — add a 1024×1024 image in `AppIcon.appiconset`.
- Food soft-refills when depleted so v1 never soft-locks; toys are reusable.
- After `xcodegen generate`, confirm App Groups is enabled in Xcode for both targets with `group.com.barrylin.livepet`.

## License

Add a license of your choice. No third-party dependencies. Original pet/room art and names.
