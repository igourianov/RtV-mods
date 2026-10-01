# Likho's No.9

RtV mod that reworks functionality of the Weapon Repair Kit into a Cleaning Kit (reference to iconic Hoppe's No.9).

Typical gun requires repair only after 10s of thousands of rounds, and it cannot be done in field conditions anyway (unless it's something very trivial like replacing firing pin). Gun cleaning makes much more sense in terms of the action mechanics and the shooting volume in this game.

## Weapon Repair Kit

The old Weapon Repair Kit was awkward: pick a per gun recipe from the crafting menu, hand over a full kit, get the gun back. Twenty plus duplicated recipes cluttering the crafting tab. This mod replaces all of that with a single drag and drop interaction.

* Renamed to **Weapon Cleaning Kit**.
* Drag any weapon onto the kit - the weapon's missing condition gets restored from the kit's own condition pool.
* The kit is **NOT CONSUMED** on use, but loses condition by the same amount it restored.
* Per gun repair recipes are removed from the crafting menu.
* Added refill recipe for the kit.
* Should be compatible with weapons added by other mods (place them before this mod in load order).

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API**:
- `lib.patch()` on the Weapon_Repair_Kit item (rename, showCondition, compatible list)
- `lib.find()` on the items registry to enumerate every weapon (vanilla and modded)

**Direct resource mutation**:
- Strips every `repair == true` entry from `res://Crafting/Recipes.tres`'s weapons array. Recipes return on uninstall.

**Hooks** (other mods that also replace these will conflict, pick one):
- `Interface.Release` (pre)

## Install / Uninstall

Drop `likhos-no9.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-no9.vmz` from the `mods/` folder and relaunch the game.
