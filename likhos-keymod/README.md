# Likho's Keymod

Tired of looking for the loot room keys? This mod adds 3 keys to the traders at the very, VERY low price of 5000 Euro + tip (while supplies last):

* Gunsmith -> Gym key
* Doctor -> Cellar key
* Generalist -> Tunnel key

Note that trader's supply is generated at random from a large pool of items, so the key may not always be there.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://www.nexusmods.com/roadtovostok/mods/20) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item definitions):
- Uses `lib.patch()` on key items to attach them to traders


## Install / Uninstall

Drop `likhos-keymod.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-keymod.vmz` from the `mods/` folder and relaunch the game.
