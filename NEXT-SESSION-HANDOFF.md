# Next-session handoff — Live Pet (Eng continuous rebuild)

**Date:** 2026-10-05 (MT)  
**Repo:** https://github.com/barrylin0404-code/live-pet  
**`main` tip (this ship):** Island careCrop (hungry/sad feet); Food/Play ink cells; Hit Island orb size (on tip past `2b6655e` Scenes hub + Hit Island timer cream)

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

- **Island compact care/hungry/sad crop:** `IslandWalkPetView.careCrop` (taller/wider than stroll `walkCrop`) so nubby sad feet (y≈59) and hungry ear tip (x≈63), plus pip bath/sleep feet, stay in the pill. Stroll / parked idle still use `walkCrop`. Feed/Pet settle path unchanged (prior tips).
- **Food/Play cream consistency:** Select Food cells + Play game rows drop leftover beige `E8D4C4` for ink stroke `4A3F35` (clear fills kept; favorite gold unchanged). Matches Scenes hub / Food outer chrome.
- **Hit Island leftover jank:** Falling island orbs honor spawn `size` (draw ~2× → ~36–52px) instead of a fixed 48 — paddle catch/miss path untouched.
- Sims: typecheck OK; missing-return 0; islandlook (careCrop asserts) / roam / carehold OK.

## Recent eng (prior tips)

- `2b6655e` — Scenes hub ink stroke; Hit Island timer cream stroke
- `01d2bc2` — Grow/Meet Pip cream chrome; Pets sleep-breath + PressScale
- `7ca89b9` — Sleep-breath widgets/Island; care alias frame counts; dock/ribbon PressScale
- `47be37c` — Playful scoot→play; Pip idle variety; StatusStrip happy one-shot
- `b2a3422`…`874c30e` — favorites/soap, bath unlock, Island rename — see prior handoff detail

## Still-open polish (if next session)

- Confirm on device: Island hungry/sad/eat/play/bath/sleep fill the compact/Lock pill with feet on the floor (no sad foot clip).
- Confirm Food/Play sheets: cell/row ink stroke on cream; favorites still gold.
- Confirm Hit Island: island sizes vary slightly; catch/miss + paddle run still feel right.
- Confirm on device: Scenes StatusStrip + cards / Hit Island timer cream from `2b6655e`.
- Confirm Grow / Meet Pip / Pets sleep-breath / dock PressScale from prior tips.
- Wand leftover jank if any remains after `914ec4f` / denser lure — no new wand change this tip.
- Wet→shake + yawn-before-nap already wired with shipped sheets — no new invent.
- Shop / Inventory / Pets unselected cards still use beige cell borders — cream ink pass only if App Lead asks (Food/Play done this tip).
- Device confirms from older handoff still apply (rename Island restart, Sleep→Wake→Feed, projected flips, kit one-size, etc.).
- Do **not** chase ActivityKit pushType / suspended flip delivery — parked.
- No new PNGs / floaters / DONE. Eng never DONE.

## Gate

App Lead compares home + Island to Shimeji reference. Reviewer quality only after that gate.

## Eng status

Tip past `2b6655e` on `main` (this push). Island careCrop; Food/Play ink cells; Hit Island orb size. Shared typecheck OK; sims OK. SwiftUI/ActivityKit not compiled for real here (Linux stubs) — confirm on Mac. **Not DONE.**

**Waiting on**
1. App Lead: compare a running build on a device or Mac against Shimeji for DONE (Eng does not call DONE).
2. App Lead: confirm Island care crop + Food/Play ink cells + Hit Island orb sizes on device.
