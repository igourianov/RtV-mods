# Weapon collision probe scales with weapon length

## Intent

The weapon collision probe deflects the rig off nearby geometry. Its length should reflect how far the weapon actually reaches, including any muzzle device, instead of the coarse authored bucket. Short weapons currently deflect off walls they are nowhere near, and the longest rifles clip walls they should have deflected from.

## Constraints and assumptions

* Collision *behavior* is unchanged. What `gameData.isColliding` means, when it is set, which pose the rig moves to and which systems read it all stay exactly as they are today. Only the probe's length changes.
* The probe stays a `RayCast3D`. No shape cast, no additional probes, no change to `collision_mask`.
* No clearance margin. The probe length is the measured reach, so collision fires when the muzzle tip would touch. The barrel briefly entering geometry while the rig slews to its collision pose is accepted.
* No MCM setting. This is a correction to authored data, always active.
* `WeaponRig` only. Knife, grenade, fishing and instrument rigs keep their authored probe lengths and their own collision handling untouched.
* Reach is derived from a fixed pose, never the live one. Deriving it from the current pose creates a feedback loop: the probe fires, the rig retracts, the muzzle pulls back, the probe shortens, the collision clears, the rig extends and fires again.
* Ruled out: deriving reach from mesh AABBs or from the firing `raycast` reference node. The `muzzle` reference node is the authored muzzle tip, is already maintained by the game across attachment changes, and needs no new data.
* Ruled out: adding a length field to `WeaponData`. That would mean shipping overrides for all 25 weapons and re-deriving them whenever the game patches a rig. The measurement is already in the scene.

## Scope

Owned:

* `likhos-vostac/Scripts/Hooks/Handling.gd` — sizes the probe on every rig update, in `on_rig_update_post`.

Context only, not modified:

* `src/Scripts/WeaponRig.gd` — supplies `muzzle`, `collision`, `muzzlePosition` and `UpdateMuzzlePosition()`.
* `src/Scripts/RigManager.gd` — instantiates the rig and resolves attachments in `RigUpdate` before the post hook fires.
* `src/Scripts/Handling.gd` — reads `collision.is_colliding()`. Untouched, and its consumers of `gameData.isColliding` (`Camera.gd`, `WeaponRig.gd`, VosTac's `WeaponRig_Optic.gd`) see no semantic change.
* Every `Items/Weapons/*/*_Rig.tscn` — authors the `Collision` node whose `target_position` is overwritten at runtime.

## Solution

### The probe

Each weapon rig carries a `Collision` `RayCast3D` as a direct child of the rig root, at identity, pointing `+Z` (rig forward) with a length authored as `target_position.z`. VosTac replaces that authored length with the weapon's measured forward reach.

Reach is the distance from the rig root to the muzzle tip with the rig in its **high** pose:

```
reach = -data.highPosition.z + muzzle_offset_z
```

`highPosition` is the reference pose because it is the most forward of the three firing poses on every weapon, so a probe sized to it also covers aim and canted. `highRotation` and `aimRotation` are zero on all 25 weapons, so the muzzle projects its full length straight down the probe axis and no rotation term is needed. It is also the one pose VosTac does not already override per-optic, unlike `aimPosition`.

The `-` is because `Handling` maps its target to `Vector3(-target.x, target.y, -target.z)`, so a negative authored `z` is forward.

### Muzzle offset

`muzzle_offset_z` is the muzzle node's forward distance in `Handling`-local space. `Handling` is a direct child of the rig root at identity, so measuring in its local frame factors the pose out of the result while keeping the same origin and axis as the probe:

```
handling.to_local(rig.muzzle.global_position).z
```

It is measured on each rig update, not per frame. The `Sway`, `Noise`, `Tilt`, `Impulse` and `Recoil` nodes between `Handling` and the muzzle inject centimetre-scale live deltas, so a per-frame measurement would jitter the probe length. Rig updates only fire on equip and on attachment change, so the value is stable throughout play.

The muzzle sits under a `References` node, a `BoneAttachment3D` bound to the weapon's `_Origin` bone. That bone resolves to identity in the weapon's model space on every rig, which is what it exists for, so the muzzle's local position needs no bone-pose arithmetic. On the 19 rigs whose origin bone is a direct child of the body bone, its rest is the exact negation of the parent's offset. On the six built over a deeper skeleton — Glock 17, P320, KP-31 and the RK-62 / RK-62M / RK-95 family — the same identity falls out of the accumulated chain rather than a single negation.

The attachment having applied its bone transform is likewise not a concern, even though `RigManager` calls `UpdateRig` in the same frame it adds the rig to the tree.

Guard the result: the probe length is written only when the measurement is positive and within a sane bound for a shoulder weapon. Otherwise nothing is written and the rig keeps the length it already has, which on a freshly instantiated rig is the authored value. A weapon whose layout defeats the measurement behaves as it does today rather than losing collision entirely. The reason is reported through `Out`.

### Muzzle devices

Muzzle devices need no term of their own. `UpdateMuzzlePosition()` shifts `muzzle.position` forward when a device is attached and restores it to the authored `muzzlePosition` when there is none, and `RigManager.RigUpdate` calls it before the post hook fires. The measured offset therefore already carries the device's extension, so the reach is suppressor-aware without the mod ever restating the game's own offset constant.

Adding an explicit `rig.muzzle.position.z - rig.muzzlePosition.z` term on top would double-count, and only on weapons that have a device fitted — the term is zero when bare, so the error is invisible on most of the arsenal.

### Flow

1. `RigManager.UpdateRig` resolves attachments, setting `activeMuzzle` and calling `UpdateMuzzlePosition()`, so `muzzle.position` reflects any attached device.
2. `rigmanager-updaterig-post` fires. VosTac's `Handling.on_rig_update_post` already resolves the active rig there and reads its weapon data. It now also writes `rig.collision.target_position.z` from the two terms.
3. `src/Scripts/Handling.gd` reads `collision.is_colliding()` unchanged, and VosTac's `on_weapon_handling` routes it into `gameData.isColliding` unchanged.

`UpdateRig` is the single site because every path that produces a rig runs it: an equip is `ClearRig()`, `instantiate()`, `add_child()`, `UpdateRig(false)`, and an attachment change calls it against the existing rig. So one hook covers weapon swaps and suppressor swaps alike, and a suppressor attached in the inventory takes effect on the next equip.

### Expected result

Probe lengths against the authored buckets. Because the `_Origin` bone resolves to identity, these are exactly `-highPosition.z + muzzle.position.z`, with no reference chain offset to account for:

| weapon | authored | measured | change |
|---|---|---|---|
| MP7 | 0.8 | 0.50 | shortens 0.30 |
| MP5K | 0.8 | 0.50 | shortens 0.30 |
| MK18 | 1.0 | 0.62 | shortens 0.38 |
| HK416 | 1.0 | 0.63 | shortens 0.37 |
| Glock 17 | 0.5 | 0.43 | shortens 0.07 |
| AKM | 0.8 | 0.71 | shortens 0.09 |
| SVD | 1.0 | 1.05 | lengthens 0.05 |
| Mosin | 1.0 | 1.22 | lengthens 0.22 |

A suppressor adds its extension on top, so a suppressed weapon deflects earlier than an unsuppressed one for the first time.

## Tradeoffs

* **Runtime measurement over authored per-weapon data.** Costs a scene-structure dependency: the solution assumes `Handling` is a direct identity child of the rig root and that `muzzle` sits under the `References` bone attachment, which holds for all 25 stock rigs. In exchange it needs no override table, survives game patches to rig geometry, and covers any weapon a future mod adds. The fallback path keeps a rig with an unexpected layout on vanilla behavior.
* **`highPosition` as the reference pose over aim or canted.** Sized to the most forward firing pose, so it is marginally conservative when aiming, by the 1-5cm the aim pose sits behind high. Sizing to `aimPosition` instead would let the rig aim into a wall that the high pose would have deflected from, and would drag VosTac's per-optic aim overrides into the calculation.
* **No clearance margin.** The most literal reading of the intent, and the probe fires exactly where the muzzle is. The cost is that with the rig already in a firing pose and the player walking forward, the barrel enters geometry for the duration of the slew to the collision pose. A constant margin would hide that at the cost of every weapon deflecting earlier than its true length.
* **One hook site, no cached state.** Measuring inside `on_rig_update_post` rather than caching a base offset at `weaponrig-_ready-post` drops an owned file and a member variable, and the not-written guard reproduces the fallback that a stored authored length would have provided. The cost is that the measurement absorbs whatever sway and recoil delta exists at that instant, so two equips of the same weapon can differ by a centimetre or two. Rig updates are rare enough that this never shows as jitter during play.
