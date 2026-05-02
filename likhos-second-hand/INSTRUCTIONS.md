# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://modworkshop.net/mod/56483) v3.0.1 or later (separate install, not bundled with the game)

# Compatibility

This mod uses the registry API through Metro Mod Loader to patch item definitions. It registers no hooks.

**Registry API** (patches item definitions):
- `lib.patch()` on `AKS_74U`, `VSS`, `Remington_870` and `KP_31` to set `slots = ["Primary", "Secondary"]` and shrink `size` by one cell on the long axis.

Other mods that patch the same `slots` or `size` fields on these specific weapons will conflict (last write wins).

# Install / Uninstall

Drop `likhos-second-hand.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-second-hand.vmz` from the `mods/` folder and relaunch the game.
