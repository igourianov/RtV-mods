## Install

Drop `likhos-battery.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

## Uninstall

To uninstall simply delete `likhos-battery.vmz` from the `mods/` folder and relaunch the game.

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item definitions):
- `lib.patch()` on `Batteries` to set `showCondition`
- `lib.patch()` on every laser (`subtype` `Laser`) to set `showCondition`, and `power` to `Medium` where it has none
- `lib.append()` on every laser to add `Batteries` to `compatible`
- `lib.patch()` on the sights `SRO`, `RMR`, `PRO`, `MRO`, `Micro`, `EXPS`, `Kobra`, `Vudu`, `Leopard`, `POSP` and `HMR` to set `showCondition`, and `power` where it has none. The `power` values are 4 for a red dot and 5 for an illuminated scope, which vanilla does not name
- `lib.append()` on the same sights to add `Batteries` to `compatible`

**Hooks** (other mods that also replace these will conflict, pick one):
- `Interface.Charge` (replace)
- `Interface.ContextRemove` (replace)
- `Item.Value` (replace)
- `Interface.Hover` (post)
- `Interface.Create` (pre)
- `Item.Remove` (pre)
- `Item.CombineSwap` (pre)
- `Item.Combine` (post)
- `Context.Update` (post)
- `Laser._process` (post)
- `Flashlight.Activate` (post)
- `NVG.Activate` (post)
- `Tooltip.Update` (post)
- `LootContainer.CreateLoot` (post)
- `LootSimulation.SpawnItems` (post)
- `Inputs.CreateActions` (pre and post)
- `Inputs.ResetActions` (post)

[Likho's Config Manager](https://vostokmods.net/mod/likhos-config-manager) is optional. Without it sights run on the default settings: red dots need charge and scope illumination is switched by the binding.

The reticle of every powered sight is drawn by a second material that this mod chains to the sight's lens material as `next_pass`, and the lens material's own reticle texture is replaced by a blank one. A mod that sets `next_pass` on those materials or swaps reticle textures at runtime will conflict.

The charge of a laser attached to a weapon is kept in the weapon's `storage`, which vanilla uses for furniture only. A mod that reads or clears `storage` on weapons will conflict.
