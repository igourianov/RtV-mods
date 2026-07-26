# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader (MML)](https://www.nexusmods.com/roadtovostok/mods/20) v3.2.1 or later (separate install, not bundled with the game)
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

Drop `likhos-eventuality.zip` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-eventuality.zip` from the `mods/` folder and relaunch the game.
