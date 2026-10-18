# Scope swing shadow

## Intent

Vanilla darkens a magnified scope from the side while the player pans with it aimed. VosTac removed that shadow entirely. Bring it back, much less aggressive than vanilla: a steady aim and ordinary panning show the full scope picture, and only a wide or fast swing, the shaking of exhausted arms or the jolt of a crouch or stand pushes a dark crescent in from the side of the lens.

## Constraints and assumptions

* Vanilla's shadow lives in `src/Shaders/Reticle.gdshader`. It offsets a very tight aperture by the view ray plus the lens normal per fragment, so any misalignment between the eye and the optic axis darkens the lens. It runs identically in PIP and non-PIP mode.
* The signal has three sources, each as pitch and yaw rotation:
	* The mouse lag of the rig's `Sway` node (vanilla `Sway.gd`, `Handling/Sway`): its rotation away from its rest rotation. While scoped, vanilla sets the lag target from the latest mouse delta times `aimMultiplier` and `gameData.scopeSensitivity` clamped to 0.1 to 1.0, and eases toward it. The lag returns to rest when the mouse stops. VosTac does not change `Sway.gd`.
	* The lag follows mouse speed, not the camera's turn rate. VosTac divides scoped sensitivity by magnification only in `Hooks/Controller.gd`, while `Sway.gd` reads the raw preference. Mouse speed matches how fast the picture moves inside the scope, so the same apparent swing gives the same shadow at any magnification, and in world terms a higher magnification shows it at a proportionally slower turn.
	* Above a scope sensitivity of 1.0 the lag no longer grows with sensitivity, so neither does the shadow.
	* The wobble of the rig's `Noise` node (`Handling/Sway/Noise`), only while the arms are exhausted (`gameData.armStamina` at 0). VosTac's `Hooks/Noise.gd` doubles the wobble's frequency and amplitude in that state, on top of the aim and weapon weight multipliers, so a heavier weapon shakes the shadow in further.
	* The kick of the rig's `Impulse` node (vanilla `Impulse.gd`, `Handling/Sway/Noise/Tilt/Impulse`): its rotation away from rest. Vanilla kicks the node on crouch one way and on stand the other way, then eases it back to rest. VosTac does not change `Impulse.gd`. Its position kick does not count.
* Ruled out: handling jump and landing. The same `Impulse` node kicks on them too, so they shadow as well while aiming is allowed in the air. Disabling aiming while jumping or falling is separate work tracked in `TODO.md`, and it removes that case.
* Ruled out: full eye to optic misalignment as the signal. Recoil, `Tilt` and the `Noise` wobble with arms not exhausted (idle drift, hold breath) never cause the shadow.
* Ruled out: the roll of either node, including the canted roll of `Sway`. Only pitch and yaw count.
* The shadow applies in PIP and non-PIP mode alike, while a magnified optic is active (`gameData.isScoped`, so not on a secondary sight or a HAMR switched to its top dot). Red dots and holographic sights never get it.
* The reticle stays drawn over the shadow. Likho's Battery Powered draws its reticle in a `next_pass` over the lens material, so the shadow never covers it there either. Its own shaders read `lens_uv_scale` only.
* The shadow has no magnification or eye relief term of its own. Magnification enters only through the sensitivity split above.
* Measured in game: the lag stays near or under 1° through ordinary panning and reaches about 2° to 4° on fast swings, so one dead zone separates them.
* Measured in game: the exhausted wobble peaks at only about 0.3° to 1.1°, at or under the same dead zone. The wobble term therefore carries a gain toward the misalignment, so exhaustion shows the shadow through the shared dead zone without a dead zone of its own.
* Measured in game: the `Impulse` kick of a crouch or stand peaks at about 1.4°, barely past the dead zone, which leaves a crescent too thin to see. The kick term therefore carries a gain of its own, as the wobble does.
* Ruled out: an MCM setting. The shadow is always active.

## Scope

Owned:

* `likhos-vostac/Scripts/Nodes/WeaponRig_Optic.gd`: the swing shadow amount and direction, and pushing it to the reticle material with the other reticle inputs.
* `likhos-vostac/Shaders/Reticle.gdshader`: the scope mask.

Context only:

* Vanilla `src/Scripts/Sway.gd`: the mouse lag.
* Vanilla `src/Scripts/Impulse.gd`: the crouch and stand kick.
* `likhos-vostac/Scripts/Hooks/Noise.gd`: the wobble and its exhausted multiplier.
* `likhos-vostac/Scripts/Hooks/Character.gd`: arm stamina.
* Vanilla `src/Shaders/Reticle.gdshader`: the vanilla shadow, for the direction the crescent enters from.
* `likhos-battery/Scripts/OpticPower.gd` and its shaders: the chained reticle pass.

## Solution

### Swing shadow in `WeaponRig_Optic`

Each ADS frame `WeaponRig_Optic` sums the misalignment angle from its three sources and turns it into a shadow offset: a 2D vector in lens UV.

* The misalignment is the pitch and yaw lag of the rig's `Sway` node against its rest rotation, plus the pitch and yaw of the `Noise` wobble scaled by a fixed gain and an exhaustion weight, plus the pitch and yaw of the `Impulse` kick scaled by a fixed gain.
* The exhaustion weight eases to 1 while `gameData.armStamina` is 0 and back to 0 once it recovers, so the wobble term fades in and out instead of snapping.
* The offset direction follows the misalignment direction, so the crescent enters from the side vanilla's shadow does for the same swing.
* Its length is 0 inside a dead zone of misalignment angle, grows linearly above it and reaches its maximum at a full reach angle. The maximum leaves a sliver of picture: the crescent covers at most about 60% of the lens width.
* The dead zone, full reach angle, maximum, wobble gain, kick gain and the exhaustion weight's ease rate are named constants in `WeaponRig_Optic`, tuned in game.
* The offset is 0 whenever a magnified optic is not active in ADS. It moves with the lag and the wobble themselves and needs no smoothing of its own.

`_update_reticle` pushes the offset with size and opacity. It is the only path that writes the reticle material.

### Reticle shader

The scope mask is the lens rim plus an eccentric clear aperture: a circle the size of the lens, shifted by the shadow offset, with a soft edge. Outside the aperture the lens is black, under the reticle. At offset 0 the aperture covers the whole lens and the picture is the same as with no shadow. The mask applies to scope materials only.

### Flow

1. The mouse turns the camera and vanilla `Sway` rotates the weapon off rest in proportion to mouse speed. With exhausted arms, `Noise` also shakes the weapon hard. A crouch or stand makes vanilla `Impulse` kick it.
2. `WeaponRig_Optic._handle_ads` maps the combined misalignment to a shadow offset and `_update_reticle` pushes it.
3. The shader shifts the clear aperture and the crescent shows on the lens.
4. The mouse stops and the lag eases back to rest, the kick settles, or the arms recover and the wobble term fades. The crescent slides out.

### Observable result

* Steady aim, idle drift, hold breath, recoil and slow or moderate panning with rested arms: full scope picture, no shadow.
* A fast flick or a wide swing: a dark crescent slides in from the side, matching the swing direction, and slides out as the turn ends. It never blacks out the whole lens.
* Aiming with exhausted arms: the crescent flickers in and out around the lens edge with the shake, deeper on heavier weapons. Panning while exhausted reaches the shadow sooner. Once the arms recover it fades away.
* Crouching or standing up while aimed: the crescent dips in from above or below and settles out within a moment.
* Same behavior in PIP and non-PIP mode and on every magnified optic. A swing that moves the scope picture equally fast gives the same shadow at any magnification, so a 12x scope shadows at a far slower world turn than a 1x.
* Red dots, holographic sights, secondary sights and the HAMR top dot never show it.
* The reticle stays visible over the crescent.

## Tradeoffs

* Sway lag and exhausted wobble over full misalignment. The cost: the shadow is a stand in for eye position, not a physical one, so a shot or a strong rested wobble on a heavy weapon never darkens the lens.
* Exhausted wobble through the shared dead zone over a constant exhaustion shadow. The cost: a light weapon with exhausted arms may barely show it.
* A gain on the wobble over a lower dead zone while exhausted. The cost: the shadow exaggerates the visible shake, and panning while exhausted gets no extra sensitivity beyond the added wobble.
* A dead zone over vanilla's always on response. The cost: the shadow is absent through most panning, so it gives no feedback about smaller swings.
* Mouse speed over an explicit magnification or exit pupil term. Higher magnification is more sensitive in world terms, as with a real scope, but in proportion to magnification rather than to exit pupil size, and two optics at the same magnification shadow alike whatever their objective size.
* A capped crescent over a full blackout. The cost: even the fastest flick keeps a sliver of picture.
* The `Impulse` rotation over its position kick or the character's own crouch state. The cost: the shadow follows vanilla's kick timing and strength, and standing shadows as much as crouching.* Lag based over mouse speed measured directly. The cost: the response inherits vanilla `Sway` tuning, so a mod that changes `Sway` multipliers changes the shadow too, and the sensitivity cap at 1.0 caps it as well.
