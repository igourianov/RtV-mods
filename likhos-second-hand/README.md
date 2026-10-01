# Likho's Second Hand

Road to Vostok mod that lets a few compact long guns ride in the secondary slot, and trims their inventory footprint to match.

Affected weapons:
* AKs-74U - resize + secondary
* VSS Vintorez - resize + secondary
* Remington 870 - resize + secondary
* KP-31 - resize (was already secondary)
* Mosin - resize (left as primary only)

Each of these now fits in either the primary or secondary slot, with their inventory size reduced by one cell along the long axis. 
KP-31 was already secondary-eligible in vanilla; this mod just shrinks its footprint.
Mosin only resized.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://www.nexusmods.com/roadtovostok/mods/20) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod uses both the registry API and one hook through Metro Mod Loader.

**Registry API** (patches item definitions):
- `lib.patch()` on `AKS_74U`, `VSS`, `Remington_870`, `Mosin` and `KP_31` to set `slots = ["Primary", "Secondary"]` and `size` fields, and mutate `*Offset` and `*Scale` fields

**Pre / post hooks** (compose with other mods):
- `Item.UpdateSprite` (pre + post): Unfortunate hack because vanilla hardcodes default weapon scale instead of reading it form item data

Other mods that patch the same `slots` / `size` / `*Scale` / `*Offset` fields on these specific weapons will conflict (last write wins).

## Install / Uninstall

Drop `likhos-second-hand.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-second-hand.vmz` from the `mods/` folder and relaunch the game.
