# Likho's Magdump

Road to Vostok mod that allows for using cross-compatible magazines as they should be in real life.

Following guns can now use each other's magazines:
* AK-74SU <-> AK-12
* AKM <-> RK variants
* KAR-21 (.223 version) <-> STANAG pattern rifles

## Not in scope / Will not fix

The actual gun in player's hands will still show its default magazine mesh, as it is a part of the gun. To fix this would be way too much effort.

## Compatibility

This mod hooks vanilla methods through Metro Mod Loader:

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `Item.UpdateAttachments`
- `Interface.GetMagazine`

## Install / Uninstall

Drop `likhos-magdump.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-magdump.vmz` from the `mods/` folder and relaunch the game.

## Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader/wiki) v3.0.1 or later (separate install, not bundled with the game)
