# Likho's Oculus

## Intent

Split VosTac's scope and aiming changes and fixes into a separate mod, "Likho's Oculus" (`likhos-oculus`). The two mods are independent: each runs alone or together with the other, and neither detects or loads the other. The one point where they meet is the zoom level contract: Oculus declares a zoom level count on an optic, and VosTac marks that it reads it, falling back to vanilla's 3.

The split follows one line. VosTac drives controls and player interactions: zoom input, the secondary sight toggle, bindings and the aim poses of its handling. Oculus drives scope effects: what a given zoom level and sight choice look and feel like.

The scoped walk speed multiplier is dropped, not moved.

## Constraints and assumptions

### Constraints

* The controls and effects line decides ownership of any feature this doc does not name. Input, bindings, sight and zoom choices, their persistence and the handling poses belong to VosTac. What the eye sees and feels through the optic belongs to Oculus.
* No coupling between the two mods beyond the zoom level contract below. No detection, no `load()` of the other mod's scripts, no shared config or state object. The other channels are vanilla game state (`GameData`, rig, optic, `SlotData`, Handling and Noise node properties) and hook priority order.
* Zoom level contract, in two metadata fields:
	* An optic's `AttachmentData` may carry a `zoom_levels` int, the number of zoom levels its effects provide. A controls mod steps `slotData.zoom` from 1 to that count, and treats a variable optic without it as having vanilla's 3. Oculus writes it, VosTac reads it.
	* `gameData` may carry a `zoom_levels_reader` bool, set by a controls mod that reads `zoom_levels`. Without it, vanilla controls step only 3 levels. VosTac writes it, Oculus reads it. `GameData.tres` is never saved to disk, so the marker lasts one session.
* The shared zoom state is vanilla's `slotData.zoom`, saved with the weapon. The shared sight choice is vanilla's `gameData.secondaryOptic`.
* A replace hook has one owner. VosTac keeps its replace hooks on `WeaponRig._input`, `WeaponRig._physics_process`, `Handling.WeaponHandling`, `Controller._input` and `Controller.MovementStates`. Oculus reaches those methods only through pre and post hooks and through the vanilla state they read.
* VosTac applies the Handling target in its `Handling.WeaponHandling` post hook at priority 200. A post hook at the default priority sets `targetPosition` before VosTac moves the rig toward it. Under vanilla, the same post hook runs after vanilla has moved the rig, so the target it sets takes effect one frame later.
* `Handling.handlingSpeed` is an authored per-rig value that vanilla never writes. Vanilla and VosTac both read it as the base rate the rig closes on its target.
* Vanilla `Noise._physics_process` eases the Noise node's position toward its bob curve from the previous position. Scaling that position once and leaving it scaled compounds every frame. VosTac's Noise post hook assigns the position fresh each frame.
* Vanilla `WeaponRig._input` steps `slotData.zoom` 1 to 3 on the mouse wheel while aiming a variable optic, and toggles `gameData.secondaryOptic` while aiming an optic with a secondary sight node. Vanilla `WeaponRig._ready` clears `gameData.secondaryOptic` on every draw. Vanilla `UpdateAimOffset` ignores the optic's scale for the secondary sight height and rotates the front sight bone even on rigs without one.

### Ruled out

* Oculus requiring VosTac, VosTac requiring Oculus, or either one detecting the other.
* Zoom input, zoom bindings, out-of-aim zoom or the secondary sight toggle in Oculus. Oculus alone keeps vanilla's controls.
* Scoped walk speed scaling (`walk_scope_mult`) in either mod. Aiming a scope walks at the aim walk speed.
* Oculus writing `gameData.scopeSensitivity` or any other preference value, even temporarily. Preferences are saved from `GameData`, and a scaled value could be written to disk.
* Laser zeroing, NVG near blur, optic handling speed and binoculars in Oculus. All stay in VosTac.

### Assumptions (unverified)

* MML runs pre and post hooks of a method whose replace hook calls `skip_super()`. Oculus depends on this for `Controller._input` under VosTac.
* The `InputEventMouseMotion` passed to `Controller._input` hooks is the instance vanilla and VosTac read, and its `relative` can be rewritten in a pre hook and restored in a post hook.
* An optic's `attachmentData` on a live rig is the same resource instance as the registry's item entry, so metadata set on the entry at setup is visible on every rig.

## Scope

Owned:

* `likhos-oculus/`: the whole mod. `mod.txt`, `README.md`, `INSTRUCTIONS.md`, `CHANGELOG.md`, `Scripts/`, `Shaders/`.
* `likhos-vostac/`: every module that holds optic or aiming code today. `Scripts/Main.gd`, `Scripts/Config.gd`, `Scripts/ScopeCatalog.gd`, `Scripts/RigOpticPatches.gd`, `Scripts/Hooks/Handling.gd`, `Scripts/Hooks/WeaponRig.gd`, `Scripts/Hooks/Camera.gd`, `Scripts/Hooks/Controller.gd`, `Scripts/Hooks/Noise.gd`, `Scripts/Hooks/Optic.gd`, `Scripts/Hooks/Recoil.gd`, `Scripts/Hooks/Tooltip.gd`, `Scripts/Hooks/SlotMeta.gd`, `Scripts/Nodes/WeaponRig_Optic.gd`, `Scripts/Nodes/WeaponRig_Shadow.gd`, `Scripts/Nodes/FiberReticle.gd`, `Shaders/Reticle.gdshader`, `Shaders/PIP.gdshader`, `mod.txt`, `README.md`, `INSTRUCTIONS.md`, `CHANGELOG.md`.

Context only, not changed:

* `src/` vanilla scripts: `WeaponRig.gd`, `Handling.gd`, `Controller.gd`, `Camera.gd`, `Noise.gd`, `Optic.gd`, `Recoil.gd`, `RigManager.gd`.
* `mod-lib/`: used as is by both mods.
* `likhos-battery/`: its optic illumination works on whatever lens shader is in place and needs no change. Its README mentions VosTac for the ACOG fiber reticle.
* `publish.config.json`: Oculus gets an entry once its Nexus page exists.

## Solution

### Likho's Oculus

Optional LCM integration like VosTac: it runs on defaults without LCM. It registers no input actions.

**Config.** Oculus's own config, registered with LCM under its own id: `magnification_schema`, `PIP_anti_aliasing`, `zoom_DOF`, `debug_enabled`. Runtime state: the current scope magnification.

**ScopeCatalog.** Moves from VosTac: per-optic magnification ranges per schema (Short, Normalized, Discrete, an optic without the chosen schema falling back to Short), eye relief, lens geometry (catalog values or measured from the lens mesh), fiber-lit flag and fallback entries for scopes added by other mods (`is_unknown`). Short has exactly 3 magnifications on every variable optic, one per vanilla zoom level, spanning its real range: Vudu 1-10x, Leopard 1.1-8x, POSP 2-6x, fallback 1.1-6x. A fixed optic has one. It declares `zoom_levels` on each known variable optic's `AttachmentData` as the size of its range under the current schema, at setup and whenever the schema setting changes. Unknown scopes get no declaration, since vanilla ADS drives them in 3 levels. The chosen schema applies while `gameData` carries `zoom_levels_reader`. Without it, Oculus uses Short whatever the setting, so vanilla's 3 levels cover each optic's whole range. The marker is read when a range is used, not at setup, so mod load order does not matter. It holds the optic state sync: `gameData.isScoped` and the current magnification read from `slotData.zoom`, clamped into the range. Oculus reads the rig's `aimOffset` and never writes it. It applies the item registry patches: HMR and Vudu legendary, POSP 2-6x variable with fixed reticle size, Vudu and Leopard PIP reticle sizes.

**RigOpticPatches.** Moves from VosTac as it is: the rail range, default position and rail movement patches through `SCENE_NODES`, and the clamp of a saved rail position into the patched range.

**Rig update.** A `RigManager.UpdateRig` post hook clamps the rail position and syncs the optic state. A `RigManager.ClearRig` post hook resets it.

**ADS.** A replace hook on `WeaponRig.ADS`. An unknown scope runs vanilla ADS. Otherwise, every frame, it syncs the optic state, keeps `aimFOV` at base FOV in PIP and divides it by magnification outside PIP, eases ocular opacity and reticle size (FFP reticles change size across the range, SFP keep it), sets the PIP camera FOV from the lens's angle at the eye divided by magnification, and puts Oculus's reticle shader on magnified optics' lens material. LPVOs stay scoped at their lowest level. With the secondary sight chosen on a scope, the lens clears and the optic is not scoped, whether the choice is the optic's own secondary sight or a sight Oculus does not know about.

**Aim pose.** A `Handling.WeaponHandling` post hook at the default priority. While aiming a known scoped optic in PIP, it sets `targetPosition` depth so the eye sits at the optic's near eye relief plus a margin behind the lens center, wherever the optic sits on the rail. Height comes from the rig's `aimOffset`.

**Scope shadow node.** Injected into each rig by a `WeaponRig._ready` post hook. Moves from VosTac's `WeaponRig_Shadow`: the swing, exhaustion, stance kick, lean and aim channels, the random turn per aim and the shadow offset pushed to the reticle shader of magnified optics. The aim channel's follower eases at the Handling node's authored `handlingSpeed`, not VosTac's final rate.

**Fiber reticle.** Moves from VosTac as it is: a mod-lifetime node that glows a fiber-lit reticle (ACOG) by the light on its collector, through `LightProbe`, never below the tritium glow.

**Optic hook.** Moves from VosTac as it is: an `Optic._physics_process` pre hook that mirrors the game's MSAA and SMAA settings onto the PIP SubViewport (`PIP_anti_aliasing`) and puts Oculus's PIP shader on the lens with the NVG exposure correction.

**Scope DOF.** A `Camera.DOF` post hook. While aiming a scoped optic outside the settings and interface, and with `zoom_DOF` on, it sets near and far blur with an amount that grows with magnification from 1x. With `zoom_DOF` off it clears the blur. It eases its own amount rather than the attribute's value, so vanilla's own DOF step that ran before it does not drag it.

**Scoped sensitivity.** A pre and post hook pair on `Controller._input`. While aiming a scoped optic, the pre hook scales the mouse motion event's `relative` by the inverse of magnification, eased on zoom and aim changes. The post hook restores it. Vanilla and VosTac both read the scaled motion with their own scope sensitivity.

**Scoped bob.** A pre and post hook pair on `Noise._physics_process`, the post at a priority after VosTac's Noise post hook. While aiming a scoped optic in PIP, the bob displacement is scaled by the stance factor (walk 40%, crouch 15%, run 100%, standing still 0%). The pre hook takes the scaling back out before the Noise node eases from it, so under vanilla it does not compound.

**Scoped recoil.** Moves from VosTac as it is: a `Recoil.ApplyRecoil` post hook that cuts the backward kick while aiming a scoped optic.

**Tooltip.** Moves from VosTac as it is: magnification and eye relief rows on known magnified optics.

**Shaders.** `Reticle.gdshader` (lens UV reticle, FFP and SFP, swing shadow, fiber glow, narrow rim) and `PIP.gdshader` move from VosTac under Oculus's path.

**Docs.** README lists the scope effects VosTac lists today under "Aiming & Optics", "PIP mode" and "Optics": eye relief, PIP rework, LPVO 1x scoping, magnification schemas (noting that without a controls mod such as VosTac every optic zooms in 3 levels), scope DOF, PIP MSAA, scope shadow, fiber ACOG, optic rebalances, rail tuning, scope tooltips and the PIP bob fix, plus sensitivity by zoom and scoped recoil. INSTRUCTIONS lists its hooks by kind and says it runs with or without VosTac. CHANGELOG starts with the first release.

### VosTac

VosTac owns the optic controls and keeps vanilla scope effects where Oculus is absent.

**Optic input node.** Injected into each rig as now. Zoom steps `slotData.zoom` from 1 to the optic's declared `zoom_levels`, or 3 without one, on a variable optic, on the `optic_zoom_in` and `optic_zoom_out` actions with input acceleration and the zoom click. It works while aiming, and out of aim per `zoom_out_of_aim` (enabled, disabled, or with the Rail Movement binding held). The secondary sight toggle works in and out of aim on an optic with a secondary sight node, or on the PU on the Mosin and M28, where it switches to iron sights. Each weapon keeps its own choice in its `SlotData` metadata, restored over vanilla's reset when the weapon is drawn and carried across saves by `SlotMeta`. A choice the newly equipped optic cannot have is cleared (the HAMR PIP reset fix).

**Zoom level marker.** VosTac sets `zoom_levels_reader` on `gameData` at setup.

**ADS and optic state.** VosTac has no ADS hook and no magnification state. Vanilla ADS and vanilla `isScoped` apply.

**Handling.** Handling modes are aim, red dot (115%), magnified (80%), canted and default. VosTac picks them from vanilla state alone: an optic that is scoped is magnified, except a variable optic at its lowest zoom level. Any other optic is a red dot. The aim pose with an optic is the rig's `aimOffset` at the weapon's authored aim depth. With iron sights chosen under a scope, it is the weapon's own aim pose. VosTac owns the rig's `aimOffset` and sets it on rig update and on every sight toggle: the optic's height, or with the secondary sight chosen, the secondary sight node's height corrected for the optic's scale (the HAMR offset fix). The rig update post hook keeps the weapon weight, weapon action, collision probe and free look baseline, clamps a saved zoom level into the optic's level count, and folds the iron sights for optic presence with the front sight index check (the M4A1 flicker fix with the HAMR). VosTac keeps no handling rate in its config.

**Controller.** Scoped aim sensitivity is `scopeSensitivity`, eased like the other sensitivities, with no magnification term. Movement has no scoped walk speed. Aiming walks at `walk_aim_mult`.

**Camera.** A `Camera.DOF` post hook at priority 200, in place of the replace hook. It applies the NVG near blur when `NVG_weapon_blur` is on and NVG is active outside the settings and interface. Running after Oculus's post hook, it wins over the scope DOF under NVG. It eases its own amount.

**Noise.** The bob runs off the controller's phase as now, with no PIP scoped factor.

**Rig nodes.** VosTac injects Fire, Reload, ManualReload, Optic (input only) and Inspect. No shadow node. Binoculars and inspect rail movement keep their zoom bindings, acceleration and click.

**Config.** `zoom_out_of_aim` stays. No `magnification_schema`, `PIP_anti_aliasing`, `zoom_DOF`, `walk_scope_mult`, current scope magnification or current handling rate.

**Docs.** README drops the moved effects, the magnification schemas and the scoped walk breakpoint, describes LPVO zoom as 3 levels or as many as the scope mod declares, and points to Oculus for scope effects. INSTRUCTIONS drops the moved hooks. CHANGELOG notes the split under `Unreleased`.

### Result

* Oculus alone: Oculus's scope effects (eye relief, PIP, reticles, scope shadow, real magnifications, scope DOF, scoped sensitivity, bob and recoil) driven by vanilla controls: wheel zoom in 3 levels across each optic's range and secondary sight toggle while aiming.
* VosTac alone: VosTac's controls (zoom bindings, out-of-aim zoom, secondary sight anywhere, Mosin and M28 iron sights, per-weapon sight choice) and optic handling speed over vanilla scope effects, plus the rest of VosTac.
* Both: VosTac's controls driving Oculus's effects, through every level of the chosen schema.

## Tradeoffs

* **Zoom level contract.** Two metadata fields couple the mods, for the magnification schemas with more than 3 levels. Under Oculus alone the schema setting has no effect.
* **Saved zoom above 3.** A zoom level above 3 saved while both mods ran outlives VosTac's removal. Under Oculus alone, vanilla's wheel steps up from it without bound while Oculus holds the picture at the top magnification. If both mods are removed, vanilla ADS has no matching level.
* **No coupling over a shared contract.** Oculus shapes VosTac's behavior only through vanilla state it scales (mouse motion, Noise position). Each seam is a pre and post pair or a per-frame overwrite rather than a direct call, and a third mod writing the same property breaks it.
* **Fixes split by owner.** The HAMR offset, HAMR PIP reset and M4A1 flicker fixes need VosTac. Oculus alone keeps those vanilla bugs. Running either mod alone keeps the other's vanilla bugs.
* **Scope shadow aim channel.** It follows the authored rate. Under VosTac the rig moves at VosTac's optic, stance and weight rate, so the aim crescent lasts a little longer or shorter than the rig's travel on very light or very heavy weapons.
* **LCM settings.** The moved settings start at Oculus's defaults (Normalized schema, as in VosTac today). Values a player set in VosTac are not carried over.
