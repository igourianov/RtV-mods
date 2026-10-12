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

**Hooks** (other mods that also replace these will conflict, pick one):
- `Interface.Charge` (replace)
- `Interface.ContextRemove` (replace)
- `Item.Value` (replace)
- `Context.Update` (post)
- `LootContainer.CreateLoot` (post)
- `LootSimulation.SpawnItems` (post)
