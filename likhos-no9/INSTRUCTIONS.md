## Install

Drop `likhos-no9.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

## Uninstall

To uninstall simply delete `likhos-no9.vmz` from the `mods/` folder and relaunch the game.

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API**:
- `lib.patch()` on the Weapon_Repair_Kit item (rename, showCondition, compatible list)
- `lib.find()` on the items registry to enumerate every weapon (vanilla and modded)

**Direct resource mutation**:
- Strips every `repair == true` entry from `res://Crafting/Recipes.tres`'s weapons array. Recipes return on uninstall.

**Hooks** (other mods that also replace these will conflict, pick one):
- `Interface.Release` (pre)
