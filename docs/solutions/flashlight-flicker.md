# Flashlight low charge flicker

## Intent

A flashlight that is running out of battery should show it. As the charge drains through 5%, 4%, 3% and 2% the beam flickers once each time: a burst of one to three short partial dips in brightness. In the last percent the flicker is continuous, a strobe that lasts until the light dies. The flicker is a visual cue only. It must not get in the way of using the light.

## Constraints and assumptions

* Lives in VosTac (`likhos-vostac`), next to the rest of its flashlight behaviour. Likho's Battery carries nothing of it.
* A flashlight's charge is the `slotData.condition` of the item in the light equipment slot. Every item in that slot is drained by vanilla `Flashlight.Consumption`, so every light flickers, including lights added by other mods. There is no per-item or per-tier branching and no check for battery compatibility.
* The flicker only dims. The light never goes fully dark before vanilla switches it off at 0%.
* Only `light_energy` changes, on both the `World` spot light and the `FPS` omni light, by the same factor. Range, cone, color and battery drain are untouched.
* Always on. No MCM setting.
* Visual only. No sound and no HUD element.
* Vanilla `Activate` rewrites energy every time it runs, and `ResetCheck` re-runs it every 10 physics frames while the light is on. At the project's 120 physics ticks per second that is one activation every 83 ms. An energy written from anywhere other than the tail of `Activate` is overwritten within 83 ms.
* Dimming must never compound. The dim factor is applied only to an energy vanilla wrote in the same call. When vanilla `Activate` returns early without writing energy, nothing is written.
* The charge only drains while the light is on, and by far less than a whole percent between two activations. The fastest drain, the Phoenix in winter, loses 0.4% per second.
* VosTac already has a post hook on `Flashlight.Activate` that shapes the beam by writing `spot_range` and `spot_angle`, behind a guard for the case where vanilla wrote nothing. The flicker writes `light_energy` only, so the two do not interact.
* VosTac replaces `Flashlight._physics_process` but still calls `ResetCheck` every physics tick, so the activation cadence is the vanilla one.
* Ruled out: bursts at random or accelerating intervals set in seconds. The flicker window scales with the drain rate and is only 12.5 s on the Phoenix in winter, where a gap of several seconds can leave a single burst.
* Ruled out: telling a drain apart from another change in charge that lands exactly one whole percent lower, such as a swapped battery, another light or a loaded save. It plays one stray burst and that does not matter.
* Ruled out: a flicker owned by Likho's Battery. It uses nothing from that mod, and it would need a second handler, hook registration and guard on a method VosTac already hooks.
* Ruled out: the weapon-mounted light driven by `RigManager.gd`. It has no battery.
* Ruled out: NVG. It has a charge but is not a flashlight.
* Ruled out: AI detection. `Sensor.gd` reads `gameData.flashlight` only, so a dimmed beam is detected the same as a full one.
* Assumption, unverified: hooks on `Activate` dispatch for the script's own internal calls from `ResetCheck`. VosTac's beam shape relies on the same behaviour. If internal calls bypass dispatch, the handler does not see the charge drain and the design needs revisiting.
* Assumption, unverified: a dip quantized to 83 ms steps reads as a flicker and not as a stutter.

## Scope

Owned:

* `likhos-vostac/Scripts/Hooks/Flashlight.gd`. The `Activate` post hook handler: the flicker, after the beam shaping it already does. The beam shaping and the `_physics_process` replacement in the same file stay as they are.
* `likhos-vostac/README.md`. The Flashlights section.
* `likhos-vostac/CHANGELOG.md`. The release note.
* `likhos-battery/`: `Scripts/`, `mod.txt`, `README.md` and `CHANGELOG.md`. They hold no flashlight handler, no hook on `Flashlight.gd` and no mention of the flicker.

Context only, not modified:

* `src/Scripts/Flashlight.gd`. Supplies `Activate`, `ResetCheck`, `lightSlot` and the two lights.
* `likhos-vostac/Scripts/Main.gd` and `likhos-vostac/mod.txt`. Already register and declare the `Activate` post hook.

## Solution

### Tunables

| tunable | value |
|---|---|
| charge threshold | 5% |
| burst points | the threshold and every whole percent below it down to the continuous phase: 5%, 4%, 3%, 2% |
| continuous phase | at or below 1% |
| dim factor during a dip | random, 0.3 to 0.7 |
| dips in a burst | 1 to 3 |
| dip length | 1 or 2 activation intervals, about 0.08 to 0.17 s |
| pause before each dip | 1 or 2 activation intervals, about 0.08 to 0.17 s |

These are starting values to be confirmed in game. The number of dips, each dip length and each pause are picked at random per burst, so a burst lasts up to about 1 s. Every dip is preceded by its pause, so bursts that follow each other directly in the continuous phase form one unbroken strobe of dips and pauses. The dim factor is picked at random for every dimmed activation and applied to both lights, so dips differ in depth and a dip two intervals long can step between two levels.

### Timing

The gap between two bursts is the time one percent of charge lasts, which follows from the vanilla drain rate. The continuous phase covers the last percent, so it lasts exactly one gap.

| light | gap and continuous phase | in winter |
|---|---|---|
| Narva | 20 s | 10 s |
| Polaris | 10 s | 5 s |
| Phoenix | 5 s | 2.5 s |

### Hook

The flicker runs in VosTac's existing post hook on `Flashlight.Activate`, handled in `Hooks/Flashlight.gd`. Vanilla `Activate` runs first and writes the equipped light's full energy on both lights. The post hook shapes the beam as before, then decides whether the light is inside a dip and, if it is, multiplies both energies by the dim factor. The guard that stops the beam shaping when vanilla wrote nothing stops the flicker too.

The handler keeps two things between activations: the whole percent the charge was last seen at, and the pattern of dips and pauses left in the running burst. It has no node, no per-frame processing, no timer and no hook on `_physics_process`.

* A burst starts when the charge has drained from one whole percent into the next one down and the new one is at or below the threshold. The burst is laid out in full at that moment and then consumed one activation at a time. Inside a dip the energy is dimmed. In a pause and outside a burst vanilla's energy stands.
* A step down of exactly one whole percent is what draining looks like, and it is the only thing that starts a burst. A charge that is first seen already below the threshold, or that lands more than one whole percent lower because the battery was swapped or another light was equipped, starts nothing. The next burst comes when the charge drains through the next whole percent. A swap that lands exactly one whole percent lower is taken for a drain and plays one burst.
* In the continuous phase a new burst starts on the first activation after the previous one ends, for as long as the charge is at or below 1%. This phase depends on the charge alone and not on draining into it, so a light switched on with less than 1% left strobes from its first activation.
* Because the charge drains only while the light is on, so does the flicker. Switching the light off and on changes nothing, except that a burst cut short by switching off finishes at the next switch-on.

No restore step exists. Vanilla rewrites the full energy on the next activation, and `Deactivate` zeroes it.

### Flow

1. The light is on. Every 10 physics frames `ResetCheck` calls `Activate`, vanilla writes full energy and the post hook runs.
2. Charge is above 5%. The hook leaves the energy alone.
3. Charge drains through 5%. A burst starts: the hook lets vanilla's full energy stand for one or two activations, then dims both lights by a random factor for one or two, and repeats for up to three dips.
4. Charge drains through 4%, 3% and 2%. Each one starts another burst.
5. Charge drains through 1%. Bursts now follow each other without a break and the light strobes.
6. Charge reaches 0%. Vanilla `ResetCheck` deactivates the light.
7. The player charges the light or swaps in another battery. Nothing flickers until the charge next drains through a burst point or is at or below 1%.

### Expected result

* A light above 5% behaves as it does today.
* At 5%, 4%, 3% and 2% the beam and the close-range glow dip together to between 30% and 70% brightness for a moment, one to three times in quick succession.
* Every light gives exactly four warnings on its way from 5% to 1%, in any season. They are 20 s apart on the Narva, 10 s on the Polaris and 5 s on the Phoenix, and half that in winter.
* Each warning marks a whole percent of charge lost.
* From 1% the light strobes without a break until it switches off: 20 s on the Narva, 10 s on the Polaris and 5 s on the Phoenix, and half that in winter.
* Switching a light off and on between 5% and 1% does not flicker by itself. Switching it on below 1% strobes at once.
* The light stays usable throughout. It is never dark until it switches off at 0%.

## Tradeoffs

* **Bursts tied to charge points over bursts on a timer.** Every light gets the same five warnings however fast it drains, and the handler needs no clock, no schedule and no knowledge of the activation cadence beyond the dip length. The cost is that the gaps are even and predictable: the single warnings do not speed up toward empty and do not look random. Only the burst shape and the dim level vary.
* **Continuous flicker in the last percent over a fifth single warning.** The final warning cannot be missed or mistaken for an earlier one. The cost is the most obtrusive part of the feature: up to 20 s of unbroken strobe on the Narva.
* **The activation call as the only tick over a per-frame driver node.** One post hook, no node, no remembered base energy and no dependence on who owns `_physics_process`. The cost is that a dip is quantized to 83 ms steps with hard edges, so smooth fades and shorter blinks are not possible. The cadence comes from vanilla's poll interval and the physics tick rate. A game patch to either makes the dips coarser or finer.
* **A step of one whole percent starts a burst over any drop in charge.** Swapping in a much weaker battery, equipping another light or loading a save does not dim the light, apart from the stray case where the charge lands exactly one whole percent lower. The cost is that a light picked up at 4.5% gives no cue until it reaches 4%, up to 20 s later on the Narva.
* **VosTac over Likho's Battery.** No new file, hook or guard, and one mod writes to the lights after activation. The cost is that players with Likho's Battery but without VosTac get no flicker, even though that mod is the one that makes charge matter.
* **Constant dim range over dimming deeper toward empty.** The light is as usable at 1% as at 5%. The cost is that the last warning looks no more urgent than the first.
* **Bursts over single dips.** A cluster of dips is harder to miss and looks like an unstable light. The cost is up to 1 s of flicker per warning.
* **Dimming both lights over the beam alone.** The close-range glow and the beam stay in step, including on the weapon in VosTac's inspect mode. The cost is that the dip is also visible on nearby surfaces and the weapon model.
* **Flicker for every light in the slot over battery-powered devices only.** No test for battery compatibility. A light from another mod that drains but does not accept batteries still flickers.
