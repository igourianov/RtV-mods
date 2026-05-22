# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://modworkshop.net/mod/55623) v3.0.1 or later (separate install, not bundled with the game)

# Compatibility

This mod uses the registry API through Metro Mod Loader:

**Registry API** (patches item definitions):
- Uses `lib.patch()` on items to override naming and other properties (display, name, weight, etc.)

Other mods that patch the same fields on the same items will conflict. Tag is intentionally loaded late (`priority=10`) so its values win over earlier mods.

**Hooks:**
* `Tooltip._ready` (pre)
* `Tooltip.Reset` (post)
* `Tooltip.Update` (post)

# Install / Uninstall

Drop `likhos-tag.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-tag.vmz` from the `mods/` folder and relaunch the game.
