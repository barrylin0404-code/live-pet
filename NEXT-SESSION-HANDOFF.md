# Next-session handoff — Live Pet (Eng continuous rebuild)

**Date:** 2026-10-05 (MT)  
**Repo:** https://github.com/barrylin0404-code/live-pet  
**`main` tip (this ship):** Grow/Meet Pip/Pets cream chrome + Pets sleep-breath (on tip past `7ca89b9` sleep-breath widgets/Island + care alias clips + dock PressScale)

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

- **Grow / Meet Pip leftover chrome:** Dropped Grow’s forever scale pulse (happy sheet alone — matches Meet Pip). Both sheets now use the same cream presentation as Pets/Scenes (`presentationDetents` medium+large, drag indicator, corner radius 24) — no system-default sheet chrome leftover.
- **Pets sheet leftover:** “Use this pet” capsule wires `PressScaleButtonStyle` (was plain while cards already scaled). Napping / mood cards use `WidgetMoodClip` (sleep-breath + happy one-shot) instead of frozen `.sleeping` / idle — same path as StatusStrip / Home widgets after `7ca89b9`.
- Island schedule / moodFlips / pushType untouched. Care aliases / dock PressScale / stageSheetsMatchSideView untouched.
- Sims: typecheck OK; missing-return 0; islandlook / roam / carehold / food OK.

## Recent eng (prior tips)

- `7ca89b9` — Sleep-breath widgets/Island; care alias frame counts; dock/ribbon PressScale
- `47be37c` — Playful scoot→play; Pip idle variety; StatusStrip happy one-shot
- `b2a3422` — Shop/Inventory favorites-first + soap; Pets/Meet Pip polish; denser lure
- `4da04a3` — Fix bath cut short on Grow/Hit Island; denser roam; toy Feeling session
- `0528154` — Wire prop-soap and kit/plus walks; drop dead room Canvas
- `0a0978e`…`874c30e` — careBusy unlock from care finish; Island rename/switch Activity restart — see prior handoff.bak detail

## Still-open polish (if next session)

- Confirm on device: Grow / Meet Pip sheets match Pets cream detents + corner; Grow no longer pulses scale.
- Confirm Pets cards: napping pet breathes (sleep→sleepBreathing); happy/playful one-shot then idle; Use this pet press-scales.
- Confirm on device: napping pet on Home / companion / Island / Lock / StatusStrip shows sleeping then sleepBreathing (not frozen sleeping or idle fallback).
- Confirm eatNotice glance + bathStart→…→bathHappy still pace right with corrected frame counts.
- Confirm dock + ribbon press scale feel; haptics still one tick per tap.
- Confirm Hit Island / wand leftover jank if any remains after `4da04a3` / `1f43011`.
- Device confirms from older handoff still apply (rename Island restart, Sleep→Wake→Feed, projected flips, Feed/Pet settle, kit one-size, etc.).
- Do **not** chase ActivityKit pushType / suspended flip delivery — parked.
- No new PNGs / floaters / DONE. Eng never DONE.

## Gate

App Lead compares home + Island to Shimeji reference. Reviewer quality only after that gate.

## Eng status

Tip past `7ca89b9` on `main` (this push). Grow/Meet Pip cream chrome + Pets sleep-breath / PressScale. Shared typecheck OK; sims OK. SwiftUI/ActivityKit not compiled for real here (Linux stubs) — confirm on Mac. **Not DONE.**

**Waiting on**
1. App Lead: compare a running build on a device or Mac against Shimeji for DONE (Eng does not call DONE).
2. App Lead: confirm Grow/Meet Pip sheet chrome + Pets nap breath / Use press-scale on device.
