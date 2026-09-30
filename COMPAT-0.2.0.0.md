# Compatibility with game 0.2.0.0

Results of per-feature verification of all mods against the new vanilla version (0.2.0.0, Godot 4.6.3), compared with the old 0.1.1.3 in the `src/` git history. Work through items one by one. Mark each `[x]` when done.

## Broken

- [x] **vostac: laser toggle calls removed method** (now calls `PlayGadget()`)
  - Vanilla `Laser.PlayLaser()` was renamed to `PlayGadget()` (sound changed from `audioLibrary.flashlight` to `audioLibrary.gadget`).
  - Mod: `likhos-vostac/Scripts/Hooks/Laser.gd:43` calls `caller.PlayLaser()` in the `laser-_input` replace hook.
  - Fix: call `PlayGadget()`. No other `PlayLaser` usages found in the mods.
  - Affects: Laser zeroing, Canted aim (laser toggle).

- [x] **vostac: click sound asset removed** (preload repointed to `Gadget.wav`, offsets kept, confirmed by ear)
  - `likhos-vostac/Scripts/Audio/AttachmentClickPlayer.gd` preloads `res://Audio/Interaction/Files/Flashlight.wav`, which is gone (`Audio/Interaction/Flashlight.tres` also deleted). The script is preloaded by `Hooks/Flashlight.gd`, `Hooks/NVG.gd` and `Hooks/Laser.gd`, so all three fail to load.
  - Vanilla click is now `audioLibrary.gadget` at `res://Audio/Character/Handling/Files/Gadget.wav`. Vanilla `Flashlight.gd` and `NVG.gd` now call `PlayGadget()` instead of `LightAudio()` and `NVGAudio()`.
  - Fix: repoint the preload to `Gadget.wav` and retune the `_IN_START`, `_IN_DURATION` and `_OUT_START` chunk offsets, since the clip differs.
  - Affects: Cocked/dry fire, Flashlight and NVG activation modes, Laser.

- [x] **vostac: kill counter boss check** (now `ai.variant.faction == AIData.Faction.Boss` with null guard)
  - Vanilla removed `AI.boss`. Boss status is now `variant.faction == variant.Faction.Boss` (`AI.gd:1357`, enum in `AIData.gd:4`).
  - Mod: `Hooks/KillCounter.gd:16` reads `ai.boss`, which errors, so no kill is recorded.
  - Fix: use `ai.variant.faction == ai.variant.Faction.Boss` and guard against a null `variant`.
  - Hook target `AI.Death(direction, force)` and `Loader.LoadScene` are unchanged.

- [x] **no9: cleaning kit audio preload** (path updated)
  - `likhos-no9/Scripts/Interface.gd:9` preloads `res://Audio/Crafting/Craft_Metal.tres`. Vanilla deleted `Audio/Crafting/`; the resource moved to `res://Audio/UI/UI_Craft_Metal.tres`. The failed preload breaks `Interface.gd`, `Main.gd` and the `interface-release-pre` hook.
  - Fix: update the path. Optionally guard with a file existence check.

- [x] **no9: kit refill recipe audio** (path updated)
  - `likhos-no9/Recipes/Cleaning_Kit_Refill.tres:4` loads `res://Audio/Crafting/Craft_Plastic.tres`, deleted in vanilla.
  - Fix: use `res://Audio/UI/UI_Craft_Plastic.tres` (no uid needed).

- [x] **tacmed: AFAK refill recipe audio** (path updated)
  - `likhos-tacmed/Recipes/AFAK.tres:4` loads `res://Audio/Crafting/Craft_Fabric.tres`, deleted in vanilla.
  - Fix: use `res://Audio/UI/UI_Craft_Fabric.tres` (uid `uid://dur6q1qyo4pmh`).

- [x] **eventuality: crash site explosion sound** (now `explosionOutdoorFar`; resource has `audioClips`, volume uses `AudioEvent` default)
  - Vanilla `AudioLibrary.grenadeExplosionOutdoorFar` was renamed to `explosionOutdoorFar` (`AudioLibrary.gd:90`, resource `Audio/Effects/Explosions/Explosion_Outdoor_Far.tres`).
  - Mod: `likhos-eventuality/Scripts/EventSystem.gd:122` reads the old name, gets null and returns silently. The crash site still spawns.
  - Fix: use `_AUDIO_LIBRARY.explosionOutdoorFar`. Confirm the resource still has `audioClips` and `volume` (not verified).

## Affected (works, behaviour changed)

- [x] **tacmed: IFAK now cures poisoning** (kept; README and BB README updated)
  - Vanilla `IFAK.tres` gained `poisoning = true` and `Character.Consume` calls `Poisoning(false)` for it.
  - Mod patch in `likhos-tacmed/Scripts/Main.gd:37-47` does not set `poisoning`, but the README says IFAK only removes bleeding and burning.
  - Decision: add `"poisoning": false` to keep the documented behaviour, or accept poisoning cure and update the README.
  - AFAK also gained `poisoning = true`. Probably fine (consistent with its advanced-medkit role), confirm intent.

- [x] **eventuality: Bogeyman event missing night gate and MCM entry** (night check added, `Bogeyman` MCM entry added)
  - New vanilla event `Events/List/D25_Bogeyman.tres` (Dynamic, possibility 10, `night = true`, implemented at `EventSystem.gd:222`). Vanilla `ActivateDynamicEvent` skips night events unless `gameData.TOD == 4` (`EventSystem.gd:106`).
  - Mod replacement `_activate_dynamic_event` (`Scripts/EventSystem.gd:47-70`) has no night check, so Bogeyman can spawn in daytime.
  - `Scripts/ModConfig.gd:13-19` has no `Bogeyman` entry, so it falls back to 10.
  - Fix: add `if e.get("night") && gameData.TOD != 4: continue` and a `Bogeyman` entry (default 10) in `ModConfig.EVENTS`.
  - Also new: Weekly events (`Driver`, `Gathering`). Vanilla only calls `ActivateDynamicEvent` when no weekly event is active, so no change needed.

- [x] **radiola: auto-play vs vanilla random radios** (MCM `on_chance` default 75 replaces vanilla random-on roll; radios that pass pick a random station; gathering radio left alone)
  - Vanilla `Radio._ready()` now sets `active = true` for gathering radios and ~5% of `random` radios (previously all started off).
  - Mod `Hooks/Radio.gd` `on_physics_process_pre` (lines 55-70): if its roll fails, a vanilla-activated radio stays on. If its roll succeeds on an already active radio, its station and vanilla's broadcast play at once.
  - Fix options: skip the roll when `radio.active` is already true, or set `radio.active = false` on the first tick before rolling. Decide how to treat `gathering` radios.
  - `on_interact` already handles the vanilla-active case. Station cycle and tooltip are OK.

## Minor and optional

- [ ] **tag: new vanilla items lack catalogue entries.** Jatimatic (9x19 SMG, 1.7kg) and its magazine (20 rounds, 0.2kg), M28 and M28_MOD (7.62x54R bolt rifles, 4.0kg), HP_DA (9x19 pistol, 0.9kg) and its magazine (14 rounds, 0.1kg), VIRVE and Watch_Tactical (electronics). Add names and weights to `likhos-tag/Scripts/Catalog.gd`.
- [ ] **tag: MP7 mag tweak is redundant.** Vanilla `MP7_Magazine.tres` already has 40 rounds (also in 0.1.1.3). Drop the `DATA` entry or keep it harmless. `FEATURES.md` wrongly says "30 to 40".
- [ ] **keymod: new vanilla items and traders.** `Key_Garage` and the Driver and Hunter traders exist. Vanilla sets no trader flag on `Key_Garage`. Optionally add it to a trader.
- [ ] **vostac: new weapons use default ammo-check intro time.** `AMMO_CHECK_INTRO_TIMES` has no entry for weapons added in 0.2.0.0, so they use 1.0s.
- [ ] **vostac: rig patches and tag catalogue should cover new weapons.** Check new rigs (Jatimatic, M28, HP_DA) for optic rail ranges, inspect positions and collision probe sanity.
- [ ] **tacmed: debug injury roll.** `_hurt_myself` could include the new `Character.Poisoning(active)` in the `randi_range(1,4)` roll.
- [ ] **vostac: two `FEATURES.md` entries may be inaccurate.** The "tooltip hidden while aiming" fix was not found in `Hooks/Tooltip.gd`. The "stow on transition prompt" part was not found in `Hooks/Handling.gd`. Locate the real code or correct the doc.
- [ ] **vostac: pre-existing precedence bug.** `WeaponRig_Fire.gd:34` has `!gameData.weaponPosition == 2`, copied from vanilla `WeaponRig.gd:380`. Not new.
- [ ] **second-hand: pre-existing type issue.** `Patches.gd` does `float(gun.get(f))` on Vector2 offset fields (`magazineSuppressorOffset`, `opticSuppressorOffset`, `fullyModdedOffset`), which would already fail in 0.1.1.3.
- [ ] **vostac: movement ignores `isRazor`.** The new vanilla `Movement()` adds razor velocity jitter. The mod's speed and state logic ignores it, which only matters for the jitter.

## Housekeeping

- [ ] Update `INSTRUCTIONS.md` requirements in every mod (currently "Road to Vostok 0.1.1.3 (Godot 4.6.2)"; new is 0.2.0.0 and 4.6.3).
- [x] Update root `CLAUDE.md` (version 0.2.0.0 and Godot 4.6.3).
- [ ] Re-run the affected hooks in game after fixes and check `godot.log` for `[OverrideVerify]` and load errors.

## Verified OK

No action needed: vostac (Binoculars, Hold breath, Adaptive Free Look, Handling speed, Reload rework, Manual action guns, Inspect mode, Inspect cards, Collision probe, Negligent discharge, Sensitivity, Secondary optic, PIP rework, Eye relief, Optic self-damage, Scope catalogue, LPVO zoom, Zoom bindings, Stamina, Movement speeds, Input priority, Crosshair, Protips, Stow on inventory, PIP bobbing fix, Interactor and transition fixes, HAMR fixes, Rail fixes, AK12/AKM inspect positions, Flashlight battery fix, Misc fixes), tag (renames and weights, functional tweaks, tooltip), tacmed (refill by combining, quick-use, debug keys), no9 (recipe stripping, slotData fix), magdump (all four), second-hand (both), eventuality (police, fighter jet), keymod (keys), radiola (station cycle and prompt, playback and sound, plugin system), mod-lib.

Vanilla fixed none of the bugs the mods patch.
