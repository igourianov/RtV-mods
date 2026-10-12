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

**Hooks** (other mods that also replace these will conflict, pick one):
- `Interface.Charge` (replace)
- `Interface.ContextRemove` (replace)
- `Interface.CombineCheck` (replace)
- `Item.Value` (replace)
- `Interface.Create` (pre)
- `Item.Remove` (pre)
- `Item.CombineSwap` (pre)
- `Item.Combine` (post)
- `Context.Update` (post)
- `Laser._process` (post)
- `Flashlight.Activate` (post)
- `Tooltip.Update` (post)
- `Tooltip.Reset` (post)
- `LootContainer.CreateLoot` (post)
- `LootSimulation.SpawnItems` (post)

The charge of a laser attached to a weapon is kept in the weapon's `storage`, which vanilla uses for furniture only. A mod that reads or clears `storage` on weapons will conflict.
