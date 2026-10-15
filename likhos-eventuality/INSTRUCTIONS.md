## Install

Drop `likhos-eventuality.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

## Uninstall

To uninstall simply delete `likhos-eventuality.vmz` from the `mods/` folder and relaunch the game.

## Compatibility

This mod hooks vanilla methods through Metro Mod Loader:

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `EventSystem.ActivateDynamicEvent`
- `EventSystem.CrashSite`

**Pre hooks** (additive, run before vanilla, coexist with other mods cleanly):

- `EventSystem.ActivateWeeklyEvent`

**Post hooks** (additive, run after vanilla, coexist with other mods cleanly):

- `EventSystem.FighterJet`
- `Police._ready`
- `Police.States`
