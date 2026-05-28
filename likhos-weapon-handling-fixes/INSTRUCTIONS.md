# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader/releases) v3.2.1 or later (separate install, not bundled with the game)
- [Mod Configuration Menu](https://modworkshop.net/mod/53713) (optional)

# Compatibility

This mod hooks multiple vanilla methods through Metro Mod Loader:

- `WeaponRig` and `Handling` objects - basically rewritten. Will conflict with pretty much anything that touches them.

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `Camera.ScopeDOF`
- `Controller.MovementStates`
- `Controller._input`
- `Controller.Crouch`
- `Laser._input`
- `Flashlight._physics_process`
- `Character.Stamina`

**Pre and Post hooks** (additive, run before/after vanilla, coexist with other mods cleanly):

- `RigManager.UpdateRig` (post)
- `Recoil.ApplyRecoil` (post)
- `Noise._physics_process` (post)
- `Tilt._physics_process` (pre)
- `HUD._ready` (post)
- `Optic._physics_process` (pre)
- `Laser._process` (post)
- `Tooltip.Update` (post)
- `Inputs.CreateActions` (pre and post)
- `Inputs.ResetActions` (post)
- `Interactor._physics_process` (pre)

# Install / Uninstall

Drop `likhos-weapon-handling-fixes.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically. The first time you install or update a mod, the loader does a one-shot restart to finish wiring the hooks. After that, no more restarts.

To uninstall simply delete `likhos-weapon-handling-fixes.vmz` from the `mods/` folder and relaunch the game.
