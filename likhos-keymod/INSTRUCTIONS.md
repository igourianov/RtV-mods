# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://modworkshop.net/mod/56483) v3.0.1 or later (separate install, not bundled with the game)

# Compatibility

This mod uses the registry API and hooks vanilla methods through Metro Mod Loader:

**Registry API** (patches item definitions):
- Uses `lib.patch()` on gun items to inject foreign magazines into their tetris scenes and compatible attachments


# Install / Uninstall

Drop `likhos-keympd.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-keympd.vmz` from the `mods/` folder and relaunch the game.
