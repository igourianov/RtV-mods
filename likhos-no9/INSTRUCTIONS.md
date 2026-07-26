# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader (MML)](https://www.nexusmods.com/roadtovostok/mods/20) v3.2.1 or later (separate install, not bundled with the game)

# Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API**:
- `lib.patch()` on the Weapon_Repair_Kit item (rename, showCondition, compatible list)
- `lib.find()` on the items registry to enumerate every weapon (vanilla and modded)

**Direct resource mutation**:
- Strips every `repair == true` entry from `res://Crafting/Recipes.tres`'s weapons array. Recipes return on uninstall.

**Hooks** (other mods that also replace these will conflict, pick one):
- `Interface.Release` (pre)

# Install / Uninstall

Drop `likhos-no9.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-no9.vmz` from the `mods/` folder and relaunch the game.
