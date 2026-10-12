# Likho's Ammo Run

Makes 4.6x30 and 9x39 available from Gunsmith. Reworks "Ammo Delivery" task.

## Features

Gunsmith now sells 4.6x30, 9x39 and 7.62x54R ammo. The idea is to make exotic ammo actually usable in game instead of being a safe queen.

The "Ammo Delivery" task reworked:

| | Vanilla | Modded |
|---|---|---|
| Deliver | 1 box of 4.6x30, 9x39 and 7.62x54R | Full stack (300 rounds) of 7.62x39 and .223 |
| Reward | LVPC (Winter) rig and Armor Plate (IV) | 3 boxes of 4.6x30 and 9x39 |

Note that trader's supply is generated at random from a large pool of items, so a given caliber may not always be there.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item and task definitions):
- `lib.patch()` on `Ammo_46x30`, `Ammo_9x39` and `Ammo_762x54R` to attach them to the Gunsmith
- `lib.patch()` on the "Ammo Delivery" trader task to change its `deliver` and `receive` lists

Other mods that patch the `deliver` or `receive` list of the same task will conflict.

**Hooks:**
- `Task.Initialize` (post)

## Install / Uninstall

Drop `likhos-ammo-run.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-ammo-run.vmz` from the `mods/` folder and relaunch the game.
