## Install

Drop `likhos-radiola.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

## Uninstall

To uninstall simply delete `likhos-radiola.vmz` from the `mods/` folder and relaunch the game.

## Compatibility

This mod hooks vanilla methods through Metro Mod Loader (declared in `[hooks]`):

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `Radio.Interact` - turns the on/off toggle into an `Off -> Vanilla -> [station packs] -> Off` cycle. The vanilla station is left untouched and stays on its own audio bus; only the custom stations are added.

**Pre / post hooks** (compose with other mods):

- `Radio._physics_process` (pre) - once per radio (not the gathering radio), discards vanilla's random-on roll, rolls the mod's on-chance instead, then picks the vanilla station or any registered pack station at random.
- `Radio.UpdateTooltip` (post) - relabels the interaction prompt to show the current state instead of the next action.

Creates a runtime audio bus `LikhosRadiola` (high-pass + low-pass + lo-fi distortion) shared by all custom stations.

Ships the shared mod-lib as `Lib/`, including `AudioChunkPlayer3D.gd` used for playback.
