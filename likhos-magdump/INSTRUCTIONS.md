## Install

Drop `likhos-magdump.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

## Uninstall

To uninstall simply delete `likhos-magdump.vmz` from the `mods/` folder and relaunch the game.

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item definitions):
- Uses `lib.patch()` on gun items to inject foreign magazines into their tetris scenes and compatible attachments

**Replace hooks** (other mods that also replace these will conflict, pick one):
- `Interface.GetMagazine` (necessary for mag reloading to work)

**Pre and Post hooks** (additive, run before/after vanilla, coexist with other mods cleanly):
- `WeaponRig._ready` (post)
- `RigManager.UpdateRig` (pre)
- `Pickup._ready` (post)
