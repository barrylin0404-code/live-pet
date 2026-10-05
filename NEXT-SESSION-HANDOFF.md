# Next-session handoff — Live Pet (Eng continuous rebuild)

**Date:** 2026-10-05 (MT)  
**Repo:** https://github.com/barrylin0404-code/live-pet  
**`main` tip (pushed):** handoff on `3fb63ce` Island Feed/Pet mid-return settle + happy densify (on `d4ec745` / `a8c2979`)

## Product locks

- Shimeji = quality bar only. Original Nubby + Pip. Free forever — no IAP / Upgrade / Unlock.
- App Lead alone says DONE after comparing a running build to the reference. Eng does not call DONE or offer a test build.
- No care floaters (hearts/stars/Zzz/bubbles/crumbs). Care = sheets.
- Feeling/Satiety: StatusStrip on Scenes (More), not cream capsule on the room plate.
- Do not invent bathStart/sleepStart sheets — aliases stay. Rare stays on idle.
- `ClipPetView.stageSheetsMatchSideView` stays **TRUE** (App Lead cleared).
- Cream sheets with ink stroke only (no white card fills — App Lead). Original assets only.

## Recent eng

- `3fb63ce` — Island Feed/Pet settle + happy densify leftover toward Shimeji bar. **Island settle:** `centeredWalkEpoch` was mid-outbound (legProgress 0.5) — inside the outbound-only hop window (0.3…0.8), so Feed/Pet/bath handback could appear mid-squash on expanded / Lock. Now mid-return (xNorm 0, facing left, no hop) via mood-aware pause. **Happy densify:** Island edge park 0.65 (between playful 0.45 and content 0.9) on shared `PetMood.islandEdgePause`; room `chooseNextHappy` more walks/hops, no loaf (existing clips). **Accessory:** Widgets gallery + Settings tip mention Lock Screen mono; Home widget a11y uses pet name. Island schedule / pushType untouched. Typecheck OK; missing-return 0; islandlook + carehold + roam + decay ALL OK. Eng continuous — not DONE.

- `d4ec745` — Sleep→wake / cream leftover toward Shimeji bar. **Sleepy-awake:** `WidgetMoodClip` yawns then idles (shipped `idleYawn`) instead of freezing on sleeping — widgets / StatusStrip / Pets matched room yawn + Island stroll after Wake / low energy; real naps still `PetSleepClip`. **Grow:** celebration pet+name clear fill + ink `4A3F35` stroke card (Meet Pip parity). **Accessory:** gallery copy pet-agnostic (plus mono path unchanged). Island schedule / pushType untouched. Typecheck OK; missing-return 0; islandlook (sleepy-awake) + carehold + roam ALL OK. Eng continuous — not DONE.

- `4679619` — Island careCrop leftover toward Shimeji bar. **Compact careCrop:** measured play/bath/sleep sheet tops sat above the old crop (nubby play y≈8 / bath–sleep y≈12; pip play–sleep y≈16 / bath y≈18) while crop started at 14/20 — clipped hop/bath crowns once `.clean` passed through on Island. Nubby `(8,8,56,56)` + pip `(16,16,44,48)` cover tops and keep hungry ear / sleep feet; stroll `walkCrop` unchanged. **fromMoodHold:** exclude `.clean` like eat/play/sleep after clean pass-through. Island schedule / pushType untouched. Typecheck OK; missing-return 0; islandlook + carehold + roam ALL OK. Eng continuous — not DONE.

- `5fdd889` — Island / Hit Island leftover toward Shimeji bar. **Island clean:** `islandContentState` keeps `.clean` (was remapped to walk with idle — in-app bath never showed bathing on Island / Lock; `IslandWalkPetView` + `islandUpdate` already supported clean→walk recenter). **Hit Island miss feel:** miss squash bump (0.94) + soft haptic alongside sad + uiTick (catch still pop 1.06 + rigid). Island schedule / pushType untouched. Typecheck OK; missing-return 0; islandlook + carehold + roam ALL OK. Eng continuous — not DONE.

- `a5012f8` — Wand / cream leftover toward Shimeji bar. **Wand / Soft Square:** `trackLure` far-run no longer `force: true` every lure tick (was stuck on run frame 0); matches walk/play `force: anim !=`. **Cream ink:** Shop, Inventory sheet, Pets unselected/locked cards, Widgets gallery, ribbon cells beige `E8D4C4` → ink `4A3F35` (favorites gold unchanged; Photo polaroid white). Island schedule / pushType untouched. Typecheck OK; missing-return 0; roam + carehold ALL OK. Eng continuous — not DONE.

- `3c5ec89` — Cream + Hit Island catch leftover toward Shimeji bar. **Onboarding:** name field clear fill + ink stroke (was white + beige); outer card ink 2.5. **Meet Pip** blurb + **Settings** blocks (Photo/rename) beige → ink `4A3F35`. Pet Photo polaroid stays white. **Hit Island:** catch radius + band scale with `orb.size` (mid ≈ old 0.13/0.09). Island schedule / pushType untouched. Typecheck OK; missing-return 0; islandlook + decay ALL OK. Eng continuous — not DONE.

- `47be37c` — Autonomous roam + Scenes strip polish toward Shimeji density. **Playful scoot handoff:** after a playful scoot parks, next beat is hop/playing (never scoot→scoot chains). **Pip idle variety:** `PetBrain.tick(..., speciesId:)` — Pip parks shorter (×0.82), walks/runs more, sniff/curious + pant-breath + hop favored; groom/loaf rare. Nubby idle weights unchanged (blink/groom/look). **StatusStrip** happy/playful uses `WidgetMoodClip` one-shot then idle (same as Home widgets — no looping bounce on Scenes). Mood overload shared. Island schedule / pushType untouched. Sims: roam ALL OK; islandlook + carehold + decay + food OK; typecheck OK; missing-return 0. Eng continuous — not DONE.

- `b2a3422` — Shop / Inventory / ribbon favorites-first consistency: Shop foods + toy rows lead with favorites (wand / Island after toys). Inventory lists Bubble Soap with bath via `onClean`; ribbon + Inventory show soap ×∞ (never depletes). Pets sheet: uiTick on card/Done, meow on switch, ink names, dim locked Pip. Meet Pip celebrates on happy sheet (existing art). Wand / Soft Square `PetBrain.trackLure` (run far / play close / walk mid); Ball / Bounce run in when drop is far. Food fail-safe mirrors toy (`careBusy` + pending id). Island schedule / pushType untouched. Carehold sim ALL OK; typecheck OK; missing-return 0. Eng continuous — not DONE.

- `4da04a3` — Bath cut short on Grow dismiss / Hit Island finish: `releaseBathOrSleepHoldForOverlay` cancels a live bath/sleep care hold + `PetBrain.abortBathIfNeeded` (no orphan bathReady); `reactGrown` / `reactPlayResult` gated on `isBusyWithCare` so they cannot cut the chain. Soft Square / Bounce / Ball Feeling once via `toySessionGeneration` (pet-switch retires lure Tasks — no late `careBusy = false` / double Feeling). Roam denser blink/look/curious (existing clips); Meadow `roamIdleHold` 0.72. Hit Island real drag cuts catch/miss beat so run-with-drag resumes. Island schedule / pushType untouched. Sim carehold extended (overlay abort + gated reacts). Typecheck OK; missing-return 0. Eng continuous — not DONE.

- `0528154` — Designer `prop-soap` → `bubble_soap` (Assets app+widget; soap never depletes; bath still dock ctrl-bath / ribbon care tap). Kit + plus walkLeft/walkRight ×6 ingested (App Lead cleared; left drawn — no second flip). `ClipPetView.stageAssetName` + Island stroll use stage walks/idle at stage size (`stageSheetsMatchSideView` TRUE). Dead RoomSceneView Canvas furniture/meadow draw helpers removed — plates only. Eng continuous — not DONE.

- `0a0978e` — Bath / Sleep no longer unlock other care on blind timers (5s / 1.6s). `PetBrain.bathReady` fires on bathHappy→idle; `sleepSettleReady` fires when sleepStart settles into sleeping (~0.35s). `ContentView` clears `careBusy` via `consumeBathReady` / `consumeSleepSettleReady`, with a generation-gated fail-safe only if ready never fires. Wake (`performSleep` / `wakeFromNapIfNeeded`) and pet switch (`resetBrainForPetSwitch`) call `cancelCareHold` so an orphaned timer cannot clear `careBusy` mid food/toy walk after Sleep→Wake or a mid-bath switch. Mid-care tap gate (`isBusyWithCare`) unchanged — soft purr only. Island schedule / moodFlips / pushType untouched. Sim: `/workspace/.toolchains/sim/carehold/` (token races + bathReady @ ~4s with 0 mid-bath taps + sleepSettle before 1.6s + Wake clears settle).
- `874c30e` — Island follows a rename or Nubby↔Pip switch. `PetActivityAttributes` (petName / petGlyph) are immutable, but rename (`PetStore.rename` → commit → onPetChange) and pet switch (setActivePet / Meet Pip → onPetChange + onChange(petGlyph) syncActivity) only sent `Activity.update`: expanded center + Lock banner kept the old name, and `IslandLook`'s `saved.name == petName` guard failed so hungry/sad/wake projection + care blurb stopped for the new pet (blurb used old name). `PetLiveActivityManager.update` / `syncOnBecomeActive` now end→request when `attributesMatch` fails. `requestInFlight` lets one end→request run at a time, so back-to-back onPetChange + syncActivity (and the existing renewIfNeeded + update pair at 7h) cannot request a duplicate Activity. Schedule / moodFlips / pushType untouched (still `pushType: nil`). Sim: `/workspace/.toolchains/sim/activityid/run.sh` (manager compiled against ActivityKit/Combine stubs) — rename → 1 fresh Activity with new name; Nubby→Pip with 3 back-to-back calls → exactly 1 new Activity; matching foreground → no restart. Pre-fix code fails 4/7 there.
- `478664c` — Island / Lock care blurb ages with the clock: care line holds ~60s (`IslandCareCopy.careHoldSeconds`, same window as `blurbTicks >= 3`), then hungry / needs care / hanging out; leftover "tucked in" / "is sleeping" while awake clears to hanging out. Fallback is hanging out (not `mood.label`) so the banner mood word stays the only Content/Happy/Playful label. Plus Lock circular no longer asks for missing `lock-nubby-plus-mono-compact` — uses shipped `lock-nubby-plus-mono` (no new art). App Lead: park further Island schedule / pushType work — sparsity at `db2cde9` stands. Compact 36pt crop + kit/plus stageFit + walkEpoch intent merge audited solid; left alone.
- `db2cde9` — Island mood advances without expand/lock when the main app can still run a Task: `PetSnapshot.moodFlips` (flip-only, ≤4 / 2h, same 90 s boundaries as widget timeline — never the 15-min step grid). `PetLiveActivityManager` arms `Activity.update` at those times on start / update / foreground sync, writing projected pose + recentered `walkEpoch` via `islandContentState`. Skips care oneshots and no-op band matches. **Residual:** no ActivityKit push token (`pushType: nil`); a fully suspended app will not fire flips until it wakes — schedule is re-armed on next foreground. Lock Screen banner now shows `look.mood.label` under the name (same mood word as expanded center). Hungry/sad→stroll recenter (`386b682`) unchanged. App Lead: flips OK only if cheap/sparse — this path is.
- `386b682` — Projected hungry/sad → stroll no longer teleports onto the old roam phase. `IslandLook` recenters `walkEpoch` when Activity moodBand still holds (hungry/low) but the App Group projection is stroll-capable (snapshot ahead of Activity, no write yet) — same centered epoch as care→walk / projected wake. Also recenters when stale Activity band vs projected mood changes edge-park length (playful 0.45 ↔ content 0.9 ↔ sleepy 1.4) so compact / Lock Screen do not jump. `islandUpdate` recenters on hungry/sad → stroll writes; walk→walk content ticks still preserve epoch. `PetMood.holdsIslandStroll` shared helper. Hungry/sad hold, sleepy no-hop, edge-park, widget happy one-shot unchanged. Decay alone cannot raise meters — recovery path is snapshot-ahead-of-Activity (or a later write).
- `991c612` — Island care→walk sideways jump fixed. `ContentState.walkEpoch` (optional Double) is the roam clock origin. `islandUpdate(from:previous:)` stamps a centered epoch (mid outbound leg → xNorm 0) when Activity pose leaves eat/play/clean/sleep for walk; walk→walk keeps the prior epoch so mood ticks do not re-center. `IslandWalkPetView` strolls with `t - walkEpoch` (nil = legacy wall clock). Manager + Island intents both merge via `islandUpdate`. Projected wake (IslandLook) also recenters. Hungry/sad hold unchanged.
- `b3b30e2` — `IslandLook` (PetLiveActivity.swift): Island / Lock Screen read the App Group snapshot projected to now when it is this pet (name + species match), so hungry/sad sheets, mood label, Sleep/Wake label, and blurb ("<name> is hungry" / "needs care" / "woke up") follow the clock with the app closed. Eat/play/bath pass through; snapshot nap state is trusted only when it agrees with the Activity. Island walk hop locked to the walk leg (outbound leg, starts 30% in, lands before the park; sleepy/hungry/low never hop) — was a free 2.75 s clock that could be cut mid-air by the park. Intents push `islandContentState()` like the app.
- `81b8f5b` — `PetDecay` (Pet.swift) shared by `Pet.applyOfflineDecay` + `PetSnapshot.projected`: a napping pet wakes at 95 energy, then decays awake for the rest (sleep used to freeze Satiety/Feeling for the whole absence). Short wake → "<name> woke up". `projectedTimeline` adds entries at the exact 90 s unit where band/nap flips. `WidgetMoodClip`: Home + companion widgets play one happy beat then idle (~3 s cycle) instead of looping the one-shot happy sheet. **Balance note:** a pet left asleep overnight now wakes hungry/low on launch (matches in-app ticks).
- Sims: `/workspace/.toolchains/sim/decay/run.sh` (PetDecay + timeline + moodFlips, links Linux-stubbed AppGroup.swift); `/workspace/.toolchains/sim/islandlook/` (WidgetMoodClip + IslandLook + hop extraction); `/workspace/.toolchains/sim/carehold/` (careBusy generation + bathReady / sleepSettleReady); `/workspace/.toolchains/sim/roam/` (playful scoot handoff + Pip vs Nubby idle weights).
- `9ed52b4` — Mood fidelity polish: Island care/hungry/sad sheets crop to the walk window (compact feet match stroll; kit/plus stageFit only inside ClipPetView). Widgets use `PetSnapshot.projectedTimeline` (~15 min × 2h) so absence flips hungry/sad/happy without opening the app. Grow Done/Back/swipe → meow; Meet Pip / Skip → PetSound. Care blurb holds ~1 min (`blurbTicks >= 3`). Sleepy pets yawn/stretch at the rest spot before tuck.
- `6e58020` — Island walk is no longer a triangle-wave slider. Walk ~1s, park on the idle sheet (mood-sized: playful 0.45 / content 0.9 / sleepy 1.4), keep facing, turn, walk back. Hops only while walking. `parkedIdle` crops the full 64-px idle into the widget walk-crop window so feet match. Hungry/low still hold hungry/sad instead of the stroll.
- `982724b` — `IslandWalkPetView.walkBody` is a plain getter with several `let`s then `TimelineView` and no `return`. Not a ViewBuilder → Xcode "missing return in getter". Linux `swiftc -typecheck` misses it; SIL catches it. Scan: `/workspace/.toolchains/scan-missing-return.py` (flags 0 now).
- `1f43011` — Hit the Island paddle pet runs `runLeft`/`runRight` the way you drag (12 fps), faces last direction when still, then playing. Catch/miss happy/sad still win; jitter under 0.4% ignored.
- `8ce1cc4` — Mid-bath / mid-meal / mid-toy taps no longer cut the care short. `PetBrain.isBusyWithCare` gates `reactPet` / `reactGrab` / `reactDoubleTap`. Soft purr + haptic only; no Feeling / pose / blurb change. Sim: bath chain survives taps every 0.3s; food eats once with 0 eat restarts.
- `fc0c62c` — Kit / Big Nubby idle sheets are drawn at stage size. Walk/eat/happy fall back to adult Nubby. `ClipPetView` applies `bodyScaleMultiplier` only on adult clips, feet-anchored (y 56/64). Room / Island care / Hit Island / WidgetPetForeground drop their extra scale. Island walk hop squash scales toward `.bottom`.
- `81a5d6d` — Widget catalog was missing hungry/sad/happy (Island + home widget fell back to frozen idle). Also had old cropped kit/plus frames and only 4/6 idle (2/4 plus sleep). Copied cleared side-view sheets from the app catalog. No new art.
- `e429eb8` — `Pet.tick` no longer writes "<name> is hanging out" every 20s. A care line holds ~40–60s (`blurbTicks`). Hungry / low say so.
- `3df2f36` — Care fail-safes sized to the real walk at room pace (`careFailSafeNanos`, never under 5.2s). Fail-safe fires → `abandonFood` / `abandonToy`.
- `dbd8d87` — `PetRoomScene.restXFraction`: tired pets nap at each plate's own spot. `PetBrain.tick(restX:)`.
- `fe4c12d` — After Hit the Island, room pet plays happy/sad ~0.45s after cover dismisses.
- `914ec4f` — Undriven walk/run/playing loops hand back to idle; lure finish plays one happy sheet.
- `a4b1d46` — Wand → `playWand` / `chaseWand` ("Chased the wand!"); soap never depletes; favorites-first defaults.
- Box Linux Swift 6.1.2: `/workspace/.toolchains/typecheck-shared.sh` + sims in `/workspace/.toolchains/sim/` (`build.sh <dir>`). Not an app build.

## Designer props wired (verify on device)

| Prop | Reachable via |
|------|----------------|
| fish berry biscuit cupcake cherries sprout | Ribbon, Food sheet, Shop, Inventory |
| ball | Ribbon (Twinkle Ball), Play sheet, Shop |
| soft / bounce | Ribbon, Inventory, Shop |
| wand / island | Play sheet, Shop |
| star | Favorite badge (Food / Inventory / ribbon / Shop) |
| bubble_soap | Ribbon (prop-soap) + bath dock ctrl-bath — soap never depletes |

## Designer ask

- Side-view kit/plus idle+sleep (note 39) + walks (note 40) + `prop-soap` **landed**. Flag stays true. Widget catalog matches walks×6 per dir.

## Still-open polish (if next session)

- Confirm on device: Little Nubby / Big Nubby walk with their own sheets (not adult scaled); left walk faces left (no mirror); Island compact stroll matches room size.
- Confirm on device: Bubble Soap shows prop-soap on ribbon / Inventory; tap still baths via dock path; quantity never hits 0.
- Confirm room plates only — no leftover Canvas furniture chrome under/over the plate.
- Confirm on device: rename the pet (Settings) with Island on → Island briefly restarts (islandStart chime) and expanded / Lock show the new name; Nubby↔Pip switch → one Activity (not two), Pip name + sheets; hungry/sad projection still follows the clock for the new pet with the app closed.
- Confirm on device: Sleep → immediate Wake → Feed/toy drop works (no leftover settle lock); mid-bath pet switch then food walk is not unlocked by an orphaned bath timer; bath still gates taps (soft purr) through bathHappy.
- Confirm on device: after leaving the app (process still briefly alive), Island turns hungry/sad / wakes at the projected flip without expand or lock/unlock; Lock Screen shows the mood word under the name.
- Confirm residual: overnight / fully suspended — Island mood may stay stale until next foreground (no push); widgets still flip via `projectedTimeline`.
- Confirm on device: Island stroll hop lands before the edge park and sleepy pets do not hop; playful still feels lively (shorter park, same hop count).
- Confirm Home/companion happy pet: one happy beat then idle blinks, not a nonstop bounce.
- Confirm Scenes StatusStrip happy/playful: one happy beat then idle (same as widgets) — not looping bounce.
- Confirm Pip roam feels dog-eager vs Nubby cat (more walks/hops/sniff/pant; less groom/loaf); playful scoot always hands off to hop/play.
- Confirm a pet tucked in for hours wakes with decayed Satiety/Feeling (App Lead: OK with the balance?).
- Confirm on device: Island Feed/Pet/bath (~2.4s) returns to stroll at the care pose's x (no ~12–14 pt sideways jump on expanded / Lock); in-app bath shows bathing on Island; hungry/sad still hold; sleepy no hop; edge-park idle unchanged.
- Confirm on device: if snapshot recovers while Activity band is still hungry/low (or playful vs projected content park mismatch), Island/Lock resume stroll at x=0 — no jump onto the old roam phase.
- Soft residual (narrowed): fully suspended app cannot deliver scheduled Activity mood flips without a push token; IslandLook projection still needs a re-render (expand / lock / unlock / Activity.update) when no schedule fired. Snap from stroll into hungry/sad hold (to center) is intentional.
- Confirm on device: Grow Done/Back/swipe meow + Meet Pip / Skip SFX; bath/sleep/feed/stroke + Hit Island miss tick still sound right.
- Confirm Soft Square / Bounce / Ball Feeling bumps **once** per session on device (incl. mid-play ribbon re-tap ignored).
- Confirm Shop / Inventory favorites-first + soap ×∞ / Inventory soap→bath (`b2a3422`) on device; Shop/Inventory/Pets/Widgets/ribbon cells ink stroke (this tip).
- Confirm Pets switch SFX + dim locked Pip; Meet Pip happy sheet; wand run/play density + Ball/Bounce run-in.
- Confirm Hit Island catch Feeling scale + dock Wake a11y + favorites-first ribbon + Meadow idle linger on device.
- Confirm Home + companion widgets flip hungry/sad/happy after long absence (`projectedTimeline` + `81a5d6d` sheets) without opening the app.
- Confirm Island hungry/sad (and eat/play/bath/sleep) fill the compact 36pt slot without clipping play hop / bath crowns; feet matching the walk crop; kit/plus not double-scaled; Feed/Pet returns to walk (~2.4s) or holds hungry/sad.
- Confirm Island edge park: idle blinks, feet stay put, mood pause lengths feel right; compact pill still starts (slotHeight 36).
- Confirm Hit Island paddle runs with drag and faces the last direction when still.
- Confirm a mid-bath tap keeps the bath chain and the "Got a soapy bath" Island blurb.
- Confirm Little Nubby does not shrink when it stops walking (room + Island + widgets).
- Confirm Island expanded / Lock blurb holds a care line ~1 min then hungry / needs care / hanging out (`478664c` IslandCareCopy aging — with app closed, expand/lock re-render).
- Confirm Big Nubby Lock circular accessory shows plus mono (not adult island-compact-crop fallback).
- Do **not** chase ActivityKit pushType / suspended flip delivery — App Lead parked that residual at `db2cde9`.
- Confirm tired-pet rest spots + pre-nap yawn/stretch linger read right on device for each plate (Meadow snappier via idleScale).
- Scenes StatusStrip only for Feeling/Satiety — never room plate meters. Cream ink-stroke only (clear fill + stroke).
- No new PNGs / floaters / DONE.

## Still-open polish (if next session)

- Confirm on device: Little Nubby / Big Nubby walk with their own sheets (not adult scaled); left walk faces left (no mirror); Island compact stroll matches room size.
- Confirm on device: Bubble Soap shows prop-soap on ribbon / Inventory; tap still baths via dock path; quantity never hits 0.
- Confirm room plates only — no leftover Canvas furniture chrome under/over the plate.
- Confirm on device: rename the pet (Settings) with Island on → Island briefly restarts (islandStart chime) and expanded / Lock show the new name; Nubby↔Pip switch → one Activity (not two), Pip name + sheets; hungry/sad projection still follows the clock for the new pet with the app closed.
- Confirm on device: Sleep → immediate Wake → Feed/toy drop works (no leftover settle lock); mid-bath pet switch then food walk is not unlocked by an orphaned bath timer; bath still gates taps (soft purr) through bathHappy.
- Confirm on device: after leaving the app (process still briefly alive), Island turns hungry/sad / wakes at the projected flip without expand or lock/unlock; Lock Screen shows the mood word under the name.
- Confirm residual: overnight / fully suspended — Island mood may stay stale until next foreground (no push); widgets still flip via `projectedTimeline`.
- Confirm on device: Island stroll hop lands before the edge park and sleepy pets do not hop; playful still feels lively (shorter park, same hop count).
- Confirm Home/companion happy pet: one happy beat then idle blinks, not a nonstop bounce.
- Confirm Scenes StatusStrip happy/playful: one happy beat then idle (same as widgets) — not looping bounce.
- Confirm Pip roam feels dog-eager vs Nubby cat (more walks/hops/sniff/pant; less groom/loaf); playful scoot always hands off to hop/play.
- Confirm a pet tucked in for hours wakes with decayed Satiety/Feeling (App Lead: OK with the balance?).
- Confirm on device: Island Feed/Pet/bath (~2.4s) returns to stroll at the care pose's x facing left mid-return (no mid-hop squash, no ~12–14 pt sideways jump on expanded / Lock); in-app bath shows bathing on Island; hungry/sad still hold; sleepy no hop; happy park snappier than content.
- Confirm on device: if snapshot recovers while Activity band is still hungry/low (or playful vs projected content park mismatch), Island/Lock resume stroll at x=0 — no jump onto the old roam phase.
- Soft residual (narrowed): fully suspended app cannot deliver scheduled Activity mood flips without a push token; IslandLook projection still needs a re-render (expand / lock / unlock / Activity.update) when no schedule fired. Snap from stroll into hungry/sad hold (to center) is intentional.
- Confirm on device: Grow Done/Back/swipe meow + Meet Pip / Skip SFX; bath/sleep/feed/stroke + Hit Island miss tick still sound right.
- Confirm Soft Square / Bounce / Ball Feeling bumps **once** per session on device (incl. mid-play ribbon re-tap ignored).
- Confirm Shop / Inventory favorites-first + soap ×∞ / Inventory soap→bath (`b2a3422`) on device; Shop/Inventory/Pets/Widgets/ribbon cells ink stroke (this tip).
- Confirm Pets switch SFX + dim locked Pip; Meet Pip happy sheet; wand run/play density + Ball/Bounce run-in.
- Confirm Hit Island catch Feeling scale + dock Wake a11y + favorites-first ribbon + Meadow idle linger on device.
- Confirm Home + companion widgets flip hungry/sad/happy after long absence (`projectedTimeline` + `81a5d6d` sheets) without opening the app.
- Confirm Island hungry/sad (and eat/play/bath/sleep) fill the compact 36pt slot without clipping play hop / bath crowns; feet matching the walk crop; kit/plus not double-scaled; Feed/Pet returns to walk (~2.4s) or holds hungry/sad.
- Confirm Island edge park: idle blinks, feet stay put, mood pause lengths feel right; compact pill still starts (slotHeight 36).
- Confirm Hit Island paddle runs with drag and faces the last direction when still.
- Confirm a mid-bath tap keeps the bath chain and the "Got a soapy bath" Island blurb.
- Confirm Little Nubby does not shrink when it stops walking (room + Island + widgets).
- Confirm Island expanded / Lock blurb holds a care line ~1 min then hungry / needs care / hanging out (`478664c` IslandCareCopy aging — with app closed, expand/lock re-render).
- Confirm Big Nubby Lock circular accessory shows plus mono (not adult island-compact-crop fallback).
- Confirm on device: happy pets roam denser in-room (more walks/hops, no loaf) and Island happy edge park ~0.65s.
- Confirm Widgets gallery shows Lock Screen row; Settings widget tip mentions Lock Screen Customize.
- Confirm Home widget VoiceOver uses pet name + feeling phrase (not hard-coded Nubby/Pip).
- Do **not** chase ActivityKit pushType / suspended flip delivery — App Lead parked that residual at `db2cde9`.
- Confirm tired-pet rest spots + pre-nap yawn/stretch linger read right on device for each plate (Meadow snappier via idleScale).
- Scenes StatusStrip only for Feeling/Satiety — never room plate meters. Cream ink-stroke only (clear fill + stroke).
- No new PNGs / floaters / DONE.

## Gate

App Lead compares home + Island to Shimeji reference. Reviewer quality only after that gate.

## Eng status (2026-10-05 ~08:30 MT)

Tip on `main` (pushed; code ship `3fb63ce`). Island Feed/Pet mid-return settle (no hop) + happy densify + Lock Screen gallery tip. Typecheck OK; missing-return 0; islandlook + carehold + roam + decay ALL OK. **Island schedule / moodFlips / pushType parked** (untouched). SwiftUI/ActivityKit not really compiled here (Linux stubs). Not DONE.

**Waiting on:** App Lead DONE call after a running build vs Shimeji (Eng does not call DONE; continuous ship — no Mac pause).

**Device confirm only**
- Island Feed/Pet/bath settle: stroll at x=0 facing left, flat walk (not mid-hop squash).
- Happy Island park snappier than content; room happy denser walks/hops.
- Widgets gallery Lock Screen row; Settings Lock tip; Home widget a11y name.
- Sleepy-but-awake Home/companion/StatusStrip/Pets: one yawn then idle blinks (not frozen sleeping); real nap still breathes sleep↔sleepBreathing.
- After Wake with low energy: widgets do not look asleep while room is awake.
- Grow “All grown!”: ink stroke card around happy pet; Meet Pip card still ink; Photo polaroid white.
- Lock accessory gallery copy; Big Nubby circular still plus mono.
- Island care sheets fill compact 36pt (play hop / bath crowns); clean bath pass-through; miss squash + soft haptic.
- Wand far chase run loop; cream ink cells; favorites gold; soap ×∞.
- Playful scoot→hop/play; Pip roam denser; Scenes StatusStrip happy one-shot.
- Sleep → immediate Wake → Feed; bath tap gate; rename Island restart.
