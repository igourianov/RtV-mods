# ACOG illumination

## Intent

The ACOG's reticle should behave as a fiber optic lit reticle. Its brightness should follow the light that falls on the scope where the player stands: bright in open daylight, dimmer under cloud, at dusk and under a roof, and reduced to a faint tritium glow in darkness. It needs no battery and has no switch.

## Constraints and assumptions

* The light signal is the renderer's own lighting of the lens surface. No light level is derived from the clock, the weather or the indoor detector, and nothing is read back from the GPU.
* The reticle of every sight Battery handles is already drawn as lit albedo by `Shaders/Reticle.gdshader`, so sun, moon, ambient light and local lamps already reach it. That pass renders with `shadows_disabled`, which is why a reticle is as bright inside a building as on open ground.
* The vanilla ACOG reticle texture authors red beyond the chevron: the upper part of the drop tree at full strength and the middle part at about half. It has no channel that separates the chevron from the tree.
* Ruled out: limiting the glow to the chevron, as on a real TA31. The vanilla reticle is accepted as authored. A replacement texture loaded at runtime is uncompressed and takes about 22 MB of video memory.
* Shadow reception is a render mode, fixed per shader. It cannot be switched per sight by a uniform.
* A lens material is shared by every instance of its sight. The weapon in hands pushes the reticle state each frame, as it does for the other sights.
* The fiber collects light where the scope is, not where it points. A player in a dark room aiming at a sunlit field has a dim reticle. This is the real behavior and is intended.
* The tritium floor is emission. It does not fade with the scene, and it is the lowest brightness the reticle ever has.
* Battery powered sights keep their current look and behavior: dots, lit and unlit scope reticles, the rim glow and the low charge flicker.
* Always on. No LCM setting. `Red Dot Power Draw` and `Scope Power Draw` do not apply to the ACOG, and the `Reticle Illumination` binding does nothing on it.
* Works with and without VosTac. VosTac's lens shader and reticle placement are unchanged, and Battery reads `lens_uv_scale` from the lens material as it does today.
* Ruled out: a brightness computed from game state (day cycle, overcast, `gameData.indoor`, `gameData.shelter`). It ignores lamps, fires and other lights, and dims only inside the areas vanilla marks as indoor.
* Ruled out: vanilla's diffuse model for the fiber reticle. The lens normal points along the scope axis, so brightness would swing as the player turns and a high sun would barely count, which leaves little for shade to remove.
* Ruled out: sampling scene luminance from a viewport. A readback stalls the frame.
* Ruled out: smoothing the brightness over time. A fiber responds instantly.
* Ruled out: any change to how the ACOG looks under night vision.
* The first person weapon does not shadow its own lens. Every mesh of `M4A1_Rig.tscn`, arms included, and the mesh of `ACOG_Active.tscn` are authored with `cast_shadow` off, so only the world shadows the lens.
* Assumption, unverified: every other weapon rig and rail attachment is authored the same way. A rig or attachment that casts shadows would hold the reticle at its shaded brightness while mounted, and the design needs revisiting.
* Assumption, unverified: with direct light shadowed, the ambient term alone leaves the reticle clearly dimmer under a roof than on open ground by day.
* Assumption, unverified: one gain value gives a usable spread between noon, overcast, dusk and a moonlit night under the game's tonemapping.

## Scope

Owned:

* `likhos-battery/Scripts/OpticPower.gd`. Knows the ACOG as a fiber lit sight and pushes its reticle state.
* `likhos-battery/Shaders/`. The reticle pass, including the fiber lit response.
* `likhos-battery/Scripts/Main.gd`. Device setup only: which sights become battery powered devices.
* `likhos-battery/README.md`. The line describing the ACOG.

Context only, not modified:

* `src/Shaders/Reticle.gdshader`. The vanilla lens shader, source of the placement and normal math the reticle pass mirrors.
* `src/Items/Attachments/ACOG/`. The ACOG item, its lens material and reticle texture.
* `src/Scripts/World.gd`. `TOD` drives sun, moon and ambient light, which is what the fiber ends up reading.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Optic.gd` and `likhos-vostac/Shaders/Reticle.gdshader`. VosTac's lens shader and the `size`, `opacity` and `lens_uv_scale` it writes each frame.

## Solution

### Sight kind

`OpticPower.SIGHTS` lists the ACOG under a fiber kind of `Sight`. A fiber sight:

* Draws no power. It is not a battery device: no charge, no battery compatibility, no condition bar and no tooltip charge. `Main.gd` makes devices only of the sights that draw power.
* Has no manual switch, no light sensor, no rim glow and no flicker.
* Is always lit, at a brightness the renderer decides.

### Reticle pass

The ACOG's reticle is drawn by Battery's reticle pass over the lens material, placed the same way as every other sight: vanilla's view space placement, or VosTac's lens UV placement when `lens_uv_scale` is set.

The fiber reticle differs from a battery lit one in four ways:

* It receives shadows. Under a roof, behind a wall or in tree shade the sun and the moon do not reach it.
* It counts light from every direction equally. The angle between a light and the lens does not matter, and the brightness is uniform across the reticle. It does not use the lens normal or the backlight of vanilla's diffuse model.
* Its lit brightness is the scene's light on the lens times a fiber gain.
* It carries a constant emissive floor on the same texels, the tritium glow.

The glow covers the texels the reticle texture authors red, as vanilla draws the ACOG today: the chevron and the upper half of the drop tree. The rest of the reticle stays black. The reticle fades with the aim like every other sight.

### Tunables

| value | start |
|---|---|
| fiber gain | 5.0, the vanilla `intensity` of the ACOG lens material |
| tritium floor | 5% of the full daylight glow |

Starting values, to be confirmed in game.

### Flow

1. The player holds a weapon with an ACOG. `OpticPower._process` finds the sighted rig and pushes the fiber state to the reticle pass. Nothing is drained.
2. The renderer lights the lens with the sun or moon, ambient light and any local light in range, shadowed by the world.
3. The pass outputs the red glow at that brightness, never below the tritium floor.

### Expected result

* Open ground at noon: the reticle is at full brightness, at least as bright as vanilla draws it today.
* Turning relative to the sun or a lamp does not change the brightness.
* Overcast, dusk and dawn: visibly dimmer, following the sun.
* Inside a building by day: dim. It brightens next to a lamp or a fire and where sunlight comes through an opening.
* Night: the tritium floor, slightly brighter under a clear moon or near a light.
* Dark room aiming out at daylight: dim reticle against a bright image.
* The ACOG shows no charge and takes no battery. The illumination binding and the power draw settings do nothing to it.

## Tradeoffs

* **Renderer lighting over a game state formula.** Lamps, fires and other lights count, shade counts wherever the world casts a shadow, and no light model is maintained in script. The cost is that brightness is whatever vanilla's light setup produces: two tunables shape it, and a change to vanilla's sun, moon or ambient curves shifts it.
* **Shadow reception over the indoor detector.** Any roof or wall dims the reticle, not only the areas vanilla marks as indoor. The cost is a hard step when crossing a shadow edge and a dependency on weapon and attachment meshes staying non shadow casting.
* **Emissive floor over a black reticle.** The reticle stays findable at night. The cost is a constant glow that ignores the scene, which reads slightly brighter than a real tritium lamp against a pitch black image.
* **Always on over a setting.** Nothing to configure and no vanilla fallback for the ACOG while Battery is installed.
* **Fiber response separate from the battery sights.** Their look is untouched. The cost is that the two kinds of reticle respond differently to the same light: a battery lit reticle stays as bright indoors as outdoors.
