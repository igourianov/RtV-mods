# Weapon sway scales with weapon weight

## Intent

In VosTac the point of aim drifts slowly while the player stands still and does not move the mouse. That drift should depend on how heavy the weapon is. A heavier weapon drifts more, a lighter one less.

* The drift as it is today is right for a weapon with a total weight of 5kg.
* A weapon of 1kg drifts at 30% of that.
* The scale is linear through those two points.
* It applies while aiming and while canted.

## Constraints and assumptions

* The drift is the rotation wobble of the rig's `Noise` node, which VosTac already drives in `Hooks/Noise.gd`. Ruled out: the mouse-follow lag of the rig's `Sway` node (vanilla `Sway.gd`) and the headbob position offset of the `Noise` node. Neither is the effect described.
* Weight scales the wobble amplitude only. The wobble frequency stays as it is, so a heavy weapon drifts further at the same pace.
* The line is not clamped. It extrapolates below 1kg and above 5kg.
* Weight is the weapon's total weight as vanilla `Item.Weight()` reports it: base weight, loaded and chambered rounds and every nested attachment. VosTac already caches it in `Config.current_weapon_weight` on every rig update.
* The 5kg reference is specific to the wobble. `Config.BASE_WEAPON_WEIGHT` (4kg) stays the reference for arm stamina drain and is not reused here.
* The weight factor applies in the aim state and the canted state, moving or standing. Ruled out: scaling the low ready and raised (`weaponPosition == 2`) wobble. The request names aiming and canted only.
* The wobble while firing is not scaled by weight. It is a firing shake, not the slow drift, and VosTac already excludes it from the aim multiplier.
* A cached weight of 0 means no weapon is resolved. The wobble is then left unscaled, instead of taking the 12.5% the line gives at 0kg.
* No MCM setting. The scale is always active.
* Assumption, unverified: the aim and canted states only occur on a weapon rig, so a rig without a weapon item (knife, grenade, instrument) never reaches the scaled path with a stale weight from the previous weapon.

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

`Hooks/Noise.gd` derives a weight factor from `Config.current_weapon_weight` on the line through its two reference points, 30% at 1kg and 100% at 5kg. The reference points are named constants in `Hooks/Noise.gd`.

| weight | factor |
|---|---|
| 1kg | 30% |
| 2kg | 47.5% |
| 3kg | 65% |
| 4kg | 82.5% |
| 5kg | 100% |
| 6kg | 117.5% |
| 8kg | 152.5% |

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
* A pistol of about 1kg drifts at under a third of that.
* Attaching a suppressor, optic or a full magazine raises the drift. Stripping the weapon lowers it.
* Holding breath and exhausted arms change the drift by the same ratios as today, on top of the weight.
* Low ready, raised and firing wobble are the same for every weapon.

## Tradeoffs

* The cached weight over reading the weapon item every frame. The cost: the weight is as fresh as the last rig update, so rounds fired from the magazine do not lower the drift until the next rig update.
* No clamp over a floor and ceiling. The cost: a very heavy build drifts well past today's level, 152.5% at 8kg, and that stacks with the exhausted arms multiplier.
* Aim and canted only over every stance. The cost: a step in wobble amplitude between canted and low ready that depends on the weapon, larger the further its weight is from 5kg.
* A separate 5kg reference over reusing the 4kg arm stamina reference. The cost: two weight baselines in the mod that mean different things.
