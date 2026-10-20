# Scope shadow

## Intent

VosTac's scope shadow has grown five sources, each wired its own way. Sway lag, exhausted wobble and the crouch or stand kick feed raw angles. Lean and aim-in each carry their own follower, gain, soft cap and units, and only aim-in has a random turn. Fold every source into one shared pipeline, so each is described the same way, tuned with the same set of parameters and combined in one place, and the random turn applies to every source alike. The tuned strength and direction of every source carries over.

## Constraints and assumptions

### Sources

* **Swing.** The mouse lag of the rig's `Sway` node (vanilla `Sway.gd`, `Handling/Sway`): its pitch and yaw away from its rest rotation. While scoped, vanilla sets the lag target from the latest mouse delta times `aimMultiplier` and `gameData.scopeSensitivity` clamped to 0.1 to 1.0. VosTac divides scoped sensitivity by magnification only in `Hooks/Controller.gd`, so the lag follows how fast the picture moves inside the scope, and the same apparent swing shadows alike at any magnification.
* **Exhaustion.** The pitch and yaw wobble of the rig's `Noise` node (`Handling/Sway/Noise`), counted only while the arms are exhausted (`gameData.armStamina` at 0). VosTac's `Hooks/Noise.gd` scales the wobble with aim, weapon weight and exhaustion.
* **Stance.** The pitch and yaw kick of the rig's `Impulse` node (vanilla `Impulse.gd`, `Handling/Sway/Noise/Tilt/Impulse`) on crouch and stand. Vanilla eases it back to rest by itself.
* **Lean.** The roll of vanilla `Lean.gd` on `Core/Controller/Pelvis`: up to `leanAngle` (15°), positive leaning left, easing at `leanSpeed` (5 per second). The whole rig rolls with the lean, so the scope never moves against the camera. The lean shadow is a stand-in for the eye catching up with the head's motion, not a measured misalignment.
* **Aim.** The rig's travel into the aim pose: the sideways and vertical position of the `Handling` node. `Hooks/Handling.gd` eases it toward its pose target at `config.current_handling_rate`, which it publishes each frame and which varies with handling mode and weapon weight.

### Measured and tuned in game

* Swing lag stays near or under 1° through ordinary panning and reaches about 2° to 4° on fast swings.
* The exhausted wobble peaks at about 0.3° to 1.1°, and the stance kick at about 1.4°. Both need a gain to clear the dead zone.
* The aim lag peaks at 0.018 m to 0.028 m with the follower at 0.4 of the handling rate, through a scope at vanilla handling speed. With the follower at the full handling rate the peak is about 0.7 of that, so the aim gain is retuned.
* A transient crescent cannot fade faster than its source settles. With the follower at the source's own rate, an aim-in peaks about 0.17 s in, as the lens finishes fading in from black, and is gone within about 0.6 s. A slower follower lingers too long (about 1 s at 0.4 of the source rate). A faster one peaks while the lens is still fading in, so less of it is seen.
* Tuned peaks, as lens UV reach of the clear aperture: a single lean about 0.22, a lean switched straight to the other side about 0.32, an aim-in 0.30 to 0.42.
* Crescent directions were settled in game, not derived. Reasoning from the geometry got both the lean and the aim direction wrong at first, so each channel's sign is a tuned value. The lean crescent comes from the side opposite the lean. The aim crescent comes from the side the rig travels toward.
* A random turn within 45° total, rolled each time aiming starts, keeps the aim crescent from always entering at the same spot. The same spread applies to every channel.

### Ruled out

* A lagging eye model driven by the scope's motion through space. The shared pipeline keeps today's sources and their tuning.
* Recoil, `Tilt`, the `Noise` wobble with rested arms (idle drift, hold breath) and the roll of any rig node never shadow.
* An MCM setting. The shadow is always active.
* Temporary calibration output. Measuring a source for tuning is done with debug output that is removed afterwards.

### Shadow conditions

* The shadow applies in PIP and non-PIP mode alike while aiming with a magnified optic active (`gameData.isScoped`), so not on a secondary sight or a HAMR top dot. Red dots and holographic sights never get it.
* The reticle stays drawn over the shadow, including Likho's Battery Powered's reticle pass.

## Scope

Owned:

* `likhos-vostac/Scripts/Nodes/WeaponRig_Shadow.gd`: the shadow pipeline, its channels and their tuning, and writing the shadow to the reticle material.
* `likhos-vostac/Scripts/Hooks/WeaponRig.gd`: injecting `WeaponRig_Shadow` into each rig.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Optic.gd`: holds no shadow logic.
* `likhos-vostac/Scripts/Hooks/Handling.gd` and `likhos-vostac/Scripts/Config.gd`: publishing the handling rate as `config.current_handling_rate`.

Context only:

* `likhos-vostac/Shaders/Reticle.gdshader`: consumes `shadow_offset`, the clear aperture's shift in lens UV.
* `WeaponRig_Optic._update_reticle`: installs the VosTac reticle shader on scope and variable optic materials and writes their size and opacity.
* Vanilla `Sway.gd`, `Impulse.gd` and `Lean.gd`, VosTac's `Hooks/Noise.gd` and `Hooks/Character.gd` (arm stamina).

## Solution

### Channels

Every source is a channel that turns a reading of its node into a misalignment: a 2D angle in degrees in view space, x the yaw and y the pitch, pointing where the clear aperture shifts. A channel is defined by the same parameters:

* **Signal.** A 2D reading of its source, in the source's own units.
* **Kind.** A level channel uses the signal itself. A transient channel uses the signal minus a follower of it, so it reads only while the source moves and settles to zero once it rests. The follower eases toward the signal at the source's own rate, so the shadow's timing scales with the source's speed and its strength does not.
* **Gain.** Degrees per source unit, sign included.
* **Soft cap.** A smooth limit on the channel's angle, so a channel driven past its usual range, such as a lean switched straight to the other side, does not grow in proportion.

Each time aiming starts, every channel rolls its own random turn within one shared spread, and its direction stays turned by that angle until the next aim.

| Channel | Signal | Kind | Source rate |
|---|---|---|---|
| Swing | `Sway` pitch and yaw away from rest | level | |
| Exhaustion | `Noise` pitch and yaw, weighted by exhaustion | level | |
| Stance | `Impulse` pitch and yaw | level | |
| Lean | `Pelvis` roll, read as yaw | transient | vanilla `leanSpeed` |
| Aim | `Handling` sideways and vertical position | transient | `config.current_handling_rate` |

The exhaustion weight eases to 1 while the arms are exhausted and back to 0 once they recover, so the exhaustion channel fades in and out.

### `WeaponRig_Shadow`

`WeaponRig_Shadow` is a rig handler node, extending `WeaponRig_Base` like the other `WeaponRig_*` handlers, and `Hooks/WeaponRig.gd` injects it into each rig alongside them. It owns the channels and their parameters, held as one table of channel definitions rather than per-source constant groups, and reads the rig's nodes and the pelvis.

* It processes every frame, aiming or not. Followers keep tracking their source outside ADS and start from the source's current value, so drawing a weapon or starting an aim never shows stale lag.
* While aiming with a magnified optic it sums the channels into one misalignment. The misalignment maps to the clear aperture's offset in lens UV: zero inside a dead zone, growing linearly above it to a maximum reach at a full reach angle, which leaves a sliver of picture. Lens UV runs y down. Otherwise the offset is zero.
* It writes the offset as `shadow_offset` to the reticle material of the rig's active optic, on scope and variable optics only. It is the only writer of `shadow_offset` and depends on no other handler's processing order. `WeaponRig_Optic` installs the VosTac reticle shader on the first ADS frame, so a write before that lands on vanilla's shader, which has no such parameter, and takes effect from the next frame.
* The spread, dead zone, full reach angle, maximum reach and the exhaustion weight's ease rate are its other named parameters.

### Flow

1. A source moves: the mouse swings the rig, the arms shake while exhausted, a crouch or stand kicks it, the player leans, or the rig travels into the aim pose.
2. `WeaponRig_Shadow` reads every channel, sums their misalignment and maps it to the aperture offset.
3. It writes the offset to the active optic's reticle material, and the shader shifts the clear aperture so the crescent shows.
4. The source settles: the swing lag eases back, the kick settles, the arms recover, the lean or the aim pose comes to rest and the transient followers catch up. The crescent slides out.

### Observable result

* Steady aim, idle drift, hold breath, recoil and slow or moderate panning with rested arms: full scope picture.
* Every crescent below enters from roughly the side described, turned a little at random on each aim.
* A fast flick or wide swing: a crescent slides in from the side matching the swing and out as the turn ends.
* Exhausted arms: the crescent flickers around the lens edge with the shake, deeper on heavier weapons, and fades once the arms recover.
* Crouching or standing while aimed: the crescent dips in from above or below and settles within a moment.
* Leaning while aimed: a brief crescent from the side opposite the lean, peaking once the lean is underway and fading as it comes to rest. A held lean shows none. Releasing the lean gives a brief one from the other side. Switching straight to the other lean shows a stronger one, but not twice as strong.
* Taking aim: a crescent from the side the rig travels toward, peaking as the lens clears and gone within about 0.6 s. Heavier or lighter weapons stretch or shorten its timing, not its strength.
* Same in PIP and non-PIP mode. Red dots, holographic sights, secondary sights and the HAMR top dot never show it. The reticle stays visible over the crescent.

## Tradeoffs

* Followers at the source's own rate over a tunable ratio of it. No timing knob of its own: a transient crescent's timing is set by how fast its source moves. The cost: aim-in peaks only just as the lens clears and cannot be made to linger past the rig settling, and its gain is retuned to the smaller peak lag.
* Swing, exhaustion and stance stay level channels. The swing lag already follows mouse speed and the kick already decays by itself. Making them transient would cut the swing shadow during a sustained fast pan. The cost: two kinds of channel instead of one.
* A soft cap on every channel over caps on the transient ones only. Swing's cap sits above the full reach angle so a flick still reaches full reach. The cost: one more parameter on channels that rarely hit it.
* One spread for every channel, rolled per aim, over a spread per channel or a roll per movement. The cost: the swing crescent no longer matches the swing direction exactly, and within one aim every lean or stance change enters at the same turned angle.
* A rig handler node of its own over a helper owned by `WeaponRig_Optic` or keeping the pipeline inline. The optic script already handles zoom, secondary sights, ADS FOV, the PIP camera and the reticle, and with its own writer of `shadow_offset` it needs no knowledge of the shadow. The cost: two writers to the reticle material, the shadow can trail the shader install by a frame, and one more handler with the audio players `WeaponRig_Base` gives every handler.
