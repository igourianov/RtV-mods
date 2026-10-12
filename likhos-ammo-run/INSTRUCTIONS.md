## Install

Drop `likhos-ammo-run.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

## Uninstall

To uninstall simply delete `likhos-ammo-run.vmz` from the `mods/` folder and relaunch the game.

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item and task definitions):
- `lib.patch()` on `Ammo_46x30`, `Ammo_9x39`, `Ammo_762x54R`, `VSS_Magazine` and `MP7_Magazine` to attach them to the Gunsmith
- `lib.patch()` on the "Ammo Delivery" trader task to change its `deliver` and `receive` lists

Other mods that patch the `deliver` or `receive` list of the same task will conflict.

**Hooks:**
- `Task.Initialize` (post)
