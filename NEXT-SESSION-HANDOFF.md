# Next-session handoff — Live Pet (Eng continuous rebuild)

**Date:** 2026-10-05 (MT)  
**Repo:** https://github.com/barrylin0404-code/live-pet  
**`main` tip (this ship):** Wand lure run no longer stuck on frame 0; Shop/Inventory/Pets/Widgets/ribbon beige → cream ink (on tip past `3c5ec89` Onboarding/Meet Pip/Settings cream + Hit Island catch scales)

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

- **Wand / Soft Square lure leftover:** `PetBrain.trackLure` far-run used `force: true` every ~40 ms lure tick → runLeft/runRight restarted at frame 0 (stuck/paddle feel). Now matches walk/play mid-close: `force: player.anim != run` so the loop advances.
- **Cream ink leftover:** Shop / Inventory sheet / Pets cards (unselected + locked Pip) / Widgets gallery / ribbon cells drop beige `E8D4C4` for ink stroke `4A3F35` — same family as Food / Play / Scenes / Onboarding / Settings. Favorite gold unchanged. Photo polaroid untouched.
- Sims: typecheck OK; missing-return 0; roam + carehold ALL OK. Island schedule / pushType untouched.

## Recent eng (prior tips)

- `3c5ec89` — Onboarding/Meet Pip/Settings cream ink; Hit Island catch scales with orb size
- `d21192f` — Island careCrop; Food/Play ink cells; Hit Island orb size
- `2b6655e` — Scenes hub ink stroke; Hit Island timer cream stroke
- `01d2bc2` — Grow/Meet Pip cream chrome; Pets sleep-breath + PressScale
- `7ca89b9`…`47be37c` — sleep-breath, scoot/Pip/StatusStrip — see research handoff

## Still-open polish (if next session)

- Confirm on device: wand / Soft Square far chase runs a smooth loop (not frozen first frame); mid walk + close play unchanged; Feeling once + happy end still fire.
- Confirm Shop / Inventory / Pets / Widgets / ribbon cells read ink stroke (favorites still gold).
- Confirm Onboarding/Meet Pip/Settings cream + Hit Island catch scales from `3c5ec89`.
- Confirm Island careCrop / Food-Play ink / Hit Island orb size from `d21192f`.
- Wet→shake + yawn-before-nap already wired with shipped sheets — no new invent.
- Island Feed/Pet settle + compact careCrop — confirm on device; no eng chase without a real jump residual.
- Accessory/Lock mono — plus uses shipped `lock-nubby-plus-mono`; confirm circular on device.
- Device confirms from older handoff still apply (rename Island restart, Sleep→Wake→Feed, projected flips, kit one-size, etc.).
- Do **not** chase ActivityKit pushType / suspended flip delivery — parked.
- No new PNGs / floaters / DONE. Eng never DONE.

## Gate

App Lead compares home + Island to Shimeji reference. Reviewer quality only after that gate.

## Eng status

Tip past `3c5ec89` on `main` (this push). Wand lure run loop fix + Shop/Inventory/Pets/Widgets/ribbon cream ink. Shared typecheck OK; roam + carehold OK. SwiftUI/ActivityKit not compiled for real here (Linux stubs) — confirm on Mac. **Not DONE.**

**Waiting on**
1. App Lead: compare a running build on a device or Mac against Shimeji for DONE (Eng does not call DONE).
2. App Lead: confirm wand chase loop + remaining cream ink cells on device.
