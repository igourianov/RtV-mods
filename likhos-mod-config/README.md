# Likho's Mod Config

A lightweight settings menu for mods. Every mod that supports it gets an entry in one list and its own settings page.

* Opens from the `Mod Config` button in the top right corner of the game's settings screen, in the main menu and in game.
* Changes take effect when you leave a mod's page or close the menu.
* `Reset` next to a setting restores its default.
* Settings are kept separately for each Mod Loader profile.
* Runs next to Mod Configuration Menu (MCM). The two menus are separate and each lists its own mods.

Without this mod installed, mods that rely on it run on their default settings.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.1 or later (separate install, not bundled with the game)

## Compatibility

This mod hooks vanilla methods through Metro Mod Loader:

**Hooks** (post, vanilla still runs):
- `Settings.gd`: `_ready`

## Install / Uninstall

Drop `likhos-mod-config.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-mod-config.vmz` from the `mods/` folder and relaunch the game.

## For mod authors

See `INSTRUCTIONS.md` for how to give your mod a settings page.
