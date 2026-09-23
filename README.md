# Live Pet

Original Dynamic Island pixel-pet companion for iOS 16.2+.

Care for **Nubby** in the **Sun Nook** — feed, play, and sleep while mood, satiety, and energy stay visible on the **Dynamic Island** and Lock Screen via ActivityKit Live Activities.

> Built as source + [XcodeGen](https://github.com/yonaskolb/XcodeGen) `project.yml`. Generate the `.xcodeproj` on a Mac (no iOS Simulator / Xcode on the Linux scaffold host).
>
> **Original work only** — geometric Canvas pet & room art, original names. Not affiliated with Shimeji / Pixel Shimeji or other desktop pet brands.

## V1 features

| Feature | Details |
|--------|---------|
| Needs meters | **Mood**, **satiety**, and **energy** (0–100). Decay on a timer while the app is open, plus offline decay after relaunch. |
| Feed / Play / Sleep | Quick actions + inventory picks. Updates in-app state **and** the Live Activity when active. |
| Persistence | `Pet` + inventory saved in `UserDefaults` (`livepet.v1.*`). Survives force-quit / relaunch. |
| Sleep / rest | Dedicated **Sleep** button restores energy (gesture optional; button is v1). |
| Original pet + room | **Nubby** (Canvas pixel geometry) in **Sun Nook** (window, rug, plant, shelf — all drawn in code). |
| Inventory | 3 foods (Crumb Cake, Berry Cube, Glow Pellet) and 3 toys (Bounce Block, Twinkle Ball, Soft Square). |
| Live Activity | Compact / minimal / expanded Dynamic Island + Lock Screen, sharing `PetActivityAttributes`. |

**Skipped for this ship:** evolve, arcade/minigames, IAP, home-screen widgets beyond Live Activity, multi-pet unlock.

## Repo layout

| Path | Role |
|------|------|
| `LivePet/` | Main SwiftUI app (UI, `PetStore`, Live Activity manager) |
| `LivePet/Models/` | `Pet`, `InventoryItem` |
| `LivePet/Views/` | Inventory panel |
| `LivePet/Services/` | Persistence + ActivityKit manager |
| `LivePetWidget/` | Widget Extension — Live Activity / Dynamic Island UI |
| `Shared/` | `PetActivityAttributes`, `PetMood`, `PixelPetView`, `RoomSceneView` / `SunNookScene` |
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
3. Build & run on a device (or Simulator for UI only).
4. Tap **Start in Dynamic Island**, then Feed / Play / Sleep (or inventory items) to see Island updates.

### Option B — Manual Xcode project

1. Create a new **App** project (SwiftUI, iOS 16.2+, product name `LivePet`).
2. Add a **Widget Extension** target named `LivePetWidget` (include Live Activity).
3. Add sources:
   - App target: `LivePet/` + `Shared/`
   - Widget target: `LivePetWidget/` + `Shared/`
4. Confirm `NSSupportsLiveActivities` = `YES` in both Info plists.
5. Set bundle IDs (defaults: `com.barrylin.livepet` / `com.barrylin.livepet.widget`) and your development team.

## How it works

1. `PetStore` loads/saves pet + inventory, applies offline decay, and ticks needs every ~20s.
2. Feed / play / sleep mutate `Pet` and call `onPetChange`.
3. `PetLiveActivityManager` requests / updates / ends `Activity<PetActivityAttributes>`.
4. `PetLiveActivityWidget` renders Lock Screen + Dynamic Island from the shared content state.
5. Canvas views in `Shared/Views` draw Nubby and Sun Nook for the app (and Nubby on the Island / Lock Screen).

## Limitations

- No `.xcodeproj` checked in (generate on Mac via XcodeGen).
- Cannot compile or run on Linux — no Xcode / Simulator.
- Local ActivityKit updates only (`pushType: nil`); no push-to-update yet.
- Placeholder App Icon — add a 1024×1024 image in `AppIcon.appiconset`.
- Food soft-refills when depleted so v1 never soft-locks; toys are reusable.

## License

Add a license of your choice. No third-party dependencies. Original pet/room art and names.
