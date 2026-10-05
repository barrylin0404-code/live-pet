# Next-session handoff — Live Pet (Eng continuous rebuild)

**Date:** 2026-10-05 (MT)  
**Repo:** https://github.com/barrylin0404-code/live-pet  
**`main` tip (this ship):** Sleepy-awake yawn + Grow ink card + Accessory copy (on tip past `4679619` Island careCrop)

## Product locks

- Shimeji = quality bar only. Original Nubby + Pip. Free forever — no IAP / Upgrade / Unlock.
- App Lead alone says DONE after comparing a running build to the reference. Eng does not call DONE or offer a test build.
- No care floaters (hearts/stars/Zzz/bubbles/crumbs). Care = sheets.
- Feeling/Satiety: StatusStrip on Scenes (More), not cream capsule on the room plate.
- Do not invent bathStart/sleepStart sheets — aliases stay. Rare stays on idle.
- `ClipPetView.stageSheetsMatchSideView` stays **TRUE** (App Lead cleared).
- Cream sheets with ink stroke only (no white card fills — App Lead). Original assets only.
- Soap never depletes. Kit/plus walks ×6 left as drawn.
- Island schedule / pushType parked (App Lead).
- Photo polaroid stays white (App Lead exception).
- Don’t regress careCrop sizes (nubby 8,8,56,56 / pip 16,16,44,48), fromMoodHold clean exclude, Island `.clean` bath, Hit Island orb/catch/miss, wand lure force-fix, cream ink surfaces. Stroll walkCrop unchanged.

## This eng ship

- **Sleep→wake / sleepy-awake consistency:** `WidgetMoodClip` no longer freezes sleepy-but-awake on a sleeping sheet (widgets / StatusStrip / Pets cards looked napping while room yawned / Island strolled). Real naps still use `PetSleepClip` (sleep ↔ sleepBreathing). Awake drowsy = one `idleYawn` beat then idle (shipped sheets; same cycle length as happy).
- **Grow cream chrome leftover:** `GrowCelebrationSheet` pet+name sits in a clear fill + ink `4A3F35` stroke card (Meet Pip / Scenes pattern) — was bare cream with no stroke.
- **Accessory/Lock mono leftover copy:** gallery description + silhouette comment are pet-agnostic (plus mono path unchanged — still shipped `lock-nubby-plus-mono`).
- Sims: typecheck OK; missing-return 0; islandlook (incl. sleepy-awake) + carehold + roam ALL OK. Island schedule / pushType untouched. Wet→shake + yawn-before-nap already wired — left alone.

## Recent eng (prior tips)

- `4679619` — Island careCrop play/bath/sleep tops + fromMoodHold clean
- `5fdd889` — Island clean bath pass-through + Hit Island miss feel
- `a5012f8` — Wand lure run loop + Shop/Inventory/Pets/Widgets/ribbon cream ink
- `3c5ec89` — Onboarding/Meet Pip/Settings cream ink; Hit Island catch scales with orb size

## Still-open polish (if next session)

- Confirm on device: sleepy-but-awake Home/companion/StatusStrip/Pets = yawn then idle blinks (not frozen sleeping); real nap still breathes; after Wake with low energy widgets do not look asleep.
- Confirm Grow “All grown!” card has ink stroke around the happy pet (Meet Pip parity); Photo polaroid stays white.
- Confirm Lock accessory gallery copy; Big Nubby circular still uses plus mono.
- Confirm Island careCrop play/bath/sleep tops + clean bath pass-through + miss squash from prior tips.
- Island Feed/Pet settle — confirm on device; no eng chase without a real jump residual.
- Wet→shake + yawn-before-nap already wired — no invent.
- Beige `E8D4C4` stroke leftovers already cleared to ink — no invent rare/bathStart/sleepStart.
- Device confirms from older handoff still apply (rename Island restart, Sleep→Wake→Feed, projected flips, kit one-size, soap ×∞, etc.).
- Do **not** chase ActivityKit pushType / suspended flip delivery — parked.
- No new PNGs / floaters / DONE. Eng never DONE.

## Gate

App Lead compares home + Island to Shimeji reference. Reviewer quality only after that gate.

## Eng status

Tip past `4679619` on `main` (this push). Sleepy-awake yawn + Grow ink card + Accessory copy. Shared typecheck OK; islandlook + carehold + roam OK. SwiftUI/ActivityKit not compiled for real here (Linux stubs) — confirm on Mac. **Not DONE.**

**Waiting on**
1. App Lead: compare a running build on a device or Mac against Shimeji for DONE (Eng does not call DONE).
2. App Lead: confirm sleepy-awake widgets/Scenes yawn (not sleeping); Grow ink card; prior Island careCrop / clean bath / miss feel still good.
