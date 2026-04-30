# Likho's Eventuality

Road to Vostok mod that improves dynamic event spawning so that they more closely represent declared probabilities.

* Fixed individual event probabilities to follow declared values
* Police van without sirens is no longer a dud
* Heli crash site now plays a sound to let you know it has spawned
* Fighter jet repeats

## Probability math

Vanilla stacks probabilities, resulting much lower chances of individual event spawning than declared in the UI. 

For example: you have `["FighterJet", "Police", "Airdrop", "CrashSite"]` events available in the Village, with individual probabilities being `25% / 10% / 10% / 10%`. The actual trigger chance for them is `6.25% / 2.5% / 2.5% / 2.5%` (declared chance divided by number of available events).

---

This mod turns this math around. Each dynamic event now gets its own die roll. There now could potentially be multiple events active on the map.

Notable exceptions:
- Police van is exclusive with BTR
- Airdrop is exclusive with the heli crash site

Events skipped because of exclusivity will pass on their probability as a roll bonus onto the next map load. Roll bonus resets when roll occurs, but accumulates on skipped rolls.

E.g. if you got two Airdrops in a row, then the trigger chance for heli crash on the third map load will be 30% instead of 10%.


## Punisher

Vanilla Punisher is incredibly hard to catch because of accumulating probabilities. This is compounded by the fact that Police van has two distinct modes (with sirens and without) activated 50/50, so the real chance of getting Punisher encounter is more like 1%.

Two main changes were made:
- Event variant without sirens will now trigger the boss just the same
- Van speed reduced from 25 to 15, so it's much easier to catch him (or to run away)

## Heli crash site

The crash site will now trigger an audible explosion (5-20 sec delay after loading the map) whenever it spawns. Now you know to look for it.

## Fighter jet

Once triggered, will repeat anywhere between 3-10 times at random intervals (60-300 seconds).

## MCM config

Published all event probabilities as MCM config values. Note that probability does not override availability. E.g. Punisher won't be available before day 5, even if you set him to 100%.

I *DO NOT RECOMMEND* changing them unless it is to trigger long wanted event (like Punisher) once and then revert. The probability stacking made it seem like vanilla events are way too rare. You may find that after this mod fix, events are quite common and might be annoying.


## Compatibility

This mod hooks vanilla methods through Metro Mod Loader:

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `EventSystem.ActivateDynamicEvent`
- `EventSystem.CrashSite`

**Post hooks** (additive, run after vanilla, coexist with other mods cleanly):

- `EventSystem.FighterJet`
- `Police._ready`
- `Police.States`

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
