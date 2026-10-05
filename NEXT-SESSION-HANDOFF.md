# Next-session handoff — Live Pet (Eng continuous rebuild)

**Date:** 2026-10-05 (MT)  
**Repo:** https://github.com/barrylin0404-code/live-pet  
**`main` tip (this ship):** Scenes hub + StatusStrip ink stroke; Hit Island timer cream stroke (on tip past `01d2bc2` Grow/Meet Pip cream + Pets sleep-breath)

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

- **Scenes hub cream consistency:** StatusStrip + Scenes scene cards / Island toggle / link rows drop leftover beige `E8D4C4` borders for ink stroke `4A3F35` (clear fills kept). Selected scene stays coral accent. Matches App Lead cream + ink stroke lock (Food outer chrome / Hit Island cards).
- **Hit Island leftover chrome:** Game timer capsule gets the same ink stroke over cream (intro/result cards already had it).
- Grow/Meet Pip / Pets / care aliases / dock PressScale / stageSheetsMatchSideView / Island schedule untouched.
- Sims: typecheck OK; missing-return 0; islandlook / roam / carehold OK.

## Recent eng (prior tips)

- `01d2bc2` — Grow/Meet Pip cream chrome; Pets sleep-breath + PressScale
- `7ca89b9` — Sleep-breath widgets/Island; care alias frame counts; dock/ribbon PressScale
- `47be37c` — Playful scoot→play; Pip idle variety; StatusStrip happy one-shot
- `b2a3422` — Shop/Inventory favorites-first + soap; Pets/Meet Pip polish; denser lure
- `4da04a3` — Fix bath cut short on Grow/Hit Island; denser roam; toy Feeling session
- `0528154`…`874c30e` — prop-soap / kit walks; careBusy unlock; Island rename — see prior handoff.bak detail

## Still-open polish (if next session)

- Confirm on device: Scenes StatusStrip + cards / toggle / links read as ink stroke on cream (no beige leftover); selected scene still coral.
- Confirm Hit Island timer capsule matches intro/result ink stroke.
- Confirm on device: Grow / Meet Pip sheets match Pets cream detents + corner; Grow no longer pulses scale.
- Confirm Pets cards: napping pet breathes; happy/playful one-shot then idle; Use this pet press-scales.
- Confirm eatNotice glance + bathStart→…→bathHappy still pace right with corrected frame counts.
- Confirm dock + ribbon press scale feel; haptics still one tick per tap.
- Confirm Island compact care/hungry/sad + Feed/Pet settle if any leftover remains after prior tips.
- Confirm Wand leftover jank if any remains after `914ec4f` / denser lure.
- Shop / Inventory / Pets unselected cards still use beige cell borders — cream ink pass only if App Lead asks (Scenes hub done this tip).
- Device confirms from older handoff still apply (rename Island restart, Sleep→Wake→Feed, projected flips, kit one-size, etc.).
- Do **not** chase ActivityKit pushType / suspended flip delivery — parked.
- No new PNGs / floaters / DONE. Eng never DONE.

## Gate

App Lead compares home + Island to Shimeji reference. Reviewer quality only after that gate.

## Eng status

Tip past `01d2bc2` on `main` (this push). Scenes hub + StatusStrip ink stroke; Hit Island timer cream stroke. Shared typecheck OK; sims OK. SwiftUI/ActivityKit not compiled for real here (Linux stubs) — confirm on Mac. **Not DONE.**

**Waiting on**
1. App Lead: compare a running build on a device or Mac against Shimeji for DONE (Eng does not call DONE).
2. App Lead: confirm Scenes ink stroke + Hit Island timer chrome on device.
