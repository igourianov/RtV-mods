# Kill counter mode

## Intent

The VosTac kill counter card counts every AI death in the current scene, whoever caused it. The user wants an option to count only the AI the player killed. The existing on/off toggle becomes a dropdown with three options: all deaths, player kills and disabled.

## Constraints and assumptions

* Vanilla `AI.Death` takes no killer. The killer is only known to the two vanilla calls that lead into it: `AI.WeaponDamage` and `AI.ExplosionDamage`, both of which receive the damage source as `id`.
* The damage source is the player when it is in the `Player` group. Vanilla relies on the same check for the nomad reputation penalty in both damage calls. The player's weapon, knife and grenade rigs all pass the player's `Camera/ID` node as the source.
* AI shots at other AI pass the shooter's own identifier. Explosions without a thrower pass a null source. Both count as deaths, not player kills.
* `AI.ExplosionDamage` calls `Death` even on an AI that is already dead. The existing guard against counting a dead AI twice stays.
* LCM drops a stored value whose type no longer matches its field. A user who had the bool toggle off gets the default mode back once. Accepted, no migration.
* Ruled out: per weapon counts. The counter stays one list per scene, cleared on scene load as today.
* VosTac registers its hooks through `register_hook`, so every hooked vanilla method is also declared under `[hooks]` in `mod.txt`.

## Scope

Owned:

* `likhos-vostac/Scripts/Config.gd`: the mode setting and the kill lists.
* `likhos-vostac/Scripts/Hooks/KillCounter.gd`: attribution and recording.
* `likhos-vostac/Scripts/Hooks/HUD.gd`: `_update_kill_cards`, choosing the list to show.
* `likhos-vostac/Scripts/Main.gd`: the kill counter hook registration.
* `likhos-vostac/mod.txt`: the `[hooks]` declaration for `AI.gd`.
* `likhos-vostac/INSTRUCTIONS.md`: the hook list.
* `likhos-vostac/README.md`: the kill counter line.

Context only:

* Vanilla `src/Scripts/AI.gd`: `WeaponDamage`, `ExplosionDamage`, `Death`.
* Vanilla `src/Scripts/Hitbox.gd`, `WeaponRig.gd`, `KnifeRig.gd`, `GrenadeRig.gd`, `Explosion.gd`: how the damage source reaches the AI.
* `likhos-vostac/Scripts/InspectCards/KillCounterCard.gd`: renders a group of factions, unchanged.
* `likhos-config-manager/Scripts/ModMenu.gd`: renders an exported enum as a dropdown.

## Solution

### Setting

`Config.gd` defines a `KillCounterMode` enum with `ALL_DEATHS`, `PLAYER_KILLS` and `DISABLED`, following `ChamberCardMode`. The `Weapon Cards` group exports `kill_counter_mode` in place of the `kill_counter_card` bool, defaulting to `ALL_DEATHS`. LCM shows it as a dropdown.

### Recording

`Config.gd` holds two faction lists for the current scene: every AI death and the AI the player killed. Both have the shape of today's `kills`: one faction byte per death, in order.

`Hooks/KillCounter.gd` records each AI death once, into the all deaths list always and into the player kills list when the damage call that led into `Death` came from the player. It learns the source from pre hooks on `AI.WeaponDamage` and `AI.ExplosionDamage` and keeps the existing `AI.Death` pre hook as the point where a death is recorded. Both lists are cleared on scene load.

Recording does not depend on the mode, so switching the mode mid raid shows the matching history at once.

### Display

`HUD._update_kill_cards` hides the cards when the mode is `DISABLED` and otherwise shows the list the mode names. Card layout, grouping by ten and faction colors are unchanged.

### Flow

1. The player or an AI hits an AI. Vanilla calls `WeaponDamage` or `ExplosionDamage` with the source. `KillCounter` notes whether the source is the player.
2. If the hit is lethal, vanilla calls `Death`. `KillCounter` records the faction in the all deaths list and, for a player source, in the player kills list.
3. In inspect mode `HUD` renders the list the mode selects.
4. On scene load both lists are cleared.

### Observable result

* `Kill counter` in LCM's Weapon Cards group is a dropdown: All deaths, Player kills, Disabled.
* All deaths behaves as the toggle did when on.
* Player kills shows only AI killed by the player's guns, knife and grenades. AI killed by other AI or by sourceless explosions are left out.
* Disabled hides the card.

## Tradeoffs

* Two lists recorded always over one list recorded per the current mode. The cost: a second small byte list per scene. The gain: the mode applies retroactively within a raid.
* Attribution from the damage calls over replacing `Death` or reading state after it. The cost: two more pre hooks on `AI.gd`, shared with any other mod hooking them.
* No migration of the old bool. The cost: users who turned the counter off see it again once.
