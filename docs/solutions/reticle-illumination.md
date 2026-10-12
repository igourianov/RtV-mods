# Reticle illumination

## Intent

Magnified optics in VosTac get a switchable reticle illumination on a new key binding. Vanilla bakes the lit look into each reticle texture, so some scopes are always lit, some never and some partly. The solution normalizes that: every illuminated scope starts unlit and the key switches its lit part on and off. An LCM setting picks between the vanilla look, the manual switch and a light sensor that lights the reticle on its own when it gets dark. Batteries are not part of it for now.

## Constraints and assumptions

* Vanilla has no illumination state. The reticle shader outputs only the red channel of the texture, scaled by the material's `intensity`. A texel authored red glows red, a texel authored black is a black etched line.
* The vanilla textures, by how they are authored:

	| Optic | Texture |
	|---|---|
	| `Vudu` | Fully red |
	| `Leopard` | Fully red |
	| `ACOG` | Red chevron and upper stadia, fading to black down the post |
	| `HMR` | Red ring and center dot, black crosshairs |
	| `POSP` | Fully black |
	| `PU` | Fully black |

* VosTac already swaps the reticle shader of every optic with `attachmentData.scope` or `attachmentData.variable` for its own `Shaders/Reticle.gdshader`, in `WeaponRig_Optic._update_reticle`. Red dots and holographic sights keep the vanilla shader, so nothing done in VosTac's shader reaches them.
* A reticle material is a resource shared by every instance of the same optic. It cannot hold a per weapon state. The weapon in hands pushes its state into the material every frame, the way `size`, `opacity` and `shadow` are pushed today.
* VosTac keeps transient state of a weapon as meta on its `slotData`, e.g. `cocked` in `WeaponRig_Fire.gd`. The rig reads the `slotData` of the item in the weapon slot, so the meta survives holstering and redrawing. Vanilla `SlotData.Update` copies no meta, so it is lost wherever the game rebuilds the weapon's `slotData`: on a map transition, on loading a save and on dropping the weapon and picking it up.
* LCM builds a mod's settings from the exported members of `Config.gd`. An exported enum shows as a dropdown of its member names, and a change takes effect while the game runs.
* VosTac already has a notion of daylight: `Hooks/Optic.gd` derives a 0 to 1 daylight factor from `Simulation.time` for the low light dimming, with ramps around sunrise and sunset, and treats shelters as lit. It knows the time of day, not how much light reaches the spot the player stands on.
* Ruled out: batteries, charge and any item cost of illumination.
* Ruled out: red dots and holographic sights (`RDS`, `EXPS`, `Kobra`) and the HAMR's top dot. They stay always lit.
* Ruled out: the `PU`. It has no illumination and keeps its black reticle.
* Ruled out: the `ACOG`. The TA31 modeled in game is lit by its fiber optic and has no switch, so its chevron is always lit, as authored.
* Ruled out: new or edited reticle textures. What lights up comes from the vanilla textures as authored.
* Ruled out: brightness levels, a HUD indicator and persisting the state in the save.
* Ruled out: carrying the manual state across a map transition or a drop and pick up. Losing it there is accepted.
* Ruled out: changing how the lit part glows. The vanilla glow is observed in game to stay clearly visible at night, more so than in daylight, so the lit part keeps it as is.
* Ruled out: a light sensor that measures the light at the player's position. Dark interiors and tunnels in daytime do not trigger it.
## Scope

Owned:

* `likhos-vostac/Shaders/Reticle.gdshader`: how a reticle renders lit and unlit.
* `likhos-vostac/Scripts/ScopeCatalog.gd`: which optics have illumination, what lights up on each, and the daylight factor.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Optic.gd`: the illumination input, the per weapon state, resolving whether the reticle is lit and pushing that to the reticle material.
* `likhos-vostac/Scripts/Config.gd`: the illumination mode setting.
* `likhos-vostac/Scripts/Hooks/Optic.gd`: only where its low light dimming gets the daylight factor from.
* `likhos-vostac/Scripts/Main.gd`: registration of the binding.
* `likhos-vostac/README.md` and `likhos-vostac/CHANGELOG.md`: the lines about reticle illumination.

Context only:

* `mod-lib/Main.gd` and `mod-lib/Inputs.gd`: `register_action` and how a registered action reaches the game's key binding settings.
* `likhos-config-manager/`: how an exported `Config.gd` member becomes a setting.
* `likhos-vostac/Scripts/Audio/AttachmentClickPlayer.gd`: the click a toggled attachment plays.
* `likhos-vostac/Scripts/Hooks/Optic.gd` beyond the daylight factor: the PIP image and its low light dimming, which do not touch the reticle.
* Vanilla `src/Shaders/Reticle.gdshader`, `src/Scripts/Optic.gd` and the reticle materials and textures under `src/Items/Attachments/`.

## Solution

### Illuminated optics

`ScopeCatalog.DATA` states per optic whether it has illumination and what its lit part is. An entry without the field has no illumination.

| Optic | Lit part |
|---|---|
| `Vudu` | As authored: the whole reticle |
| `Leopard` | As authored: the whole reticle |
| `HMR` | As authored: the ring and the center dot |
| `POSP` | The whole reticle, since its texture authors nothing red |
| `ACOG` | None |
| `PU` | None |

An optic that is not in the catalog has no illumination.

### Mode

`Config.gd` exports the illumination mode as an enum in the `Aim tweaks` group, so LCM lists it as `Reticle Illumination`. The mode decides whether an illuminated optic is lit:

| Mode | Lit when | Key |
|---|---|---|
| `Disabled` | Always, and the reticle renders as authored. This is the vanilla look, so the POSP stays black. | Does nothing |
| `Manual`, the default | The weapon's state is on | Flips the weapon's state |
| `Light Sensor` | It is dark outside | Does nothing |

* Dark means the daylight factor is below one half, which is the stretch from sunset to sunrise. A shelter is never dark.
* The daylight factor is the one the low light dimming already uses. `ScopeCatalog` computes it, and both `Hooks/Optic.gd` and the illumination read it from there.
* `Light Sensor` switches the reticle silently and ignores the weapon's state without changing it. Going back to `Manual` shows each weapon's state as it was left.
* A mode change in LCM shows on the next frame.

### State

* The manual state is an on or off state of the weapon, kept as meta on the weapon's `slotData` like `cocked`. It is off until toggled.
* The state belongs to the weapon, not to the optic. Another illuminated optic mounted on the same weapon takes over the state as it is.
* It lasts while the weapon stays in its slot on the current map. A map transition, loading a save, or dropping the weapon and picking it up returns it to off.

### Toggle

* `Main.gd` registers the action `reticle_illumination`, labeled `Reticle Illumination`, with `Y` as the default key. It shows up in the game's key binding settings like VosTac's other actions, in every mode.
* `WeaponRig_Optic` handles the press next to the zoom and secondary optic input, under the same gates, in and out of aim.
* In `Manual` mode a press flips the weapon's state when the active optic has illumination, and plays the attachment click. On any other optic, with no optic, or in another mode, the press does nothing.
* On a HAMR switched to its top dot the press still flips the scope's state. It shows once the aim returns to the scope.

### Rendering

`Reticle.gdshader` takes the illumination from two inputs that `WeaponRig_Optic` pushes to the active optic's reticle material every frame, together with the size, opacity and shadow: whether the reticle is lit, and whether its lit part is the authored one or the whole reticle.

* Unlit: every opaque texel of the reticle is black, whatever the texture authors.
* Lit, authored part: the reticle renders as vanilla does. Red texels glow at the material's `intensity`, black texels stay black. Texels authored in between glow in proportion.
* Lit, whole reticle: every opaque texel glows as a fully red one.
* An optic without illumination, and every optic in `Disabled` mode, renders as authored. That leaves the `PU` black and the `ACOG`'s chevron lit in every mode.

The glow is the same as vanilla's lit reticle in strength and color.

### Release notes

* The README lists the illumination toggle and its three modes under Aiming & Optics and the new binding with the other bindings.
* The changelog entry names the binding and its default key, the four optics, the LCM setting with its modes, that scopes start unlit and that the ACOG, the PU and non magnified sights are not covered.

### Observable result

In `Manual` mode:

* A weapon with a Vudu or a Leopard: the reticle is black on first aim. The key turns the whole reticle red, a second press turns it black again.
* HAMR: unlit, the ring and the dot are black like the crosshairs. Lit, the ring and the dot are red.
* POSP: black as in vanilla until toggled, then the whole reticle is red.
* Holstering a weapon and drawing it again keeps its illumination state. Two weapons carry their states independently.
* After a map transition or loading a save every scope is unlit. So is a weapon that was dropped and picked up again.

In `Light Sensor` mode:

* The four optics are black in daylight and in shelters, and lit from sunset to sunrise, without a key press or a click.
* The key does nothing.

In `Disabled` mode:

* Every reticle looks as in vanilla and the key does nothing.

In every mode:

* ACOG, PU, red dots, holographic sights and a weapon without an optic: the key does nothing and the sight looks as in vanilla. The ACOG's chevron is always lit.

## Tradeoffs

* The vanilla texture's red channel as the illumination mask over new mask textures. The cost is that Leopard and Vudu light up whole, where their real counterparts light only the center.
* A whole reticle rule for the POSP over a dedicated texture. The cost is that its rangefinder scale lights up along with the chevrons.
* State on the weapon over state on the optic item. The cost is that an optic moved to another weapon does not carry its state.
* Transient `slotData` meta over saved state. The cost is that scopes are unlit again after every map transition, every load and every drop and pick up.
* `Manual` as the default. The cost is that Vudu, Leopard and HAMR look different from vanilla until the player finds the key or the setting.
* A light sensor driven by the time of day over one driven by measured light. The cost is a black reticle in a dark building at noon, with no manual override in that mode.
* A light sensor without a manual override over a key that overrides it. The cost is that the player switches the mode in LCM to force the reticle on or off.
