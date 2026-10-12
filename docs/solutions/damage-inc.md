# Damage Inc.

## Intent

A new mod, Likho's Damage Inc. (`likhos-damage-inc`). Every weapon hit, on AI and on the player alike, is resolved by one damage calculation hub. The hub produces both the health damage and the armor damage of a hit from the weapon's base damage, its penetration, the distance of the shot, the body part hit and the armor level on that part. Distance is judged against a new weapon stat, range, with a parabolic falloff past it. Range derives from caliber and weapon type, so an SMG outranges a pistol firing the same round. Base damage and penetration of all vanilla guns are replaced with values that follow real ballistics.

## Constraints and assumptions

* Vanilla has two unrelated damage paths. A hit on AI goes through `Hitbox.ApplyDamage(damage, vector, id)`, which applies a per-hitbox rule and calls `AI.WeaponDamage`. A hit on the player goes through `Character.WeaponDamage(damage, penetration)`, which rolls a hit zone, runs an all-or-nothing armor check in `Interface.PlateCheck` or `Interface.HelmetCheck`, rolls medical conditions and subtracts a random 25 to 50% of the weapon damage.
* Every vanilla hit passes one of those two functions. Callers are `WeaponRig.Raycast` (player guns), `KnifeRig.HitCheck` (knife, fixed 25), `AI.Raycast` (AI guns, against AI and against the player) and `BTR.Raycast` (fixed 50 damage and penetration 10, player only).
* Neither function receives enough to do the calculation. `ApplyDamage` gets no penetration and neither gets the weapon or the distance. The shooter has to hand those over separately.
* AI hitbox types are `Head`, `Torso`, `Leg_L` and `Leg_R` in all six AI scenes. There are no arm hitboxes.
* The player is a single collider. Vanilla decides the player's hit zone with a uniform roll: head, torso or limbs at 1/3 each. Ruled out: changing how the hit zone is decided. This solution computes damage for a given body part and does not touch hit chance.
* Player armor levels come from `ItemData.protection`: plates 1 (II), 2 (IIIA), 3 (III), 4 (III+) and 5 (IV), helmets 1 and 2. The plate is a nested `Armor` item inside the rig in equipment slot 7 and its condition is the rig's `slotData.condition`. The helmet sits in equipment slot 8 with its own condition. Limbs carry no armor.
* Ruled out for now: armor on AI. Every AI resolves to armor level 0. The hub itself is side-agnostic and takes an armor level for any target.
* Ruled out: explosions, burn, poison, razor wire and fall damage. They keep vanilla behavior.
* Ruled out: medical conditions on AI.
* Shots are hitscan. Player weapon rays are 400 m long, AI fire rays are 100 m long. A weapon whose range exceeds the ray length never reaches its falloff zone. For AI shooters only pistols and shotguns ever fall off.
* `WeaponData` is a data-only resource script that the loader does not rewrite, so the range stat cannot live on the weapon resource. `damage` and `penetration` are existing fields and can be patched through the registry.
* Caliber is identified by the weapon's ammo item (`weaponData.ammo.file`, e.g. `Ammo_9x19`), not by the `caliber` string. Vanilla spells the string inconsistently (`9x19` on SMGs, `9×19` on pistols) and `likhos-tag` rewrites it for display.
* `likhos-tag` patches VSS `penetration` through the registry. Registry patches on the same field are last write wins. The hub uses whatever `damage` and `penetration` the weapon carries when it fires.
* No existing mod in this repo hooks `Hitbox.ApplyDamage`, `Character.WeaponDamage`, `WeaponRig.Raycast`, `AI.Raycast`, `KnifeRig.HitCheck` or `BTR.Raycast`.
* Assumption, unverified: `Hitbox.gd`, `KnifeRig.gd` and `BTR.gd` can be wrapped by the loader's hook codegen. None is on a skip list, but no existing mod hooks them. `AI.gd`, `Character.gd` and `WeaponRig.gd` are already hooked by `likhos-vostac`.
* Assumption, unverified: inside each shooter function the damage call runs synchronously after the pre hook and before any `await`, so the shot data published in the pre hook is the data the damage call sees.
* Assumption, unverified: a registry patch on a weapon item changes the resource that AI weapon nodes (`AI.weaponData`) and player rigs (`WeaponRig.data`) read, so patched values reach both sides.
* Assumption, unverified: every weapon item has `ammo` set and all weapon items can be enumerated at setup. If they cannot, `Catalog.gd` lists the weapon ids itself.

## Scope

Owned: the new mod folder `likhos-damage-inc/`.

* `mod.txt`
* `Scripts/Main.gd`
* `Scripts/Config.gd`
* `Scripts/Catalog.gd`, the ballistic tables
* `Scripts/Damage.gd`, the hub
* `Scripts/Shot.gd`, the shooter side
* `Scripts/Hitbox.gd`, the AI target side
* `Scripts/Character.gd`, the player target side

Context only: vanilla `Hitbox.gd`, `AI.gd` (`Raycast`, `WeaponDamage`), `Character.gd` (`WeaponDamage` and the condition functions it calls), `Interface.gd` (`PlateCheck`, `HelmetCheck`, `PlayArmorBreak`), `WeaponRig.gd` (`Raycast`), `KnifeRig.gd` (`HitCheck`), `BTR.gd` (`Raycast`), `WeaponData.gd`, `ItemData.gd`, `mod-lib/Main.gd`, `likhos-tag/Scripts/Catalog.gd` (registry patch pattern), `likhos-eventuality/Scripts/Main.gd` and `Config.gd` (LCM registration pattern).

Not owned: other mods, `mod-lib/`, `src/`, repo documentation and the mod's README and changelog.

## Solution

### `mod.txt`

Declares the mod (`id="likhos-damage-inc"`, name `Likho's Damage Inc.`), the autoload for `Scripts/Main.gd`, the `[registry]` opt-in and `[hooks]` for `Hitbox.gd` (`ApplyDamage`), `Character.gd` (`WeaponDamage`), `WeaponRig.gd` (`Raycast`), `AI.gd` (`Raycast`), `KnifeRig.gd` (`HitCheck`) and `BTR.gd` (`Raycast`).

### `Scripts/Main.gd`

Extends `Lib/Main.gd`. In `setup` it registers `Config.gd` with LCM the way `likhos-eventuality` does, has `Catalog.gd` patch the weapon items and registers the hooks below.

### `Scripts/Config.gd`

LCM settings: a multiplier on damage taken by the player (default 0.4, close to the vanilla average of 0.375), a multiplier on damage taken by AI (default 1.0) and the debug switch.

### `Scripts/Catalog.gd`: ballistic tables

Holds two tables and nothing per weapon.

Per caliber, keyed by ammo item:

| Ammo item | Damage | Penetration | Base range, m |
|---|---|---|---|
| `Ammo_9x18` | 30 | 1 | 40 |
| `Ammo_9x19` | 35 | 1 | 50 |
| `Ammo_45ACP` | 40 | 1 | 40 |
| `Ammo_46x30` | 30 | 3 | 75 |
| `Ammo_12x70` | 20 per pellet | 1 | 40 |
| `Ammo_9x39` | 60 | 4 | 200 |
| `Ammo_545x39` | 45 | 3 | 350 |
| `Ammo_223` | 50 | 4 | 350 |
| `Ammo_762x39` | 55 | 3 | 300 |
| `Ammo_308` | 75 | 4 | 500 |
| `Ammo_762x54R` | 80 | 4 | 500 |

Per weapon type, a range factor: `Pistol` 1.0, `SMG` 2.0, `Rifle` 1.0, `Bolt` 1.2, `Shotgun` 1.0.

A weapon's damage and penetration are its caliber's. Its range is the caliber's base range times its type factor. A 9x19 pistol reaches 50 m and a 9x19 SMG 100 m. The PM7 reaches 150 m, an SVD 500 m and a Mosin 600 m.

At setup `Catalog.gd` patches `damage` and `penetration` on every weapon item through the items registry, following the patch pattern of `likhos-tag/Scripts/Catalog.gd`. The vanilla tooltip and inspect screen therefore show the new values. Range is not stored on the weapon. `Catalog.gd` resolves it on request for a given `WeaponData`.

A weapon whose caliber is not in the table keeps its own damage and penetration and has no range, which means no falloff.

### `Scripts/Damage.gd`: the hub

A side-agnostic calculation with no knowledge of AI, player, nodes or hooks.

Input, one hit: base damage, penetration, weapon range (absent for melee and unknown sources), distance, body part (`Head`, `Torso` or `Limb`), armor level on that part (0 for none) and the target side's damage multiplier.

Output: health damage, armor damage in condition points and whether the armor stopped the hit. A hit with no remaining energy produces no effect at all.

Rules:

* Falloff. The factor is 1 up to the weapon's range. Past it the factor drops along a parabola, gently at first and steeply toward the end, reaching 0 at 1.5 times the range. Without a range the factor is 1.
* The factor scales both base damage and penetration. The results are the effective damage and the effective penetration. Effective penetration is fractional.
* Body part. Health damage is multiplied by 4 for `Head`, 1 for `Torso` and 0.5 for `Limb`.
* Armor pass. With no armor all effective damage passes. With armor, the share that passes depends on effective penetration minus armor level. At 0 or below the hit is stopped and only a 10% blunt share passes. At 1 or above everything passes. In between the share rises linearly. At point blank this keeps the vanilla meaning of the integer levels: penetration equal to the armor level is stopped, one level above goes through.
* Health damage is effective damage times body part multiplier times pass share times the side multiplier.
* Armor damage is effective damage times the ratio of effective penetration to armor level, times a wear factor of 0.5. A round close to the armor's rating wears it faster than a weak one. A penetrating hit takes a large share of condition but does not zero the armor by itself.
* Armor protects at its full level until its condition reaches 0, as in vanilla. Reading the level and treating condition 0 as level 0 is the target side's job.

### `Scripts/Shot.gd`: shooter side

Pre hooks on `WeaponRig.Raycast`, `AI.Raycast`, `KnifeRig.HitCheck` and `BTR.Raycast`. Each publishes the current shot for the target side to pick up: the ray origin, the penetration and the weapon range resolved by `Catalog.gd`. Knife and BTR hits publish no range. The knife publishes penetration 0.

The published shot is valid only for the damage call made inside the shooter function that published it. A damage call that finds no shot, such as one from another mod, is calculated from its arguments alone with no falloff.

Vanilla shooter functions are not replaced. Ray casting, spread, decals, sounds and effects stay vanilla.

### `Scripts/Hitbox.gd`: AI target side

Replace hook on `Hitbox.ApplyDamage`, suppressing vanilla. It maps the hitbox type to a body part (`Leg_L` and `Leg_R` are `Limb`), measures the distance from the published ray origin to the hit, passes armor level 0 and the AI multiplier from config, and calls the hub. It applies the health damage through vanilla `AI.WeaponDamage`, which keeps the flinch, Nomad reputation, voice lines and death handling. A hit with no effect is dropped.

This handler is the only place that resolves AI armor. It is where a later AI armor source plugs in.

### `Scripts/Character.gd`: player target side

Replace hook on `Character.WeaponDamage`, suppressing vanilla. It keeps the vanilla guard for transitions and caching and the vanilla 1/3 zone roll. It reads the armor on the rolled part as described in the constraints, measures the distance from the published ray origin to the player and calls the hub with the player multiplier from config.

Applying the result:

* Armor damage is subtracted from the helmet's or the rig's condition, clamped at 0. The item's details refresh and the vanilla armor break sound plays when condition reaches 0.
* A stopped hit subtracts the blunt health damage, plays the vanilla armor impact sound and rolls no medical condition.
* Any other hit subtracts the health damage and runs the vanilla medical roll unchanged: headshot, rupture, bleeding or fracture at the vanilla odds.
* The vanilla damage and impact flags on `gameData` are set as vanilla sets them.

Vanilla `Interface.PlateCheck` and `HelmetCheck` are no longer called by anything.

### Observable result

* Weapon tooltips show the new damage and penetration values.
* A point blank torso hit on a standard AI (100 health) takes 80 from a Mosin, 55 from an AKM and 35 from a G7. A head hit kills a standard AI with any gun except a single shotgun pellet, which deals 80. A knife head hit deals 100, as in vanilla.
* A G7 deals full damage up to 50 m, about 75% at 62 m and nothing from 75 m.
* An AI firing an AKM at the player's torso at default settings: with no plate 22 health, with a IIIA plate 22 health and about 41 plate condition, with a III plate about 2 health and 27 plate condition, with a III+ plate about 2 health and 21 plate condition.
* A plate or helmet survives a penetrating hit with reduced condition.
* Raising the player multiplier in the LCM menu makes every hit on the player proportionally harder. The AI multiplier does the same for hits on AI.

## Tradeoffs

* Shooters publish shot data in pre hooks and the two target functions are replaced, chosen over replacing the four shooter functions. Vanilla ray casting and effects stay intact and other mods' hooks on shooters keep working. The cost is an implicit hand-off between a pre hook and a replace hook that relies on the call being synchronous.
* The two replace hooks are single-owner. Another mod replacing `Hitbox.ApplyDamage` or `Character.WeaponDamage` wins or loses wholesale.
* Stats derive from caliber and type only, chosen over per-weapon values. Two small tables cover all 29 guns and any modded gun in a known caliber. The cost is that guns sharing caliber and type are ballistically identical: M4A1, K416, KM18 and KAR-21 (.223) no longer differ in penetration as they do in vanilla.
* Range lives in the mod's table, not on the weapon resource. Other mods cannot patch it through the registry.
* Damage on the player is deterministic. The vanilla random spread of 25 to 50% is replaced by one configurable multiplier.
* A penetrating hit no longer zeroes armor, chosen over the vanilla rule. Armor stays useful after a first penetration. The cost is that better armor lasts longer than in vanilla against rounds that defeat it.
* Armor keeps its full level until condition 0, chosen over protection that degrades with condition. It matches vanilla and keeps the hub's armor input a single number.
* The four shooter hooks share one script, chosen over one handler script per hooked vanilla script as other mods here do. Each handler is a few lines doing the same job.

## Open questions

* Head multiplier on the player. The vanilla zone roll makes 1/3 of all hits on the player head hits. With a head multiplier of 4 and the default player multiplier of 0.4, an unhelmeted head hit costs 56 health from a 9x19 and 88 from an AKM, and a .308 or 7.62x54R kills outright. Options: accept it, lower the shared head multiplier (a 9x19 head hit then no longer kills a standard AI), or use a separate head multiplier per side.
* Shotgun pellets. Vanilla fires six rays for the player's shotgun and one for an AI's. At 20 per pellet the player deals up to 120 per shot and an AI 20. Options: accept it, or let the hub scale an AI shotgun ray to stand for several pellets.
* The caliber table is a first proposal. Damage, penetration and base range per caliber and the type factors need your review.
* Range is not shown anywhere in game. A `Range` row on weapon tooltips is possible through `mod-lib/Tooltip.gd`, at the cost of a post hook on `Tooltip.Update` alongside the ones `likhos-tag` and `likhos-vostac` already have.
