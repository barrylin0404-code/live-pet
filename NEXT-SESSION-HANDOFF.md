# Next-session handoff — Live Pet (Eng continuous rebuild)

**Date:** 2026-10-05 (MT)  
**Repo:** https://github.com/barrylin0404-code/live-pet  
**`main` tip (this ship):** Onboarding/Meet Pip/Settings cream ink; Hit Island catch scales with orb size (on tip past `d21192f` Island careCrop + Food/Play ink + Hit Island orb size)

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

## This eng ship

- **Onboarding cream consistency:** name field drops white fill for clear + ink stroke `4A3F35`; outer card beige → ink (2.5). Matches Scenes / Food / Grow chrome.
- **Meet Pip / Settings cream leftover:** Meet Pip blurb card + Settings blocks (incl. Photo / rename) drop beige `E8D4C4` for ink stroke. Pet Photo widget polaroid stays white (polaroid exception).
- **Hit Island catch/miss leftover:** paddle hitbox radius + vertical band scale with spawn `orb.size` (18…26) so mid-size ≈ old 0.13 / 0.09 — larger drawn islands no longer look catchable while slipping past. Paddle run / reaction path untouched.
- Sims: typecheck OK; missing-return 0; islandlook + decay ALL OK. Island schedule / pushType untouched.

## Recent eng (prior tips)

- `d21192f` — Island careCrop; Food/Play ink cells; Hit Island orb size
- `2b6655e` — Scenes hub ink stroke; Hit Island timer cream stroke
- `01d2bc2` — Grow/Meet Pip cream chrome; Pets sleep-breath + PressScale
- `7ca89b9` — Sleep-breath widgets/Island; care alias frame counts; dock/ribbon PressScale
- `47be37c`…`874c30e` — scoot/Pip/StatusStrip, favorites/soap, bath unlock, Island rename — see prior handoff

## Still-open polish (if next session)

- Confirm on device: Onboarding name field + card ink stroke (no white fill); Meet Pip blurb ink; Settings blocks ink; Photo polaroid still white.
- Confirm Hit Island: larger islands catch more easily / smaller tighter; paddle run + catch/miss happy/sad still feel right.
- Confirm on device: Island careCrop / Food-Play ink / Hit Island orb size from `d21192f`.
- Confirm Scenes / Grow / Pets sleep-breath / dock PressScale from prior tips.
- Shop / Inventory / Pets unselected cards still use beige cell borders — cream ink pass only if App Lead asks.
- Wand leftover jank if any remains after denser lure — no wand change this tip.
- Wet→shake + yawn-before-nap already wired with shipped sheets — no new invent.
- Device confirms from older handoff still apply (rename Island restart, Sleep→Wake→Feed, projected flips, kit one-size, etc.).
- Do **not** chase ActivityKit pushType / suspended flip delivery — parked.
- No new PNGs / floaters / DONE. Eng never DONE.

## Gate

App Lead compares home + Island to Shimeji reference. Reviewer quality only after that gate.

## Eng status

Tip past `d21192f` on `main` (this push). Onboarding/Meet Pip/Settings cream ink; Hit Island size-scaled catch. Shared typecheck OK; sims OK. SwiftUI/ActivityKit not compiled for real here (Linux stubs) — confirm on Mac. **Not DONE.**

**Waiting on**
1. App Lead: compare a running build on a device or Mac against Shimeji for DONE (Eng does not call DONE).
2. App Lead: confirm Onboarding/Settings/Meet Pip cream ink + Hit Island catch feel on device.
