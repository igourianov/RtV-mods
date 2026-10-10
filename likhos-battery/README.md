# Likho's Battery

Batteries keep their charge and can be taken out of any device that accepts them.

* Batteries show their own charge. A device takes exactly the charge of the battery you put in.
* Right click a charged device and pick `Remove (Batteries)` to get a battery with the device's charge. The device drops to 0%.
* Dropping a battery on a charged device swaps their charge. A device at 0% consumes the battery, same as vanilla.
* Prices follow charge. A battery is worth its charge and a device loses the price of the charge it is missing. Narva: 180€ at 100%, 80€ at 0%.
* A flashlight below 5% charge flickers. The short bursts of dimming come more often as the battery runs out.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item definitions):
- `lib.patch()` on `Batteries` to set `showCondition`

**Hooks** (other mods that also replace these will conflict, pick one):
- `Interface.Charge` (replace)
- `Interface.ContextRemove` (replace)
- `Item.Value` (replace)
- `Context.Update` (post)
- `Flashlight.Activate` (post)

## Install / Uninstall

Drop `likhos-battery.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-battery.vmz` from the `mods/` folder and relaunch the game.
