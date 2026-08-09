# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader (MML)](https://www.nexusmods.com/roadtovostok/mods/20) v3.2.1 or later (separate install, not bundled with the game)
- [Mod Configuration Menu (MCM)](https://www.nexusmods.com/roadtovostok/mods/58) (optional, falls back to defaults without it)

This mod is a shell. It ships no music of its own. Stations are separate "station pack" mods that register themselves at startup (see `README.md`). Without any pack installed the radio cycle only contains Off and the vanilla station.

# Compatibility

This mod hooks vanilla methods through Metro Mod Loader (declared in `[hooks]`):

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `Radio.Interact` - turns the on/off toggle into an `Off -> Vanilla -> [station packs] -> Off` cycle. The vanilla station is left untouched and stays on its own audio bus; only the custom stations are added.

**Pre / post hooks** (compose with other mods):

- `Radio._physics_process` (pre) - rolls the on-load auto-play chance once per radio. May pick Off, the vanilla station or any registered pack station.
- `Radio.UpdateTooltip` (post) - relabels the interaction prompt to show the current state instead of the next action.

Creates a runtime audio bus `LikhosRadiola` (high-pass + low-pass + lo-fi distortion) shared by all custom stations.

Ships the shared mod-lib as `Lib/`, including `AudioChunkPlayer3D.gd` used for playback.

# Install / Uninstall

Drop `likhos-radiola.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-radiola.vmz` from the `mods/` folder and relaunch the game.
