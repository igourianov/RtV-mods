# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://modworkshop.net/mod/56483) v3.0.1 or later (separate install, not bundled with the game)
- [Mod Configuration Menu](https://modworkshop.net/mod/53713)

# Compatibility

This mod hooks multiple vanilla methods through Metro Mod Loader:

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `Handling.WeaponHandling`
- `WeaponRig._input`
- `WeaponRig.UpdateAimOffset`
- `Laser._input`
- `Controller.MovementStates`
- `Controller._input`
- `Character.Stamina`

**Pre and Post hooks** (additive, run before/after vanilla, coexist with other mods cleanly):

- `WeaponRig.AmmoCheck` (pre and post)
- `WeaponRig.ADS` (post)
- `Camera.ScopeDOF` (post)
- `WeaponRig.Insert` (post)
- `Noise._physics_process` (post)
- `Tilt._physics_process` (pre)
- `HUD._ready` (post)
- `Recoil.ApplyRecoil` (post)
- `Optic._physics_process` (pre)
- `RigManager.UpdateRig` (post)
- `Inputs.CreateActions` (post)
- `Inputs.ResetActions` (post)

# Install / Uninstall

Drop `likhos-weapon-handling-fixes.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically. The first time you install or update a mod, the loader does a one-shot restart to finish wiring the hooks. After that, no more restarts.

To uninstall simply delete `likhos-weapon-handling-fixes.vmz` from the `mods/` folder and relaunch the game.
