# NVG near blur

## Intent

With night vision on, everything close to the eye goes out of focus: hands, weapon, scope body and the picture inside the scope lens. This matches real NVG tubes, which are focused at distance. Today VosTac blurs only the scope picture, with a shader blur inside the lens that runs only while scoped. Replace it with the camera's near depth of field blur, so the whole near field softens the same way in every weapon state.

## Constraints and assumptions

* Camera DOF is a depth-based post-process over the main camera image. It cannot be scoped by layer, and the lens is a surface of the scope mesh, so the lens and the scope body always blur together. That is the wanted result here.
* `CameraAttributesPractical` has one `dof_blur_amount` shared by near and far blur. Any state that turns both on blurs the world and the near field at the same strength.
* Godot keeps only the band between the near and far blur distances sharp. With near blur covering the weapon, far blur must start beyond it.
* Binoculars cannot be raised with NVG on (`BinocularsOverlay.gd`), so the binocular lens blur never meets NVG blur.
* VosTac scope DOF already runs on the Mobile renderer (`gameData.compatibility`). NVG blur does the same and needs no fallback.
* Assumed, unverified: the PIP lens surface writes depth like any opaque surface, so near blur softens the scope picture along with the scope body. The build checks it in game.
* Assumed, unverified: one fixed near blur distance covers the longest rig, including suppressed rifles at the hip, without blurring the world noticeably beyond arm's reach. The build tunes the distance on a few rigs.
* Ruled out: per-layer DOF through a second weapon camera and compositing. Too costly for the result.
* Ruled out: a lens shader that fakes its own depth to stay sharp. Not wanted, the lens blurs with the body.
* Ruled out: README updates.
* The 3.10.2123 CHANGELOG entry is unreleased, so this work goes into it rather than a new version entry.

## Scope

Owned:

* `likhos-vostac/Scripts/Hooks/Camera.gd`: every camera DOF decision while VosTac is loaded.
* `likhos-vostac/mod.txt` `[hooks]` entry for `Camera.gd` and its registration in `likhos-vostac/Scripts/Main.gd`.
* `likhos-vostac/Scripts/Hooks/Optic.gd`: the PIP lens shader swap and its parameters.
* `likhos-vostac/Shaders/PIP.gdshader`: VosTac's PIP lens shader.
* `likhos-vostac/Scripts/Config.gd`: the NVG blur setting.
* `likhos-vostac/INSTRUCTIONS.md`: the replace hook list.
* `likhos-vostac/CHANGELOG.md`: the 3.10.2123 entry.

Context only:

* Vanilla `src/Scripts/Camera.gd`: `DOF`, `UIDOF`, `ScopeDOF` and `ResetDOF`.
* Vanilla `src/Scripts/NVG.gd` and `likhos-vostac/Scripts/Hooks/NVG.gd`: `gameData.NVG` is the NVG on state.
* `likhos-vostac/Scripts/ScopeCatalog.gd`: sets `config.current_scope_mag`.

## Solution

### Camera DOF

VosTac replaces vanilla `Camera.DOF`. The `Camera.ScopeDOF` hook does not exist. `Camera.gd` picks one DOF state per tick, in priority order:

1. **UI.** Settings or the inventory open: vanilla `UIDOF`, unchanged.
2. **NVG.** `gameData.NVG` and the NVG blur setting on, in any weapon state: hip, aim, scope, low ready, inspect, reload. Near blur on, covering the hands and the longest weapon. Far blur off, so the world stays sharp, as through a tube focused at distance. The amount fades toward a fixed NVG strength.
3. **Scope.** The vanilla scope condition (scoped, aiming, not colliding, not inspecting): VosTac scope DOF as it is today. With `zoom_DOF` off it clears DOF. With a magnified optic the world blurs by magnification. Otherwise it falls back to vanilla `ScopeDOF`.
4. **Reset.** Vanilla `ResetDOF`: the amount fades to 0, then near and far blur turn off.

NVG overrides scope DOF while scoped, so the world outside the lens stays sharp under NVG at any magnification. Switching NVG on or off fades the amount at the same rate scope DOF uses, without jumps.

### PIP lens shader

`PIP.gdshader` is VosTac's replacement for the vanilla `res://Shaders/PIP.gdshader`: the vanilla scope picture plus low light transmission. It has no blur. No `PIP_NVG.gdshader` exists. `Optic.gd` swaps it onto every optic's PIP material once and drives transmission as today. The swap check keys on a parameter the shader has.

### Changelog

The 3.10.2123 entry states that NVG blurs hands, weapon and scope in every state instead of only the scope picture, and that the setting is renamed to NVG blur and re-enabled once.

### Setting

The LCM setting `NVG_blur` (default on) turns NVG near blur on and off. It replaces `NVG_PIP_blur`.

### Observable result

* NVG on, weapon at the hip or lowered: hands and weapon are soft, the world is sharp.
* NVG on, scoped with any optic: scope body and scope picture are soft, the world outside the lens is sharp.
* NVG off: scope DOF and UI blur behave as they do today.
* NVG blur setting off: no blur from NVG in any state.

## Tradeoffs

* Camera near blur over the lens shader blur. Cheaper on the GPU and blurs the whole near field. The cost is less control: strength depends on the user's DOF quality setting and screen resolution, and anything within arm's reach blurs too, such as a wall you stand against.
* NVG overrides scope DOF over combining them. The shared amount would otherwise blur the world at NVG strength even on a 1x optic. The cost is losing the magnification world blur while scoped under NVG.
* Replacing `Camera.DOF` over hooking `ScopeDOF` and `ResetDOF` separately. One flat decision covers every state. The cost is a conflict with any other mod that replaces `Camera.DOF`.
* Renaming the setting to `NVG_blur` over keeping `NVG_PIP_blur`. The label now matches what it does. The cost is that players who turned it off get it back on once.
