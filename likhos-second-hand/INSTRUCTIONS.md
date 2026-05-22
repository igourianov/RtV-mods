# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://modworkshop.net/mod/55623) v3.0.1 or later (separate install, not bundled with the game)

# Compatibility

This mod uses both the registry API and one hook through Metro Mod Loader.

**Registry API** (patches item definitions):
- `lib.patch()` on `AKS_74U`, `VSS`, `Remington_870`, `Mosin` and `KP_31` to set `slots = ["Primary", "Secondary"]` and `size` fields, and mutate `*Offset` and `*Scale` fields

**Pre / post hooks** (compose with other mods):
- `Item.UpdateSprite` (pre + post): Unfortunate hack because vanilla hardcodes default weapon scale instead of reading it form item data

Other mods that patch the same `slots` / `size` / `*Scale` / `*Offset` fields on these specific weapons will conflict (last write wins).

# Install / Uninstall

Drop `likhos-second-hand.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-second-hand.vmz` from the `mods/` folder and relaunch the game.
