# Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://www.nexusmods.com/roadtovostok/mods/20) v3.4.1 or later (separate install, not bundled with the game)
- [Mod Configuration Menu (MCM)](https://www.nexusmods.com/roadtovostok/mods/58)

# Compatibility

This mod hooks vanilla methods through Metro Mod Loader:

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `EventSystem.ActivateDynamicEvent`
- `EventSystem.CrashSite`

**Post hooks** (additive, run after vanilla, coexist with other mods cleanly):

- `EventSystem.FighterJet`
- `Police._ready`
- `Police.States`

# Install / Uninstall

Drop `likhos-eventuality.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-eventuality.vmz` from the `mods/` folder and relaunch the game.
