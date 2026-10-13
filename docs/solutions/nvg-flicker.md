# NVG low charge flicker

## Intent

Night vision goggles that are running out of battery should show it the same way the other battery powered devices do. As the charge drains through 5%, 4%, 3% and 2% the night vision image flickers once each time: a burst of one to three short partial dips in brightness. In the last percent the flicker is continuous until the goggles switch off. The flicker is a visual cue only. It must not get in the way of using the goggles.

## Constraints and assumptions

* Lives in Likho's Battery (`likhos-battery`), next to the flicker of flashlights, lasers and sights.
* The burst pattern is the shared one in `Scripts/Flicker.gd`: threshold, burst points, continuous phase, dip count, dip length and step pace. NVG gets no timing of its own.
* An NVG's charge is the `slotData.condition` of the item in the NVG equipment slot. Vanilla `NVG.Consumption` drains every item in that slot, so every NVG flickers, including ones added by other mods. There is no per-item branching and no check for battery compatibility.
* The flicker only dims. A dip lowers the light amplification and never takes the image below the unaided view. The green overlay and its tint stay as vanilla draws them.
* Only `tonemap_exposure` of the world environment changes. `gameData.NVG`, the overlay, the tint and the battery drain are untouched, so everything that reads the NVG state sees the goggles as on during a dip, VosTac's scope blur included.
* Vanilla `NVG.Activate` rewrites the exposure every time it runs, and `ResetCheck` re-runs it every 10 physics frames while the goggles are on. That is one activation every 83 ms, the same cadence as the flashlight. An exposure written from anywhere other than the tail of `Activate` is overwritten within 83 ms.
* Dimming must never compound. The dim is applied only to an exposure vanilla wrote in the same call. Vanilla writes it only for an equipped NVG with a power tier of Low, Medium or High. In every other case nothing is written.
* VosTac replaces `NVG._physics_process` but still calls `ResetCheck` every physics tick, so the activation cadence is the vanilla one with or without VosTac.
* Always on. No LCM setting. Vanilla already drains NVGs, so there is no power draw to switch off.
* Visual only. No sound and no HUD element.
* NVG handling is otherwise unchanged: the loot charge roll, battery removal and prices stay as they are.
* Ruled out: cutting the night vision out entirely during a dip, the way lasers and sights go dark. The last percent would strobe between night vision and darkness.
* Ruled out: dimming or hiding the green overlay. The dip is carried by the amplification alone.
* Ruled out: a dim range shared with the flashlight. Each device owns the look of its dip and `Flicker.gd` owns the timing only.
* Ruled out: the edge cases the shared pattern already rules out: a change in charge that lands exactly one whole percent lower plays one stray burst, and a burst cut short finishes at the next switch-on unless the charge came back higher.
* Assumption, unverified: a hook on `NVG.Activate` dispatches for the script's own internal calls from `ResetCheck`. The flashlight flicker relies on the same behaviour for `Flashlight.Activate`.
* Assumption, unverified: a dip to 30-70% of the amplification is clearly visible on the PV7. The range is a starting value to be confirmed in game.

## Scope

Owned:

* `likhos-battery/Scripts/NVG.gd`. The `Activate` post hook handler.
* `likhos-battery/Scripts/Main.gd`. Creation of the handler and registration of its hook.
* `likhos-battery/mod.txt`. The `[hooks]` declaration for `NVG.gd`. The version is left to the build.
* `likhos-battery/README.md`. The low charge flicker section.
* `likhos-battery/INSTRUCTIONS.md`. The hooks list.
* `likhos-battery/CHANGELOG.md`. The release note.

Context only, not modified:

* `src/Scripts/NVG.gd`. Supplies `Activate`, `ResetCheck`, `NVGSlot` and the `world` whose environment carries the exposure.
* `likhos-battery/Scripts/Flicker.gd`. The shared burst pattern.
* `likhos-battery/Scripts/Flashlight.gd`. The handler this one follows.
* `likhos-vostac/Scripts/Hooks/NVG.gd`. Replaces `NVG._physics_process` and adds the hold and toggle input. It does not hook `Activate`.

## Solution

### Tunables

| tunable | value |
|---|---|
| amplification during a dip | random, 0.3 to 0.7 of the vanilla amplification |

Amplification is the part of the exposure above 1.0, the unaided level. On the PV7, which vanilla runs at an exposure of 2.5, a dip lands between 1.45 and 2.05. The factor is picked at random for every dimmed activation, so dips differ in depth and a dip two steps long can show two levels. Everything else about the flicker comes from the tunables in `Flicker.gd`.

### Timing

The gap between two bursts is the time one percent of charge lasts, which follows from the vanilla drain rate. The continuous phase covers the last percent, so it lasts exactly one gap.

| NVG power tier | gap and continuous phase | in winter |
|---|---|---|
| Low | 20 s | 10 s |
| Medium, the PV7 | 10 s | 5 s |
| High | 5 s | 2.5 s |

### Handler

`Scripts/NVG.gd` is a handler of the same shape as `Scripts/Flashlight.gd`: it is created by `Main.gd` with the lib, owns one `Flicker` and exposes the post hook on `NVG.Activate`, which `Main.gd` registers and `mod.txt` declares.

Vanilla `Activate` runs first and writes the full exposure for the equipped NVG's power tier. The post hook then advances its `Flicker` by one step at the NVG's charge and, when that step is inside a dip, lowers the exposure by the dim factor. When vanilla wrote no exposure the hook does nothing and does not step the flicker.

The activation call is the only tick. The handler has no node, no per-frame processing, no timer and no hook on `_physics_process`. No restore step exists: vanilla rewrites the full exposure on the next activation, and `Deactivate` sets it back to 1.0.

### Flow

1. The goggles are on. Every 10 physics frames `ResetCheck` calls `Activate`, vanilla writes the full exposure and the post hook runs.
2. Charge is above 5%. The hook leaves the exposure alone.
3. Charge drains through 5%. A burst starts: the image holds for one or two activations, then dims for one or two, and repeats for up to three dips.
4. Charge drains through 4%, 3% and 2%. Each one starts another burst.
5. Charge drains through 1%. Bursts follow each other without a break.
6. Charge reaches 0%. Vanilla `ResetCheck` deactivates the goggles.
7. The player swaps in another battery or another NVG. A burst that was running is dropped if the charge is now higher.

### Expected result

* An NVG above 5% behaves as it does today.
* At 5%, 4%, 3% and 2% the night vision image dims for a moment, one to three times in quick succession, and stays green throughout.
* The PV7 gives four warnings 10 s apart on its way from 5% to 1%, 5 s apart in winter.
* From 1% the image flickers without a break until the goggles switch off: 10 s on the PV7, 5 s in winter.
* Switching the goggles off and on between 5% and 1% does not flicker by itself. Switching them on below 1% flickers at once.
* The image is never darker than the unaided view until the goggles switch off at 0%.
* The README lists NVGs among the devices that flicker at low charge, and INSTRUCTIONS lists the `NVG.Activate` post hook.

## Tradeoffs

* **Dimming the amplification over cutting the night vision out.** The goggles stay usable down to 0%, in line with the flashlight. The cost is a milder cue than the one lasers and sights give, and a dip that depends on how dark the scene is: in a bright scene the dimmed image differs less from the full one.
* **Scaling the amplification over scaling the whole exposure.** A dip never shows less than the unaided view. The cost is a shallower dip than the flashlight's for the same range: 58% to 82% of full image brightness on the PV7.
* **The activation call as the only tick over a per-frame driver.** One post hook, no node and no remembered exposure. The cost is a dip quantized to 83 ms steps with hard edges, tied to vanilla's poll interval and the physics tick rate.
* **A dim range of its own over one shared with the flashlight.** The NVG dip can be tuned in game without touching the flashlight. The cost is the same two starting values written in two handlers.
* **Flicker for every item in the NVG slot over battery powered devices only.** No test for battery compatibility. An NVG from another mod that drains but does not accept batteries still flickers.
