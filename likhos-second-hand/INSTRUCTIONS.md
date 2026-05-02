# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://modworkshop.net/mod/56483) v3.0.1 or later (separate install, not bundled with the game)

# Compatibility

This mod uses both the registry API and one hook through Metro Mod Loader.

**Registry API** (patches item definitions):
- `lib.patch()` on `AKS_74U`, `VSS`, `Remington_870` and `KP_31` to set `slots = ["Primary", "Secondary"]`, shrink `size` by one cell on the long axis, and scale the inventory-sprite fields (`magazineScale` / `opticScale` / `suppressorScale` / `magazineOpticScale` / `magazineSuppressorScale` / `opticSuppressorScale` / `fullyModdedScale` and the matching `*Offset` fields, both float and Vector2) by the same linear factor.

**Pre / post hooks** (compose with other mods):
- `Item.UpdateSprite` (pre + post): for the four resized guns, when the gun is bare (no real magazine / optic / suppressor), the pre hook flips `item.magazine = true` and the post hook flips it back. Vanilla `UpdateSprite` then takes the magazine path instead of its hardcoded-`0.5` inventory-grid branch and uses our factor-scaled `magazineScale`; the equipment-slot auto-fit block then picks up `scalePercentage = magazineScale / 0.5 = factor` so primary and secondary slots render the bare gun at the same proportions as a magazine-loaded gun. Side effect: the bare gun is rendered with `magazineOffset` applied (a few cell-pixels of shift) in both inventory and equipment views, which is the accepted trade-off. The flip is bracketed inside one UpdateSprite call, so no stale flag leaks to other code paths.

This mod does not touch the `tetris` field, so it is fully compatible with mods that do (e.g. Likho's Magdump, which bakes foreign magazines into the AKS-74U tetris).

Other mods that patch the same `slots` / `size` / `*Scale` / `*Offset` fields on these specific weapons will conflict (last write wins).

# Install / Uninstall

Drop `likhos-second-hand.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-second-hand.vmz` from the `mods/` folder and relaunch the game.
