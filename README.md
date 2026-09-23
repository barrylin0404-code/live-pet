# Live Pet

A SwiftUI + **ActivityKit Live Activities** starter for a Dynamic Island pet companion on iOS 16.2+.

Feed, play, and rest with a simple in-app pet. Start a Live Activity to keep mood, hunger, and energy visible on the **Dynamic Island** (compact / minimal / expanded) and the Lock Screen.

> This repository was scaffolded on Linux. It ships source + an [XcodeGen](https://github.com/yonaskolb/XcodeGen) `project.yml`. Generate the `.xcodeproj` on a Mac — there is no iOS Simulator or Xcode here.

## What’s included

| Path | Role |
|------|------|
| `LivePet/` | Main SwiftUI app (entry, UI, Live Activity manager) |
| `LivePetWidget/` | Widget Extension hosting the Live Activity / Dynamic Island UI |
| `Shared/` | Shared `PetActivityAttributes` + `PetMood` (ActivityKit model) |
| `project.yml` | XcodeGen spec for App + Widget Extension targets |
| `LivePet/Info.plist` | `NSSupportsLiveActivities` (+ frequent updates) |

### App features (starter)

- Pet model with hunger / energy / mood and Feed · Play · Rest actions
- Background tick that slowly changes stats
- Start / update / end Live Activity from the main UI
- Dynamic Island: compact leading/trailing, minimal, and expanded regions
- Lock Screen Live Activity layout

## Requirements (Mac)

- macOS with **Xcode 15+** (iOS 16.2 SDK or newer)
- Physical iPhone with Dynamic Island recommended (14 Pro / 15 / 16 / etc.) — Simulator has limited Live Activity / Island support
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) **or** create targets manually in Xcode (see below)

## Open & build on a Mac

### Option A — XcodeGen (recommended)

```bash
git clone https://github.com/barrylin0404-code/live-pet.git
cd live-pet
brew install xcodegen   # once
xcodegen generate
open LivePet.xcodeproj
```

1. Select the **LivePet** scheme and your team under Signing & Capabilities for both `LivePet` and `LivePetWidget`.
2. Build & run on a device (or Simulator for UI only).
3. Tap **Start in Dynamic Island**, then Feed / Play / Rest to see updates.

### Option B — Manual Xcode project

1. Create a new **App** project (SwiftUI, iOS 16.2+, product name `LivePet`).
2. Add a **Widget Extension** target named `LivePetWidget` (include Live Activity / no Intent if prompted).
3. Replace generated sources with the files in this repo:
   - App target: everything under `LivePet/` + `Shared/`
   - Widget target: everything under `LivePetWidget/` + `Shared/`
4. Ensure both targets have **Live Activities** support:
   - Info: `NSSupportsLiveActivities` = `YES` (already in the plists here)
5. Set a unique bundle ID (e.g. `com.yourname.livepet` / `.widget`) and your development team.
6. Embed the widget extension in the app target (Xcode usually does this when you add the extension).

## How Live Activities are wired

1. `PetLiveActivityManager` calls `Activity.request(attributes:content:)` with `PetActivityAttributes`.
2. Pet actions mutate local `Pet` state and call `activity.update(...)`.
3. `PetLiveActivityWidget` renders Lock Screen + Dynamic Island presentations from the same attributes / content state.
4. **End Live Activity** calls `activity.end(...)`.

Shared types live in `Shared/` so App and Widget compile the same ActivityKit model.

## Limitations of this scaffold

- No `.xcodeproj` checked in (generated on Mac via XcodeGen).
- Cannot be compiled or run on this Linux machine — no Xcode / Simulator.
- No push-to-update token flow yet (`pushType: nil`); updates are local from the app.
- Placeholder App Icon asset (add a 1024×1024 image in `AppIcon.appiconset`).
- Bundle IDs are `com.barrylin.livepet` / `.widget` — change if needed.

## Next steps for Barry

1. Generate the project on a Mac and run on a Dynamic Island device.
2. Customize pet species, animations, and Island expanded layout.
3. Optionally add ActivityKit push updates for background refresh when the app is suspended.
4. Add App Store icons, privacy strings if needed, and a real accent/branding pass.

## License

Add a license of your choice. Scaffold only — no third-party dependencies.
