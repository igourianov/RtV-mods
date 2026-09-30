# Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://www.nexusmods.com/roadtovostok/mods/20) v3.4.1 or later (separate install, not bundled with the game)

# Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item definitions):
- Uses `lib.patch()` on gun items to inject foreign magazines into their tetris scenes and compatible attachments

**Replace hooks** (other mods that also replace these will conflict, pick one):
- `Interface.GetMagazine` (necessary for mag reloading to work)

**Pre and Post hooks** (additive, run before/after vanilla, coexist with other mods cleanly):
- `WeaponRig._ready` (post)
- `RigManager.UpdateRig` (pre)
- `Pickup._ready` (post)

# Install / Uninstall

Drop `likhos-magdump.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-magdump.vmz` from the `mods/` folder and relaunch the game.
