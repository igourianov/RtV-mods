# PIP eye relief

## Intent

Invert the VosTac eye relief logic in PIP mode. Today the player has to slide the optic along the rail until the camera falls inside the optic's eye relief, and outside it the scope picture shrinks into a black shadow. Players read that as a broken scope. Instead, ADS with a magnified optic in PIP mode brings the eye to the optic's optimal eye relief for wherever the optic is mounted, so a scope never blacks out from its placement. The code gets simpler along the way.

## Constraints and assumptions

* Eye relief values in `ScopeCatalog.DATA` are real optic specs in cm, stored as a near and far bound. The range stays in the catalog because the tooltip shows it.
* The optimal eye relief of an optic is its near bound plus 0.5 cm. The far bound is informational only.
* Rail movement in inspect mode (`WeaponRig_Inspect.gd`, `RigOpticPatches.gd`) stays as it is. Placement now decides where the optic and the eye sit along the weapon, not how good the picture is.
* The vanilla camera sits at the origin of the Handling node's parent, and the eye to lens distance along the bore is the lens center depth in the optic's rest pose plus the Handling node's Z position. This is what `WeaponRig_Optic` computes today for the shadow and the PIP FOV. Assumed, unverified: that measure matches the real camera to lens distance closely enough to land the eye where intended on every rig. The build checks it with debug output against the global camera to lens distance on a few rigs.
* The eye target uses the optic's rest pose only. Recoil, sway, noise and tilt live below Handling and must not move the target, or the camera would chase the recoil.
* With the shadow at 0 the shader's aperture mask sits outside the lens radius, so removing the shadow changes nothing in a settled ADS picture. Verified by reading `Reticle.gdshader`.
* No other mod in the repo reads the reticle `shadow` uniform. `lens_uv_scale` is read by Likho's Battery Powered and stays.
* Ruled out: narrowing rail ranges per optic. Supplied later as separate work in `RigOpticPatches.gd`.
* Ruled out: non-PIP mode. Its ADS pose is vanilla: the aim depth is `data.aimPosition.z`, as in vanilla `Handling.gd`, with no eye relief logic, no shadow and no too close check.
* Ruled out: any optic too close check, in any mode. An optic mounted close to the camera in non-PIP mode or on a non-magnified sight is accepted as is.
* Ruled out: README and CHANGELOG updates for now.
* Ruled out: scope shadow in any form, including a transitional shadow while the optic travels to the eye.
* Ruled out: eye relief that varies with magnification on variable optics.
* Ruled out: clamping the eye target. Extreme placements are bounded by the rail ranges.

## Scope

Owned:

* `likhos-vostac/Scripts/ScopeCatalog.gd`: eye relief data, the optic geometry including the optic's lens depth in rest pose, and the aim depth of a rig with an optic.
* `likhos-vostac/Scripts/Hooks/Handling.gd`: the ADS aim target and the aim intent resolution in `_resolve_aim_intent`.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Optic.gd`: ADS state, PIP camera FOV and reticle push.
* `likhos-vostac/Scripts/Config.gd`: only the dynamic state vars tied to ADS.
* `likhos-vostac/Shaders/Reticle.gdshader`: the scope mask.

Context only:

* `likhos-vostac/Scripts/Hooks/Tooltip.gd`: shows the eye relief range, unchanged.
* `likhos-vostac/Scripts/Nodes/WeaponRig_Inspect.gd` and `likhos-vostac/Scripts/RigOpticPatches.gd`: rail movement and rail ranges.
* `likhos-vostac/Scripts/Hooks/Optic.gd`: PIP viewport, NVG blur and low light dimming.
* Vanilla `src/Scripts/Handling.gd` and `src/Scripts/Optic.gd`.

## Solution

### Optic geometry

`ScopeCatalog` is the single source of an optic's geometry. For the active optic it provides the lens center and radius, the FFP flag and the lens depth in the rig's Handling space for the optic's current rail position in rest pose. Lens center and radius keep the existing fallback that measures them from the lens mesh when the catalog does not state them.

### Aim depth

`ScopeCatalog` owns the aim depth of a rig with an optic: the Handling target Z for ADS. It decides the number for every optic type and mode, including the fallback:

* In PIP mode with a magnified optic active (`gameData.isScoped`, so not on a HAMR switched to its top dot) and catalog eye relief, the aim depth puts the eye exactly at the optic's optimal eye relief behind the lens.
* Every other aim with an optic keeps the weapon's `data.aimPosition.z`: red dots and holographic sights, a secondary sight, non-PIP mode and a magnified optic without catalog eye relief.

`Handling._set_target` uses the number as is, with `rig.aimOffset` as the vertical aim offset as today. It holds no eye relief logic and no fallback of its own. With no optic it aims at `data.aimPosition`.

There is no per weapon aim depth table. The optic data and its rail position alone decide the eye position in PIP scoped ADS.

### ADS in `WeaponRig_Optic`

* The PIP camera FOV follows the live eye to lens distance, so it widens as the optic comes to the eye and settles at the value set by the optimal eye relief.
* The reticle material gets size and opacity. There is no shadow input.
* ADS never cancels the aim or deals damage over optic placement. Aim intent in `Handling` comes from the input bus alone.

### Reticle shader

The scope mask is the lens rim alone. The shader has no shadow uniform and no aperture mask.

### Observable result

* PIP mode, any magnified optic at any rail position: ADS settles with the full scope picture, no black ring. Moving the optic along the rail in inspect moves where the camera sits along the weapon on the next ADS, and the scope picture stays full.
* The same optic at the same eye relief gives the same PIP FOV on every weapon.
* An ACOG sits much closer to the eye than a Leopard or Vudu.
* HAMR switched to its top dot, red dots and non-PIP mode aim as they do today.
* No placement gives a shiner, in any mode.

## Tradeoffs

* Forced eye position over player placed optics. The cost is losing the eye relief penalty, for example the ACOG on Combloc rifles, and the rail no longer tunes picture quality.
* Per optic eye relief over the per weapon PIP aim depth table. The cost is losing hand tuned cheek weld per weapon in PIP scoped ADS. Placements the old table masked may now put the camera visibly far forward or back until rail ranges are narrowed.
* Near bound plus 0.5 cm over the range midpoint. It gives the widest scope picture with a small margin. The cost is that every optic sits at the close end of its spec.
* PIP only over both modes. The cost is that non-PIP mode still shows whatever the vanilla aim depth gives, including an optic mounted too close to the camera.
* No too close check over keeping the shiner. The cost is no penalty for a bad placement in non-PIP mode.
* Removing the shadow over keeping it for the transition. The cost is that the scope picture shows at full size while the optic is still travelling to the eye.
