# Likho's Eventuality

Road to Vostok mod that improves dynamic event spawning so that they closer represent declared probabilities.

## Probability

Each dynamic event now gets its own die roll and there now could potentially be multiple events active on the map.

Notable exceptions:
- Punisher is exclusive with BTR
- Care package drop is exclusive with the chopper crash site

Events skipped because of exclusivity will pass on half of their spawn chance onto the next event as a roll bonus.

## Punisher

Vanilla Punisher is incredibly hard to catch because of accumulating probabilities.

Two main changes to make to make it easier to obtain his hat:
- Event variant without sirens will now trigger the boss just the same
- Van speed reduced from 25 to 15, so it's much easier to catch him

## Fighter jet

Once triggered, will spawn repeatedly at random intervals.

## Compatibility

This mod hooks vanilla methods through Metro Mod Loader:

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `EventSystem.ActivateDynamicEvent`
- `Police.States`

**Post hooks** (additive, run after vanilla, coexist with other mods cleanly):

- `EventSystem.FighterJet` (post)
- `Police._ready` (post)

## Install / Uninstall

Drop `likhos-eventuality.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically.

To uninstall simply delete `likhos-eventuality.vmz` from the `mods/` folder and relaunch the game.

## Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader/wiki) v3.0.1 or later (separate install, not bundled with the game)
