# Next-session handoff — Live Pet (Eng continuous rebuild)

**Date:** 2026-10-05 (MT)  
**Repo:** https://github.com/barrylin0404-code/live-pet  
**`main` tip (this ship):** Island clean bath pass-through + Hit Island miss feel (on tip past `a5012f8` wand lure + cream ink)

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

## This eng ship

- **Island clean leftover:** `islandContentState` remapped `.clean` → walk with idle, so an in-app bath never showed bathing on Island / Lock (eat/play already passed through; `IslandWalkPetView` + `islandUpdate` clean→walk recenter already existed). Clean now passes through like eat/play; settle still recenters stroll at x=0.
- **Hit Island miss feel leftover:** miss only had sad + uiTick while catch had pop + rigid haptic. Miss now squash-bumps paddle (0.94) + soft haptic; catch still pop 1.06 + rigid via shared `bumpPaddle`.
- Sims: typecheck OK; missing-return 0; islandlook + carehold + roam ALL OK. Island schedule / pushType untouched.

## Recent eng (prior tips)

- `a5012f8` — Wand lure run loop + Shop/Inventory/Pets/Widgets/ribbon cream ink
- `3c5ec89` — Onboarding/Meet Pip/Settings cream ink; Hit Island catch scales with orb size
- `d21192f` — Island careCrop; Food/Play ink cells; Hit Island orb size
- `2b6655e`…`47be37c` — Scenes ink, Grow chrome, scoot/Pip — see research handoff

## Still-open polish (if next session)

- Confirm on device: in-app bath shows bathing on Island / Lock, then stroll at care x; blurb keeps soap/bath line.
- Confirm Hit Island miss: brief squash + soft haptic with sad (catch still pops).
- Confirm wand / Soft Square far chase + cream ink cells from `a5012f8`.
- Wet→shake + yawn-before-nap already wired with shipped sheets — no new invent.
- Island Feed/Pet settle + compact careCrop — confirm on device; no eng chase without a real jump residual.
- Accessory/Lock mono — plus uses shipped `lock-nubby-plus-mono`; confirm circular on device.
- Grow beige strokes already ink; no invent rare/bathStart/sleepStart sheets.
- Device confirms from older handoff still apply (rename Island restart, Sleep→Wake→Feed, projected flips, kit one-size, etc.).
- Do **not** chase ActivityKit pushType / suspended flip delivery — parked.
- No new PNGs / floaters / DONE. Eng never DONE.

## Gate

App Lead compares home + Island to Shimeji reference. Reviewer quality only after that gate.

## Eng status

Tip past `a5012f8` on `main` (this push). Island clean bath pass-through + Hit Island miss feel. Shared typecheck OK; islandlook + carehold + roam OK. SwiftUI/ActivityKit not compiled for real here (Linux stubs) — confirm on Mac. **Not DONE.**

**Waiting on**
1. App Lead: compare a running build on a device or Mac against Shimeji for DONE (Eng does not call DONE).
2. App Lead: confirm Island bath sheet + Hit Island miss squash/haptic on device.
