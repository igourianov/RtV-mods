# Weapon sway scales with weapon weight

## Intent

In VosTac the point of aim drifts slowly while the player stands still and does not move the mouse. That drift should depend on how heavy the weapon is. A heavier weapon drifts more, a lighter one less.

* The drift as it is today is right for a weapon with a total weight of 5kg.
* A weapon of 3kg drifts at 30% of that.
* The scale is linear through those two points.
* The difference between a light and a heavy rifle is plain to see in play, not only measurable.
* It applies while aiming and while canted.

## Constraints and assumptions

* The drift is the rotation wobble of the rig's `Noise` node, which VosTac already drives in `Hooks/Noise.gd`. Ruled out: the mouse-follow lag of the rig's `Sway` node (vanilla `Sway.gd`) and the headbob position offset of the `Noise` node. Neither is the effect described.
* Weight scales the wobble amplitude only. The wobble frequency stays as it is, so a heavy weapon drifts further at the same pace.
* The factor has a floor of 30%, so every weapon of 3kg and under drifts the same. The line would reach zero at 2.1kg without it. There is no ceiling: the line extrapolates above 5kg.
* Ruled out: a gentler line through 1kg at 30%. Equipped rifles weigh about 3.5 to 6kg, which that line maps to 75% to 118%, too narrow a spread to notice in play.
* Weight is the weapon's total weight as vanilla `Item.Weight()` reports it: base weight, loaded and chambered rounds and every nested attachment. VosTac already caches it in `Config.current_weapon_weight` on every rig update.
* The 5kg reference is specific to the wobble. `Config.BASE_WEAPON_WEIGHT` (4kg) stays the reference for arm stamina drain and is not reused here.
* The weight factor applies in the aim state and the canted state, moving or standing. Ruled out: scaling the low ready and raised (`weaponPosition == 2`) wobble. The request names aiming and canted only.
* The wobble while firing is not scaled by weight. It is a firing shake, not the slow drift, and VosTac already excludes it from the aim multiplier.
* A cached weight of 0 means no weapon is resolved. The wobble is then left unscaled, instead of taking the 30% floor.
* No MCM setting. The scale is always active.
* The aim and canted states only occur on a weapon rig. Vanilla `Handling.gd` sets them on its weapon path only, and knife, grenade and fishing rigs go through `BasicHandling`, which never sets them. So a rig without a weapon item never reaches the scaled path with a stale weight from the previous weapon.

## Scope

Owned:

* `likhos-vostac/Scripts/Hooks/Noise.gd`: the wobble amplitude.

Context only:

* `likhos-vostac/Scripts/Hooks/Handling.gd`: `on_rig_update_post` writes `Config.current_weapon_weight`.
* `likhos-vostac/Scripts/Config.gd`: holds `current_weapon_weight`.
* `likhos-vostac/Scripts/Hooks/Character.gd`: the other reader of the cached weight, for arm stamina.
* Vanilla `src/Scripts/Noise.gd`: sets `targetAmplitude`, `targetFrequency` and `targetLerpSpeed` per movement state.
* Vanilla `src/Scripts/Item.gd`: `Weight()`.

## Solution

### Weight factor

`Hooks/Noise.gd` derives a weight factor from `Config.current_weapon_weight` on the line through its two reference points, 30% at 3kg and 100% at 5kg, floored at 30%. The reference points are named constants in `Hooks/Noise.gd`.

| weight | factor |
|---|---|
| 3kg and under | 30% |
| 3.5kg | 47.5% |
| 4kg | 65% |
| 4.5kg | 82.5% |
| 5kg | 100% |
| 6kg | 135% |
| 7kg | 170% |
| 8kg | 205% |

### Wobble amplitude

The wobble amplitude target in `_apply_wobble` is vanilla's `targetAmplitude` times VosTac's amplitude multiplier. The weight factor is one more term of that multiplier.

* Aim state, not firing: the aim multiplier, eased toward the hold breath multiplier by `Config.hold_breath_state`, times the weight factor.
* Canted state, not firing: the weight factor alone. Canted has no multiplier of its own today and keeps none.
* Exhausted arms multiply on top of either, as they do today.
* Every other state, and any state while firing: unchanged.

The amplitude reaches its target through the existing lerp, so a weapon swap or a change of state eases into the new amplitude instead of snapping.

### Flow

1. A rig update (equip, attachment change, inventory change of the equipped weapon) fires `rigmanager-updaterig-post`. `Handling.on_rig_update_post` caches the weapon's weight.
2. Each physics frame `noise-_physics_process-post` fires. `Noise.on_physics_process_post` computes the amplitude target with the weight factor and writes the node's rotation.

### Observable result

* A 5kg weapon drifts exactly as it does today, aiming and canted.
* Pistols, light submachine guns and any other build of 3kg and under drift at 30% of that, all alike.
* A 3.5kg rifle drifts at about half of today's level and a 5.7kg one at about 125%, a difference visible without comparing side by side.
* From 3kg up, attaching a suppressor, optic or a full magazine raises the drift, by 35 points per kg. Stripping the weapon lowers it.
* Holding breath and exhausted arms change the drift by the same ratios as today, on top of the weight.
* Low ready, raised and firing wobble are the same for every weapon.

## Tradeoffs

* The cached weight over reading the weapon item every frame. The cost: the weight is as fresh as the last rig update, so rounds fired from the magazine do not lower the drift until the next rig update.
* A steep line over a gentle one. The cost: weight differences under 3kg do not show at all, so a pistol and a light submachine gun drift the same, and one heavy attachment moves the drift noticeably.
* A floor without a ceiling. The cost: a very heavy build drifts well past today's level, 205% at 8kg, and that stacks with the exhausted arms multiplier.
* Aim and canted only over every stance. The cost: a step in wobble amplitude between canted and low ready that depends on the weapon, larger the further its weight is from 5kg.
* A separate 5kg reference over reusing the 4kg arm stamina reference. The cost: two weight baselines in the mod that mean different things.
