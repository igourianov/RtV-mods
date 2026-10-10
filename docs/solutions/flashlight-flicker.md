# Flashlight low charge flicker

## Intent

A flashlight that is running out of battery should show it. Below 5% charge the beam flickers: bursts of one to three short partial dips in brightness at random intervals, rare at first and more frequent as the charge approaches zero. The flicker is a visual cue only. It must not get in the way of using the light.

## Constraints and assumptions

* Lives in Likho's Battery (`likhos-battery`). It works with or without VosTac installed.
* A flashlight's charge is the `slotData.condition` of the item in the light equipment slot. Every item in that slot is drained by vanilla `Flashlight.Consumption`, so every light flickers, including lights added by other mods. There is no per-item or per-tier branching and no check for battery compatibility.
* The flicker only dims. The light never goes fully dark before vanilla switches it off at 0%.
* Only `light_energy` changes, on both the `World` spot light and the `FPS` omni light, by the same factor. Range, cone, color and battery drain are untouched.
* Always on. No MCM setting. `likhos-battery` has no configuration today.
* Visual only. No sound and no HUD element.
* Vanilla `Activate` rewrites energy every time it runs, and `ResetCheck` re-runs it every 10 physics frames while the light is on. At the project's 120 physics ticks per second that is one activation every 83 ms. An energy written from anywhere other than the tail of `Activate` is overwritten within 83 ms.
* Dimming must never compound. The dim factor is applied only to an energy vanilla wrote in the same call. When vanilla `Activate` returns early without writing energy, nothing is written.
* VosTac already has a post hook on `Flashlight.Activate` that writes `spot_range` and `spot_angle`. Post hooks are multi-owner. The two hooks write disjoint properties, so their order does not matter.
* VosTac replaces `Flashlight._physics_process` but still calls `ResetCheck` every physics tick, so the activation cadence is the same with or without it.
* Ruled out: resetting the schedule at switch-on. A light used in presses shorter than the gap would never flicker.
* Ruled out: a flicker owned by VosTac. The feature belongs with battery charge and should not require VosTac.
* Ruled out: the weapon-mounted light driven by `RigManager.gd`. It has no battery.
* Ruled out: NVG. It has a charge but is not a flashlight.
* Ruled out: AI detection. `Sensor.gd` reads `gameData.flashlight` only, so a dimmed beam is detected the same as a full one.
* Assumption, unverified: hooks on `Activate` dispatch for the script's own internal calls from `ResetCheck`. VosTac's beam shape relies on the same behaviour. If internal calls bypass dispatch, the activation cadence is not available as a clock and the design needs revisiting.
* Assumption, unverified: a dip quantized to 83 ms steps reads as a flicker and not as a stutter.

## Scope

Owned:

* `likhos-battery/Scripts/Flashlight.gd`. The flicker handler.
* `likhos-battery/Scripts/Main.gd`. Creates the handler and registers the hook.
* `likhos-battery/mod.txt`. The `[hooks]` entry for `res://Scripts/Flashlight.gd`.
* `likhos-battery/README.md`. The feature list and the hook compatibility list.
* `likhos-battery/CHANGELOG.md`. The release note.

Context only, not modified:

* `src/Scripts/Flashlight.gd`. Supplies `Activate`, `ResetCheck`, `lightSlot` and the two lights.
* `likhos-vostac/Scripts/Hooks/Flashlight.gd`. Shares the `Activate` post hook site.
* `likhos-battery/Scripts/Item.gd`. The handler convention to follow: a `RefCounted` constructed with the lib, one `on_*` method per hook.

## Solution

### Tunables

| tunable | value |
|---|---|
| charge threshold | 5% |
| dim factor during a dip | random, 0.3 to 0.7 |
| dips in a burst | 1 to 3 |
| dip length | 1 or 2 activation intervals, about 0.08 to 0.17 s |
| pause between dips in a burst | 1 or 2 activation intervals, about 0.08 to 0.17 s |
| mean time between bursts at the threshold | 8 s |
| mean time between bursts near 0% | 1 s |

These are starting values to be confirmed in game. The number of dips, each dip length and each pause are picked at random per burst, so a burst lasts between 0.08 s and about 0.8 s. The dim factor is picked at random for every dimmed activation and applied to both lights, so dips differ in depth and a dip two intervals long can step between two levels. The time between bursts is randomized around the mean and the mean falls linearly with charge between the two ends. It is time with the light on: the seconds are converted to a number of activations from the physics tick rate and vanilla's 10 frame poll.

### Hook

Likho's Battery hooks `Flashlight.Activate` as a post hook, handled in `Scripts/Flashlight.gd`. Vanilla `Activate` runs first and writes the equipped light's full energy on both lights. The post hook then decides whether the light is inside a dip and, if it is, multiplies both energies by the dim factor.

The handler owns the flicker schedule: how many activations remain until the next burst and the burst's pattern of dips and pauses. The activation call is its only clock, so the schedule advances only while the light is on. Time the light spends off or the game spends paused does not count. Switching the light off freezes the schedule and the next switch-on resumes it where it stopped, including a burst that was cut short. The handler has no node, no per-frame processing and no hook on `_physics_process`.

* At or above the threshold there is no schedule and the hook writes nothing, so the light is exactly vanilla.
* Below the threshold the handler schedules the next burst from the current charge. Each activation checks the schedule. A burst is laid out in full when it starts and then consumed one activation at a time. Inside a dip the energy is dimmed. In a pause and between bursts vanilla's energy stands.
* When a burst ends the next one is scheduled from the charge at that moment, which is how the flicker speeds up as the battery drains.

No restore step exists. Vanilla rewrites the full energy on the next activation, and `Deactivate` zeroes it.

### Flow

1. The light is on. Every 10 physics frames `ResetCheck` calls `Activate`, vanilla writes full energy and the post hook runs.
2. Charge is at or above 5%. The hook leaves the energy alone.
3. Charge drops below 5%. The handler schedules the first burst several seconds out.
4. The scheduled number of activations has passed and the burst starts. The hook dims both lights by a random factor for one or two activations, then lets vanilla's full energy stand for one or two, and repeats for up to three dips. After the last dip the next burst is scheduled.
5. As charge falls the bursts come closer together, down to about one per second near empty.
6. The player switches the light off and back on. The countdown to the next burst continues from where it stopped.
7. Charge reaches 0%. Vanilla `ResetCheck` deactivates the light.
8. The player charges the light or swaps in a battery above 5%. The next activation finds the charge above the threshold and the flicker stops.

### Expected result

* A light above 5% behaves as it does today.
* Below 5% the beam and the close-range glow dip together to between 30% and 70% brightness for a moment, one to three times in quick succession, at irregular intervals.
* The bursts are rare right below 5% and frequent just before the light dies.
* The warning lasts as long as the last 5% of charge does: about 1:40 on the Narva, 0:50 on the Polaris and 0:25 on the Phoenix, and half that in winter.
* The light stays usable throughout. It is never dark until it switches off at 0%.

## Tradeoffs

* **The activation cadence as the clock over a per-frame driver node.** One post hook, no node, no remembered base energy and no dependence on who owns `_physics_process`. The cost is that a dip is quantized to 83 ms steps with hard edges, so smooth fades and shorter blinks are not possible. The cadence comes from vanilla's poll interval and the physics tick rate. A game patch to the tick rate makes the dips coarser or finer. A patch to the poll interval does the same and also scales the time between bursts.
* **Freezing the schedule while the light is off over resetting it at switch-on.** No wall clock, no hook on `Deactivate` and a light used in short presses still flickers after enough time on. The cost is that a burst cut short by switching off finishes at the next switch-on, so the light can come on dimmed for a fraction of a second.
* **Likho's Battery over VosTac.** The flicker ships with the mod that makes charge visible and works without VosTac. The cost is a second mod hooking `Flashlight.Activate`, with both writing light properties after activation.
* **Ramping the frequency over ramping the depth.** The dim range is the same at every charge, so the light is as usable at 1% as at 4% and only the rhythm tells the player how close to empty it is. The cost is that the last seconds do not look any dimmer than the first warning.
* **Bursts over single dips.** A cluster of dips is harder to miss and looks like an unstable light. The cost is that a full burst occupies most of the one second gap near empty, so the light is flickering nearly continuously in its last moments.
* **Random intervals over a fixed pattern.** Reads as a failing battery instead of a signal. The cost is that two sessions at the same charge do not look the same, which makes the tunables harder to judge in game.
* **Dimming both lights over the beam alone.** The close-range glow and the beam stay in step, including on the weapon in VosTac's inspect mode. The cost is that the dip is also visible on nearby surfaces and the weapon model.
* **Flicker for every light in the slot over battery-powered devices only.** No dependency on `BatteryUtil.powers`. A light from another mod that drains but does not accept batteries still flickers.
