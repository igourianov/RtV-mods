# Footsteps follow movement speed

## Intent

In VosTac the player's footsteps should follow how fast the player actually moves. Today step cadence is a fixed rate per movement state and step volume is fixed, so walking at 30% speed through a scope sounds the same as a plain walk.

* Step cadence follows actual speed in every ground state: walk, crouch and sprint, with every speed multiplier and speed override applied.
* The head bob slows and speeds up together with the steps.
* Steps get quieter only below walk speed. The volume falls linearly with speed and never rises above today's level.

## Constraints and assumptions

* Vanilla `Controller.Headbob` advances one bob phase by a constant per state (walk 10, sprint 20, crouch 8 per second) and plays a step once per cycle of that phase. Cadence never reads `currentSpeed`.
* Vanilla walk and sprint share one stride: 4 phase units per metre (10 at 2.5m/s, 20 at 5m/s). Vanilla crouch has a shorter one: 8 per metre (8 at 1m/s). Scaling by stride reproduces vanilla cadence exactly at vanilla speeds.
* Actual speed is the controller's planar speed after vanilla `Movement` has run, not `currentSpeed`. It includes the VosTac walk multipliers and speed overrides, the vanilla inertia for strafing and backpedalling, the vanilla overweight and fracture slowdown and collisions.
* The volume reference is the effective walk speed that `_apply_speed` resolves: `Config.walk_speed` with the override on, the controller's `walkSpeed` otherwise. Plain forward walking is always at full volume, whatever the walk speed setting is.
* Volume has a cap at today's level and no floor. It reaches silence at zero speed.
* Cadence has no cap. It follows speed above vanilla sprint speed too.
* `_update_state` sets `isWalking` while crouch walking, unlike vanilla. The stride is therefore chosen by `isCrouching` first, not by vanilla's walk, sprint, crouch order.
* Ruled out: AI hearing. Vanilla `Sensor.PlayerHearDetection` detects the player by `isRunning` and `isWalking` within fixed distances and does not listen to sounds. It stays as it is.
* Ruled out: the second, smaller bob that vanilla `Noise.gd` applies to the `Noise` node position. It keeps its constant rate per state.
* Ruled out: jump and landing sounds, swimming strokes and the bob while swimming. They are not steps at a speed.
* Ruled out: AI footsteps (`AI.PlayFootstep`).
* No LCM setting. The scaling is always active.
* VosTac registers its hooks through `register_hook`, so every hooked vanilla method is also declared under `[hooks]` in `mod.txt`.
* Assumption, unverified: lowering the volume of a vanilla `AudioInstance2D` right after `PlayInstance` started it takes effect for the whole clip.

## Scope

Owned:

* `likhos-vostac/Scripts/Hooks/Controller.gd`: the bob phase, the step trigger and the step volume.
* `likhos-vostac/Scripts/Main.gd`: the hook registration.
* `likhos-vostac/mod.txt`: the `[hooks]` declaration for `Controller.gd`.
* `likhos-vostac/INSTRUCTIONS.md`: the replace hook list.

Context only:

* Vanilla `src/Scripts/Controller.gd`: `Headbob`, `PlayFootstep`, `Movement`, `Inertia` and the `headbob*` constants.
* Vanilla `src/Scripts/AudioInstance2D.gd`: `PlayInstance` sets the player's volume and starts it.
* Vanilla `src/Scripts/Noise.gd` and `src/Scripts/Sensor.gd`: ruled out above.
* `likhos-vostac/Scripts/Config.gd`: the speed override and walk multiplier settings.

## Solution

### Bob phase

`Hooks/Controller.gd` owns vanilla `Headbob` through a replace hook, the way it owns `MovementStates` and `Crouch`. It keeps vanilla's behaviour except for how the phase advances on the ground.

* On the ground the phase advances by stride times planar speed. The stride is the vanilla crouch stride while crouched and the vanilla walk stride otherwise, both derived from the controller's own `headbob*` constants and vanilla speeds.
* While swimming the phase advances at the vanilla swim rate.
* Bob intensity per state, the bob position easing, the return to rest without input and the once per cycle step trigger are vanilla's.

| movement, VosTac defaults, forward | speed | steps per second | vanilla |
|---|---|---|---|
| scoped walk | 0.9m/s | 0.57 | 1.59 |
| crouch | 0.7m/s | 0.89 | 1.27 |
| aim walk | 1.8m/s | 1.15 | 1.59 |
| canted walk | 2.25m/s | 1.43 | 1.59 |
| walk | 3.0m/s | 1.91 | 1.59 |
| sprint | 7.0m/s | 4.46 | 3.18 |

### Step volume

A step still goes through vanilla `PlayFootstep`, which keeps choosing the surface, razor and gear sounds. The hook then lowers the volume of every player that call spawned by one gain.

The gain is planar speed over the effective walk speed, capped at 1.

| movement, VosTac defaults | gain |
|---|---|
| walk and sprint, forward | 100% |
| walk, strafing | 80%, -1.9dB |
| canted walk | 75%, -2.5dB |
| walk, overweight or fractured | 67%, -3.5dB |
| aim walk | 60%, -4.4dB |
| walk, backpedalling | 60%, -4.4dB |
| scoped walk | 30%, -10.5dB |
| crouch | 23%, -12.6dB |

Slowdowns multiply, so backpedalling while aiming is at 36%.

### Flow

1. Each physics frame vanilla `_physics_process` runs `Movement`, which sets the controller's velocity from `currentSpeed`, inertia and the overweight and fracture slowdown, then moves the body.
2. It then calls `Headbob`. `controller-headbob` fires and `Controller.on_headbob` advances the phase from the resulting planar speed and updates the bob.
3. When the phase completes a cycle on the ground, the hook calls vanilla `PlayFootstep` and applies the gain to the players it spawned.
4. `MovementStates` runs after, as today, and sets the speed target for the next frame.

### Observable result

* Aiming, canting and scoping in slow the steps and the head bob in proportion to the walk multiplier, and quieten the steps by the same proportion.
* Crouch steps are slow and faint.
* Sprint steps at the default 7m/s come 40% faster than vanilla sprint, at today's volume.
* Plain forward walking is as loud as today. At the default 3m/s its steps come 20% faster than vanilla.
* Strafing, backpedalling, overweight and a fracture slow and quieten the steps.
* Walking into a wall produces no steps. Sliding along one slows them.
* Changing the speed or multiplier settings changes cadence at once, with no separate setting.
* Jump, landing and swimming sounds are unchanged.

## Tradeoffs

* A replace hook on `Headbob` over correcting the phase from pre and post hooks. The cost: one more single-owner hook that conflicts with any other mod replacing `Headbob`, and vanilla changes to it no longer carry over.
* Planar speed over `currentSpeed`. The cost: plain walking is no longer one cadence and one volume, since strafing and backpedalling count as slower. Steps in razor wire come at an erratic pace, as vanilla jitters the velocity there.
* A stride per metre without a cadence cap. The cost: at high sprint speed settings the head bob gets fast.
* A linear gain without a floor. The cost: crouch steps are close to inaudible, and stacked slowdowns go lower still.
* The effective walk speed as the volume reference over the vanilla one. The cost: cadence and volume use different references, so a walk speed setting above vanilla speeds the steps up without making them louder.
* Vanilla `PlayFootstep` keeps the sound selection, with the gain applied afterwards. The cost: the hook depends on vanilla spawning a step's players as children of the controller.
* AI hearing left alone. The cost: quiet steps do not make the player harder to hear for AI.
* The `Noise` node bob left alone. The cost: two bobs run at different rates below and above vanilla speeds. The untouched one has a quarter of the amplitude.
