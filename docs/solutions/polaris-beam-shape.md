# Flashlight beam shape

## Intent

Every flashlight should throw a significantly wider and shorter beam than it does today. The new shape is derived from the vanilla values by scaling, so the three lights keep their relative reach and a game patch to the vanilla numbers carries through.

## Constraints and assumptions

* Applies to every light that goes through `Flashlight.gd`: Narva, Polaris, Phoenix and any light added by another mod. There is no per-tier or per-item branching.
* Two factors define the shape: one for range and one for cone angle. Both multiply the vanilla value. No absolute range or angle is stated anywhere in the mod.
* Always on. No MCM setting.
* Only the cone angle and the range change. Energy, color, the `FPS` omni light, battery drain, the light projector texture and `spot_angle_attenuation` stay vanilla.
* The world beam is one `SpotLight3D` shared by every flashlight. Its cone is authored once in `Core.tscn` at 25 degrees and vanilla script never writes it. The node is created fresh with the authored cone on every scene load.
* Scaling must never compound. Vanilla rewrites range on every activation, so range can be scaled from what vanilla just wrote. Vanilla never rewrites the cone, so the scaled cone is always derived from the authored angle, not from the node's current angle.
* Vanilla `Activate` rewrites range and energy every time it runs, and `ResetCheck` re-runs it every 10 physics frames while the light is on. A range written from anywhere other than the tail of `Activate` is overwritten within 10 frames.
* Ruled out: applying the shape from the existing `_physics_process` hook. Activation by input happens in `FlashlightDriver._input`, so the correction would land on the next physics tick and leave rendered frames showing the vanilla beam.
* Ruled out: tying AI detection to the beam. `Sensor.gd` boosts detection from `gameData.flashlight` and a fixed pointing cone. It never reads the light's range or angle, so detection is unchanged by this solution.
* Ruled out: the weapon-mounted light driven by `RigManager.gd`. It is a separate pair of lights and keeps its vanilla beam.
* Assumption, unverified: hooks on `Activate` dispatch for every caller, including the script's own internal calls from `ResetCheck` and `Load` and the `parent.Activate()` call from `FlashlightDriver`. `RTVModLib.md` describes the wrapper replacing the method in place, which implies it. If internal calls bypass dispatch, the single hook site does not hold and the design needs revisiting.
* Assumption, unverified: the light projector texture and the authored `spot_angle_attenuation` of 2.5 still look right when stretched over the wider cone.

## Scope

Owned:

* `likhos-vostac/Scripts/Hooks/Flashlight.gd`. Shapes the beam after every activation.
* `likhos-vostac/Scripts/Main.gd`. Registers the hook.
* `likhos-vostac/mod.txt`. The `[hooks]` entry for `res://Scripts/Flashlight.gd`.
* `likhos-vostac/README.md`. The hook compatibility list only.

Context only, not modified:

* `src/Scripts/Flashlight.gd`. Supplies `Activate` and the `lightWorld` spot light.
* `src/Resources/Core.tscn`. Authors `Camera/Flashlight/World` with `spot_angle = 25.0`.
* `src/Items/Electronics/{Narva,Polaris,Phoenix}/*.tres`. Declare each light's power tier.

## Solution

### Factors

| property | factor |
|---|---|
| range | 0.6 |
| cone angle | 1.8 |

These are starting values to be confirmed in game.

### Resulting beams

`spot_angle` is the cone's half-angle in degrees.

| light | tier | vanilla range | range | vanilla cone | cone |
|---|---|---|---|---|---|
| Narva | Low | 25 | 15 | 25 | 45 |
| Polaris | Medium | 50 | 30 | 25 | 45 |
| Phoenix | High | 100 | 60 | 25 | 45 |

At 45 degrees the lit circle has about 2.1 times the radius it has at 25 degrees at the same distance.

### Hook

VosTac hooks `Flashlight.Activate` as a post hook, handled in `Hooks/Flashlight.gd` alongside the existing `_physics_process` replacement. Vanilla `Activate` runs first and sets range, energy and color for the equipped light. The post hook then finishes the beam on `lightWorld`:

* Range becomes the range vanilla just wrote, times the range factor.
* Cone becomes the authored cone times the cone factor.

When vanilla `Activate` returns early without writing a range, the hook writes nothing, so a range that is already scaled is never scaled again.

`Deactivate` is not hooked. It zeroes range and energy, so the cone left on the node while the light is off is never visible.

### Flow

1. The player presses the flashlight binding. `FlashlightDriver` calls `Activate` on the flashlight node.
2. Vanilla `Activate` reads the equipped light and sets its vanilla range, energy and color.
3. The post hook runs in the same call and scales the range and the cone. No frame renders in between.
4. Every 10 physics frames `ResetCheck` calls `Activate` again and the same two steps repeat, so the shape holds for as long as the light is on.
5. The player swaps lights with the flashlight on. The next `ResetCheck` activation writes the new light's vanilla range and the hook scales it. The cone is the same for every light.

### Expected result

* All three lights cover a much wider area and reach 60 percent as far as in vanilla.
* The lights keep their vanilla ordering and ratios: the Phoenix still reaches twice as far as the Polaris and four times as far as the Narva.
* Brightness close to the player is unchanged for all three lights.

## Tradeoffs

* **Uniform factors over per-light profiles.** Two numbers to tune and nothing to maintain when a light is added or patched. The cost is that no light can be shaped independently. The Narva drops to 15 m, which is short, and it cannot be given a gentler factor without bringing per-tier data back.
* **Post hook on `Activate` over a replacement.** Vanilla keeps ownership of energy, color and the tier branching, so a game patch to those values carries through. The cost is one more hooked method on `Flashlight.gd` that other mods can collide with, and that vanilla range is written and immediately overwritten on each activation.
* **Rewriting the cone on every activation over setting it once per scene.** One redundant property write every 10 physics frames, in exchange for a single hook site and no dependency on the flashlight node's startup order.
* **Vanilla energy on a wider cone.** Godot does not spread a spot light's energy over its cone, so the wider beam emits more total light at the same per-surface brightness. Every light illuminates more of the scene at close range than a physically scaled beam would. Lowering energy to compensate would dim the near field, most noticeably on the Narva.
