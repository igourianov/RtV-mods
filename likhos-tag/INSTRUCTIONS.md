## Install

Drop `likhos-tag.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

## Uninstall

To uninstall simply delete `likhos-tag.vmz` from the `mods/` folder and relaunch the game.

## Compatibility

This mod uses the registry API through Metro Mod Loader:

**Registry API** (patches item definitions):
- Uses `lib.patch()` on items to override naming and other properties (display, name, weight, etc.)

Other mods that patch the same fields on the same items will conflict.

**Hooks:**
* `Tooltip.Reset` (post)
* `Tooltip.Update` (post)
