# AI behavior ideas

Sourced from Oldman's Immersive Overhaul (IXP) 3.2.0, `ImmersiveXP.vmz`. Taken from its `AI.gd`, `Sensor.gd`, `AISpawner.gd` and `Mine.gd`, each compared against the vanilla method in `src/`. Line references are relative to the `ImmersiveXP/` folder inside the archive.

IXP 3.2.0 does not match the game build in `src/`, so these are ideas to reimplement, not code to copy.

## Perception

- **Real last known position.** Vanilla `PriorityStats` copies the target's true position every frame, so AI always knows where you are. IXP updates it only while the target is visible or was just heard (`Sensor.gd:155`).
- **View cone on line of sight.** Vanilla `PriorityLOS` raycasts regardless of facing. IXP fails the check when the target is outside `viewAngle` (`Sensor.gd:127`).
- **Sight range from light and weather.** Vanilla uses 150, 100 in fog and 50 at night. IXP derives it from sun colour, ground colour, fog and overcast (`Sensor.gd:240`).
- **Player stance affects sight range.** Running +20%, walking +10%, crouch-walking -10%, crouched still -20%, indoors -20%.
- **Softer detection boost.** Firing at the AI or pointing a flashlight at night adds 50 m instead of jumping to 200 (`Sensor.gd:31`).
- **Graded hearing.** Vanilla is 20 m running and 5 m walking. IXP uses 20 running, 10 landing, 6 walking and 3 crouch-walking (`Sensor.gd:206`), with modifiers:
  - x1.35 when overweight or on wood, x1.7 on metal.
  - 10 m minimum while reloading, checking ammo, using items or crafting.
  - x0.7 in wind, when the AI itself is moving, or when one of you is indoors and the other is not.
- **Flashlight gives you away up close.** Pointed at the AI, it is noticed within 20 m at night outdoors and 10 m otherwise (`Sensor.gd:189`).
- **Reaction time scales with angle and distance.** The priority and raycast cycles stretch from 0.3 s to 1.0 s for targets far away and off axis (`Sensor.gd:67`).
- **Stale target cleared.** Vanilla keeps the old priority when no target qualifies. IXP nulls it (`Sensor.gd:123`).

## Decisions

- **Context-driven decision instead of a d8 roll** (`AI.gd:104`):
  - Over 100 m: hide, cover or vantage, never rush.
  - 25 to 100 m: hunt only under 50 m, with ammo and not under fire.
  - Under 25 m: cover when out of ammo or taking fire.
  - Bolt-action AI never hide or rush.
- **Push when the player is busy.** If the player is heard nearby while reloading or using an item, Attack becomes a valid choice (`AI.gd:156`).
- **Reaction to incoming fire.** Shots aimed at a stationary AI force an immediate re-decision (`Sensor.gd:54`). Taking a hit does the same half the time (`AI.gd:546`).
- **Closing distance at long range.** Wander, cover and vantage points nearer the target are preferred when it is over 90 m away, unless under fire (`AI.gd:571`).
- **Hide always ends in Ambush.** Vanilla does this 25% of the time (`AI.gd:207`).
- **Ambushers hold position.** They do not open doors (`AI.gd:56`) and break ambush on noise only if the player is outdoors and facing them (`Sensor.gd:201`).
- **Bounding advance.** A "Shift" state hops between waypoints toward the target while firing (`AI.gd:85`, `AI.gd:318`). It is implemented but commented out of the decision list.

## Shooting and ammo

- **Magazines matter.** Vanilla reloads instantly at zero. IXP plays a dry click, then sometimes shouts, seeks cover and reloads only once it has slowed down (`AI.gd:357`, `AI.gd:784`).
- **Tactical reload.** A partial magazine is topped up when the target is out of sight and no threat is active (`AI.gd:171`).
- **Full-auto chance by pressure.** Vanilla is a flat 10%. IXP uses 10% past 100 m, 20% past 50 m, 50% under fire and 30% otherwise (`AI.gd:414`).
- **Slower semi-auto cadence at range.** Extra bands at 20, 60 and 100 m (`AI.gd:483`).
- **Suppressive fire at the last known position.** `Combat` fires without line of sight when a `suppressiveFire` flag is set (`AI.gd:251`). Nothing sets the flag, so only the idea is usable.

## Sound and group awareness

- **Gunfire alerts by radius and faction.** Shots alert AI within 100 m, or 40 m suppressed. Allies go hot and receive the shooter's position. Enemies of the shooter target it if it is closer than their current target (`AISpawner.gd:84`, `AI.gd:770`).
- **Explosions alert AI.** Mine detonation alerts within 200 m (`Mine.gd:44`).
- **Report delay by distance.** The shot sound is delayed by `distance * 0.002` s (`AI.gd:395`).
- **Crack and flyby from the actual miss.** Played when the round lands beyond the player at any range, with flyby outdoors only (`AI.gd:463`). Vanilla plays them only past 50 m.

## World interaction and spawning

- **AI close doors behind them.** After 5 s, if calm, moving slowly and the target is over 5 m from the door (`AI.gd:65`).
- **Randomised population per map load.** Total 12 to 18 and active 4 to 6, with the active cap re-rolled each time it is reached (`AISpawner.gd:24`, `AISpawner.gd:72`).
- **Nomads present on a 50% roll** (`AISpawner.gd:36`).
- **Stealth readout.** The HUD debug text shows the current visibility and noise distances (`HUD.gd:80`, `HUD.gd:177`).

## Defects not to carry over

- `Sensor.gd:231` and `Sensor.gd:235` mix `&&` and `||` without parentheses, so the wind and indoor modifiers apply more broadly than the comments say.
- `AI.gd:512` overwrites the full-auto spread multiplier with the accuracy setting.
- `AI.gd:494` checks `weaponAction == "Manual"` where vanilla uses `"Pump"` and `"Bolt"`.
- `AI.gd:72` reads `gameData.sensor`, which IXP never defines, so the door-closing check errors when reached.
- `AISpawner.gd:50` reads `isSuppressed`, which nothing sets. It also indexes `enemies.get_child(0)` on every physics frame while firing, which fails with no enemies alive.
- `AISpawner.noHiding`, `AISpawner.damageBlocked` and `AISpawner.AlertNoise` are referenced but do not exist in `src/`.

## Implementation notes

- Most of these are single-method changes on `Sensor.gd` and `AI.gd`, so they fit replace hooks without replacing the AI scenes.
- The only existing touchpoint in this repo is VosTac's `ai-death-pre` hook for the kill counter.
- IXP adds two `gameData` fields the AI reads, `isInteracting` and `isSuppressed`. A reimplementation needs its own source for both.
