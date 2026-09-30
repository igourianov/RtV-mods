# Feature catalogue

Every feature and bugfix shipped by the mods in this repo, with the files and functions that implement it. Paths are relative to the mod folder. Sources are the READMEs, CHANGELOG and scripts as of 2026-09-30. Function mapping is based on the code structure and comments, so check the code before relying on a specific line.

Hook names below use the loader form (e.g. `handling-weaponhandling`). "replace" means the vanilla method is skipped, "pre" and "post" run around it.

## Contents

* [likhos-vostac](#likhos-vostac)
* [likhos-tag](#likhos-tag)
* [likhos-tacmed](#likhos-tacmed)
* [likhos-no9](#likhos-no9)
* [likhos-magdump](#likhos-magdump)
* [likhos-second-hand](#likhos-second-hand)
* [likhos-eventuality](#likhos-eventuality)
* [likhos-keymod](#likhos-keymod)
* [likhos-radiola](#likhos-radiola)
* [mod-lib](#mod-lib)

---

## likhos-vostac

Entry point: `Scripts/Main.gd` `setup()` registers every hook, the three input actions and the `BinocularsOverlay` node. MCM config lives in `Scripts/ModConfig.gd` (`create_template`, `apply_config`, `gated`, `locked`).

Script abbreviations: `Hooks/` = `Scripts/Hooks/`, `Nodes/` = `Scripts/Nodes/`, `Cards/` = `Scripts/InspectCards/`.

### Novel features

#### Binoculars
* 6-12x observation binos, hold B (rebindable, MMB supported). Hold and toggle activation modes.
* Files: `Nodes/BinocularsOverlay.gd` (`_ready`, `_build_overlay`, `_input`, `_process`, `_change_zoom`, `_can_raise`, `_apply`), `Hooks/Handling.gd` (`_set_target` binos branch stows the rig out of view), `Main.gd` (`binoculars` action), `Audio/ZoomClickPlayer.gd` (zoom click), `ZoomAccelerator.gd`.
* Sub-features:
  * Zoom acceleration and click sound: `BinocularsOverlay._change_zoom`, `ZoomClickPlayer.click`, `ZoomAccelerator.step`.
  * Sensitivity based on look sens, not scope: `Hooks/Controller.gd` `_target_sensitivity`.
  * Mutually exclusive with NVG, auto-deactivate on sprint: `BinocularsOverlay._process`, `Hooks/NVG.gd` `on_physics_process`.
  * Rangefinder: `BinocularsOverlay._ensure_ray`, `_update_rangefinder`.
  * Action priority rework (aim straight out of binos): `BinocularsOverlay._input`, `Hooks/Handling.gd` `_resolve_aim_intent`.
  * Forces weapon position down, blocks raised mode while active: `Hooks/Handling.gd` `_set_target`, `BinocularsOverlay._can_raise`.
  * LootLight integration: `BinocularsOverlay._apply_loot_light`.
  * Compressed grime texture: `BinocularsOverlay._load_texture`.

#### Hold breath
* Hold Sprint while aiming to steady aim at the cost of stamina.
* Files: `Hooks/Character.gd` (`on_stamina`, `_hold_breath`), `Hooks/Noise.gd` (`_apply_wobble`, `WOBBLE_MULT_HOLD_BREATH`), `ModConfig.gd` (`hold_breath_state`).

#### Kill counter
* Scratch-tally card in weapon inspect mode, purple marks for bosses.
* Files: `Hooks/KillCounter.gd` (`on_ai_death`, `on_load_scene_pre`), `Cards/KillCounterCard.gd` (`set_group`, `_paint`, `_draw_tick`, `_draw_slash`, `_draw_stroke`), `Hooks/HUD.gd` (`_setup_kill_cards`, `_update_kill_cards`).
* Hooks: `ai-death-pre`, `loader-loadscene-pre`.
* Related: AK12 and AKM inspect positions raised so tallies stay visible: `WeaponPatches.gd` `apply`.

### Weapons and handling

#### Adaptive Free Look mode (replaces lowered/patrol weapon mode)
* Files: `Hooks/Handling.gd` (`_set_target_idle`, `_apply_target`, `_apply_left_arm`, `_stow_rotation`, `_stow_hold`), `ModConfig.gd` (`free_look`).
* Sub-features: patrol position decoupled from the free look setting, separate pistol branch, fluid transitions, stow timing tweaks, left arm collapse while stowed (`_apply_left_arm`).

#### Canted aim as independent action
* Canted is separate from aim, with optional laser auto-on, and rotation with/without optic is split.
* Files: `Hooks/Handling.gd` (`_resolve_aim_intent`, `_set_target`, `_SECONDARY_OPTIC_ROT_OFFSET`), `Hooks/Laser.gd` (`__process_post` auto-on latch), `ModConfig.gd` (`laser_auto_on`).

#### Handling speed by stance and optic
* Red dot and LPVO 1x 115%, canted 130%, magnified 80%. Applies in and out of the state. Slowed speed for Inspect, Ammo Check and Insert.
* Files: `Hooks/Handling.gd` (`on_rig_update_post` saves weapon weight and action, `on_weapon_handling`, `_apply_target`).

#### Reload, ammo check and insert rework
* Reload binding held over 300ms performs ammo check and ammo shows while held. Fire during ammo check reloads directly (detachable mags). Hold action instead of toggle for insert. Old ammo check and insert bindings removed. Lock-out at animation tail trimmed.
* Files: `Nodes/WeaponRig_Reload.gd` (`_input`, `_process`, `_do_reload`, `_play_reload`, `_show_mag_delayed`, `_update_bullets_delayed`, `_set_view_delayed`), `Nodes/WeaponRig_Base.gd` (`play`, `await_animation`, `is_engine_busy`), `Main.gd` (`remove_action("ammo_check")`, `remove_action("insert")`), `Hooks/WeaponRig.gd` (`_inject_handler`).
* Sub-fixes:
  * Ammo check no longer forces raised weapon: `Hooks/Handling.gd` `_set_target`.
  * Mag showing empty or disappearing on reload from no-mag or ammo check: `WeaponRig_Reload._show_mag_delayed`, `_update_bullets_delayed`.
  * Semi guns firing on reload from ammo check with no valid mag: `WeaponRig_Fire._fire_input`.
  * Deadlock and softlock when opening the inventory while checking ammo: `WeaponRig_Reload._input`, `_exit_tree`.
  * Missing left arm when reloading while looking down: `Handling._apply_left_arm`.

#### Manual action guns (Mosin and 870)
* Cycle the bolt on full or empty mag (ammo is lost), dry fire click on empty chamber, insert preparation is a hold action, reduced animation lock.
* Files: `Nodes/WeaponRig_ManualReload.gd` (`_input`, `_process`, `_play`, `_insert_delayed`, `_close_bolt_delayed`), `Hooks/WeaponRig.gd` (`on_casing_eject_post`).
* Sub-fixes:
  * Mosin ending up in a mag + 0 state after opening and closing the bolt: `WeaponRig_ManualReload._process`.
  * Mosin casing and live round not ejecting, missing animations: `WeaponRig_ManualReload._inject_mosin_casing_eject`.
  * 870 losing the chambered shell on insert preparation: `WeaponRig_ManualReload._process`.
  * Chamber flag not cleared when clearing casing: `Hooks/WeaponRig.gd` `on_casing_eject_post`.
  * Bolt work no longer drops out of aim.

#### Cocked state and dry fire
* All guns get a cocked state and click when firing empty but cocked. Also gates negligent discharge.
* Files: `Nodes/WeaponRig_Fire.gd` (`_fire_input`, `_play_dry_click`), `Audio/AttachmentClickPlayer.gd`, `ModConfig.gd` (`negligent_discharge`).
* Hook: `weaponrig-_physics_process` (replace with noop), `weaponrig-ads` (replace with noop).

#### Inspect mode rework
* Rewritten bindings and states, rotation with the Canted binding, rail movement only in inspect, no stamina drain, ammo and attachment cards, flashlight lights the weapon.
* Files: `Nodes/WeaponRig_Inspect.gd` (`_input`, `_process`, `_inspect_toggle`), `Hooks/Handling.gd` (`on_input`), `Hooks/Flashlight.gd`, `Cards/InspectCard.gd`, `Hooks/HUD.gd` (`_update_attachment_cards`).

#### Inspect cards
* Ammo count, chamber status and fire selector cards, optional icon replacers (off by default).
* Files: `Cards/InspectCard.gd`, `Cards/AmmoCardReplacer.gd`, `Cards/ChamberCardReplacer.gd`, `Cards/FireModeCard.gd`, `Hooks/HUD.gd` (`_setup_firemode_card`, `_setup_ammo_replacer`, `_setup_chamber_replacer`, `_update_ammo_cards`, `_update_firemode_card`).
* Sub-features: card positioning and reduced redraws (`InspectCard.point_at`, `redraw`), dropped weapon icon ammo obfuscation.

#### Weapon collision probe scaled to real weapon length
* Replaces vanilla's coarse length buckets and counts muzzle devices. Uses the patrol/stow position to avoid rig flicker near walls.
* Files: `Hooks/Handling.gd` (`on_rig_update_post`, `_set_target`, constant `_STOW_POS_OFFSET`).

#### Negligent discharge toggle
* MCM option to allow or block firing out of aim.
* Files: `Nodes/WeaponRig_Fire.gd` `_fire_input`, `ModConfig.gd`.

### Aiming and optics

#### Laser zeroed at 30m
* Dot fades out between 30m and 50m, PEQ-15 laser recoloured red, ray aligned with collision dot.
* Files: `Hooks/Laser.gd` (`_converge`, `_fade_point`, `_recolor`, `_tint_mesh`, `ZERO_DISTANCE`, `_ensure_click`), hooks `laser-_input` (replace) and `laser-_process-post`.

#### Sensitivity by stance and zoom
* Scales with stance and progressively with magnification, lerped on transition.
* Files: `Hooks/Controller.gd` (`on_input`, `_mouse_input`, `_target_sensitivity`).

#### Secondary optic toggle out of aim
* Visual cue for the toggle.
* Files: `Nodes/WeaponRig_Optic.gd` (`_handle_secondary_optic`, `_handle_ads` ocular opacity), `Hooks/Handling.gd` (rotation offset).

#### PIP scope rework
* Files: `Nodes/WeaponRig_Optic.gd` (`_handle_ads`, `_update_optic_camera`, `_update_reticle`), `Hooks/Optic.gd` (`on_physics_process_pre`, `_msaa_from_pref`, `_ssaa_from_pref`), `ScopeCatalog.gd` (`get_optic_geometry`, `compute_angle`, `_measure_lens`), `Hooks/Camera.gd` (`on_scope_dof`).
* Sub-features:
  * FOV math reworked (prism scopes, eye relief scaling): `compute_angle`, `_update_optic_camera`.
  * Main camera FOV no longer narrows, LPVOs stay scoped at 1x: `WeaponRig_Optic._handle_ads`.
  * DOF scales with magnification, lerped, near-DOF enabled: `Hooks/Camera.gd` `on_scope_dof` (replace).
  * PIP MSAA matches main viewport (MCM toggle): `Hooks/Optic.gd`.
  * NVG-aware blur when aiming a magnified optic (MCM toggle): `Hooks/Optic.gd`.
  * PIP shader injection refactored for compat with other scope shader mods: `Hooks/Optic.gd`.
  * Reticle in front of scope shadow, reticle tracks weapon in PIP: `WeaponRig_Optic._update_reticle`.

#### Realistic eye relief and scope shadow
* Penalty shadow outside declared eye relief, no wobble, rail position alters eye relief.
* Files: `ScopeCatalog.gd` (`DATA` eye_relief per optic, `compute_shadow`), `Nodes/WeaponRig_Optic.gd` (`_validate_lens_distance`, `_update_reticle`).

#### Optic self-damage
* Aiming with an optic mounted too close hurts the player.
* Files: `Nodes/WeaponRig_Optic.gd` `_validate_lens_distance` (protip `optic-too-close`).

#### Scope catalogue (magnifications, rarity, tooltips)
* New magnification ranges, MCM schema Short / Normalized / Discrete, acceleration, scoped sensitivity.
* Changes: Mark 8 (Leopard) 1.1-8x with fixed reticle, Vudu 1-10x and legendary, POSP 2-6x with fixed reticle and dovetail movement, HAMR legendary, PU moved back and real 3.5x.
* Files: `ScopeCatalog.gd` (`DATA`, `get_mag_range`, `apply`), `ZoomAccelerator.gd` (`step`), `Nodes/WeaponRig_Optic.gd` (`_handle_zoom`), `Hooks/Tooltip.gd` (`on_update_post` shows real magnification and eye relief), `Main.gd` (`optic_zoom_in`, `optic_zoom_out` actions).

#### LPVO zoom without aiming
* Gated by the Rail movement modifier by default (MCM).
* Files: `Nodes/WeaponRig_Optic.gd` `_handle_zoom`.

#### Explicit zoom bindings
* Files: `Main.gd` (`register_action` for `optic_zoom_in` and `optic_zoom_out`), `Nodes/WeaponRig_Optic.gd`.

### Movement and stamina

#### Arm and leg stamina rework
* Arm drain by weapon weight and stance, recovery and delay by Energy. Leg drain by inventory weight, recovery and delay by Hydration. Dynamic recovery delay. Overweight, fracture and zero leg stamina block sprint. Higher scope sway when out of arm stamina. Simplified drain logic with MCM toggle.
* Files: `Hooks/Character.gd` (`on_stamina` replace, `_body_stamina`, `_arm_stamina`, `_recovery_delay_threshold`), `Hooks/Noise.gd` (`_apply_wobble`, `_calculate_speed_factor`).

#### Movement speeds
* Crouch/walk/sprint 0.7 / 3 / 7, stance multipliers 0.6 / 0.75 / 0.3, editable in MCM.
* Files: `Hooks/Controller.gd` (`on_movement_states` replace, `_update_state`, `_apply_speed`), `ModConfig.gd`.
* Fix: walk speed MCM override not applying.

#### Input priority (last action wins)
* Crouch, Sprint, Aim and Canted override each other by last input. Aim and canted override sprint. Sprint overrides crouch.
* Files: `Hooks/Controller.gd` (`on_input` replace, `on_crouch` replace), `Hooks/Handling.gd` (`on_input`, `_resolve_aim_intent`).

### Controls and HUD

#### Dynamic crosshair
* Idle crosshair for interactions, hidden when aiming, canted or raised, MCM visibility and fade options.
* Files: `Nodes/Crosshair.gd` (`_draw`, `_update_visibility`, `_update_tooltip`, `_is_interaction_blocked`), `Hooks/HUD.gd` (`_setup_crosshair`), `Hooks/UIPosition.gd` `on_physics_process_post`.
* Sub-features: hides on zone transition prompt, unshifts interaction tooltip when crosshair is off.

#### Flashlight and NVG activation modes
* Toggle and hold on the same binding. Fixed double click sound on the flashlight and click sound for held NVG.
* Files: `Hooks/Flashlight.gd` (`on_physics_process` replace, nested input node), `Hooks/NVG.gd` (`on_physics_process` replace, nested input node), `Audio/AttachmentClickPlayer.gd`.

#### Protips
* In-game hints about changed bindings.
* Files: `Out.protip` calls in `Nodes/WeaponRig_Fire.gd`, `WeaponRig_Inspect.gd`, `WeaponRig_ManualReload.gd`, `WeaponRig_Reload.gd`, `WeaponRig_Optic.gd`, `ModConfig.gd` (`show_protips`).

#### Weapon stow on inventory disabled
* Files: `Hooks/Handling.gd` `_set_target`.

### Vanilla bug fixes

* PIP viewport bobbing independently from the rig: `Hooks/Tilt.gd` `on_physics_process_pre`, `Hooks/Recoil.gd` `on_apply_recoil_post`, `Hooks/Noise.gd` `on_physics_process_post`.
* Canted aim blocked by interactables, tooltip blocking view while aiming, no interaction during ammo check, stale transition prompt: `Hooks/Interactor.gd` `on_physics_process_pre`, `Hooks/Tooltip.gd` (`on_reset_post`, `on_update_post`).
* Zone transition prompt shown in inspect mode and weapon stow on the prompt: `Hooks/Interactor.gd`, `Hooks/Handling.gd`.
* HAMR secondary optic killing the PIP plane on other scopes (`secondaryOptic` not reset): `ScopeCatalog.gd` `sync_optic_state`.
* HAMR secondary optic vertical offset on AK rifles, SVD and Vintorez (missing `optic.scale`): `ScopeCatalog.gd` `sync_optic_state`.
* HAMR flicker on M4A1 (no foldable front sight, missing `frontSightIndex` check): `Hooks/Handling.gd` `on_rig_update_post`.
* Optic rail limits outside min/max and float math in rail movement (HAMR and ACOG on M78, T2 on M4A1, POSP, PU on Mosin): `RigOpticPatches.gd` `PATCHES`, `Nodes/WeaponRig_Inspect.gd` (rail movement).
* AK12 and AKM inspect position showing arm ends: `WeaponPatches.gd` `apply`.
* Laser ray misaligned with collision dot: `Hooks/Laser.gd` `_converge`.
* Weapon collision sized from coarse buckets: see the collision probe entry above.
* Flashlight draining battery while the world is frozen: `Hooks/Flashlight.gd` `on_physics_process`.
* Fixed camera shake sticking on entering binos while firing, vertical aim smoothing from free look, aim toggling on right click from inventory, left arm missing after inventory with free look disabled: `Hooks/Handling.gd`, `Hooks/Controller.gd`, `BinocularsOverlay._process`.

### Hooks registered (see INSTRUCTIONS.md for the compatibility view)
Replace: `handling-weaponhandling`, `handling-weaponposition`, `weaponrig-_input`, `weaponrig-ads`, `weaponrig-_physics_process`, `camera-scopedof`, `controller-movementstates`, `controller-_input`, `controller-crouch`, `laser-_input`, `flashlight-_physics_process`, `nvg-_physics_process`, `character-stamina`.
Pre/post: `rigmanager-updaterig-post`, `weaponrig-_ready-post`, `weaponrig-casingeject-post`, `controller-_physics_process-post`, `noise-_physics_process-post`, `tilt-_physics_process-pre`, `hud-_ready-post`, `hud-_physics_process-post`, `recoil-applyrecoil-post`, `optic-_physics_process-pre`, `laser-_process-post`, `tooltip-reset-post`, `tooltip-update-post`, `interactor-_physics_process-pre`, `uiposition-_physics_process-post`, `item-updatedetails-post`, `ai-death-pre`, `loader-loadscene-pre`.

---

## likhos-tag

Renames weapons, attachments, magazines and ammo, sets real-life weights, and slims the tooltip. Loaded late (priority 10) so its values win.

#### Renames and weights
* Files: `Scripts/Catalog.gd` (`DATA` per item file name, applied through `lib.patch(ITEMS)`), `Scripts/ModConfig.gd` and `Scripts/Main.gd` (`create_config`, `load_config`: Russian vs English names).

#### Functional tweaks
* MP7 mag 30 to 40, KAR-21 (.308) mag 30 to 20, VSS penetration 3 to 4.
* Files: `Scripts/Catalog.gd` (`DATA` entries for the MP7 mag, KAR-21 .308 mag and VSS).

#### Tooltip rework
* Less verbose, shows caliber and bullet weight.
* Files: `Scripts/Tooltip.gd` (`on_reset_post`, `on_update_post`, `_get_caliber`), base `Lib/Tooltip.gd`. Hooks: `tooltip-reset-post`, `tooltip-update-post`.

---

## likhos-tacmed

#### IFAK and AFAK as reusable kits
* Not consumed, lose condition, heal exactly the needed amount. IFAK 150 healing pool, only removes bleeding and burning, weight 2kg, sold by Doctor for 1000. AFAK 200 HP pool, no Energy/Hydration/Mental, weight 5kg, price 5000, sold by Doctor, use time 3s.
* Files: `Scripts/Main.gd` (`_patch_items`: `lib.patch` on `IFAK` and `AFAK`), `Scripts/Interface.gd` (`on_use` replace, `_use`, `_use_anim`). Hook: `interface-use`.

#### Refill by combining
* Drag basic healing items onto the kit, 1:1 healing value to condition, tourniquet 10%.
* Files: `Scripts/Interface.gd` (`on_release_pre`, `_combine`), `Scripts/Main.gd` (`compatible` list in `_patch_items`). Hook: `interface-release-pre`.

#### AFAK refill recipe
* Used AFAK + 2x Medkit gives AFAK 100%.
* Files: `Scripts/Main.gd` `_register_recipes` (`lib.register(RECIPES)`), `Recipes/AFAK.tres`.

#### Quick-use binding (Z)
* Picks the item that minimises waste.
* Files: `Scripts/Main.gd` (`register_action("tacmed")`), `Scripts/Interface.gd` (`_input`, `_tacmed_heal`, `_prioritize_tacmed`, `_cond_heal_count`).

#### Debug hurt keys
* Ctrl+Shift+O (bleed) and Ctrl+Shift+P (random injury) for testing.
* Files: `Scripts/Main.gd` (`register_action("hurt_myself")`, `register_action("hurt_myself_more")`), `Scripts/Interface.gd` (`_hurt_myself`).

---

## likhos-no9

#### Weapon Cleaning Kit
* Weapon Repair Kit renamed, drag a weapon onto it to restore condition from the kit's own pool. Kit is not consumed but loses the same condition. Works with modded weapons.
* Files: `Scripts/Main.gd` (`_patch_wrk` uses `lib.find` and `lib.patch`), `Scripts/Interface.gd` (`on_release_pre`, `_combine`, `_use_anim`). Hook: `interface-release-pre`.

#### Per-gun repair recipes removed
* Files: `Scripts/Main.gd` `_strip_repair_recipes` (mutates `res://Crafting/Recipes.tres`).

#### Kit refill recipe
* Files: `Scripts/Main.gd` (`lib.register(RECIPES, "likhos_cleaning_kit_refill")`).

#### Shared slotData fix
* Makes the kit's slotData local to scene so condition is not shared between kits.
* Files: `Scripts/Main.gd` `_localize_wrk_slotdata`.

---

## likhos-magdump

Cross-compatible magazines: AK-74SU with AK-12, AKM with RK variants, KAR-21 (.223) with STANAG rifles.

* Compatibility table and tetris patches: `Scripts/CompatTable.gd` (`COMPAT`, `MAG_PICKUPS`, `MAG_STATICS`, `apply` uses `lib.patch(ITEMS, tetris)`).
* Magazine swap logic: `Scripts/Interface.gd` `on_get_magazine` (replace). Hook: `interface-getmagazine`.
* Correct mag model on the rig: `Scripts/RigVisual.gd` (`on_ready_post`, `on_update_rig_pre`, `refresh_after_cross_swap`, `refresh_after_attach`, `_resolve_pointer`, `_scale_along_axis`, `_find_mag_bone`, `_get_loaded_mag_file`). Hooks: `weaponrig-_ready-post`, `rigmanager-updaterig-pre`.
* Correct mag model on dropped pickups: `Scripts/Pickup.gd` (`on_ready_post`, `_find_native_mag_node`). Hook: `pickup-_ready-post`.

---

## likhos-second-hand

Shrinks AKS-74U, VSS, Remington 870, KP-31 and Mosin by one cell, and lets AKS-74U, VSS and 870 use the secondary slot.

* Resize and slot patches: `Scripts/Patches.gd` (`RESIZE`, `SECONDARY`, scale and offset fields, `lib.patch(ITEMS)`).
* Sprite scaling workaround for vanilla's hardcoded 0.5 scale: `Scripts/Item.gd` (`on_update_sprite_pre`, `on_update_sprite_post`). Hooks: `item-updatesprite-pre` and `item-updatesprite-post`.

---

## likhos-eventuality

#### Independent event probabilities
* Each dynamic event gets its own roll, multiple events can be active. BTR/Police and Airdrop/CrashSite are exclusive, and skipped events carry a roll bonus to the next map load.
* Files: `Scripts/EventSystem.gd` (`on_activate_dynamic_event` replace, `_activate_dynamic_event`, `_activate_delayed_event`, `blockers`, `_rollBonus`). Hook: `eventsystem-activatedynamicevent`.

#### MCM probabilities
* Files: `Scripts/ModConfig.gd` (`_create_config_template`, `_apply_config`, `get_probability`).

#### Police van without sirens is no longer a dud
* The siren-less variant triggers the Punisher, van speed capped at 15 (from 25).
* Files: `Scripts/Police.gd` (`on_ready_post` forces Boss state, `on_states_post` caps speed). Hooks: `police-_ready-post`, `police-states-post`.

#### Crash site explosion sound
* Audible explosion 5-20s after spawn, 2-4 blasts.
* Files: `Scripts/EventSystem.gd` (`on_crash_site` replace, `_play_delayed_explosion`, `_spawn_explosion`). Hook: `eventsystem-crashsite`.

#### Repeating fighter jet
* 3-10 repeats at 60-300s intervals.
* Files: `Scripts/EventSystem.gd` (`on_fighter_jet_post`, `_schedule_fighter_jet`, `_jetCounter`). Hook: `eventsystem-fighterjet-post`.

---

## likhos-keymod

#### Loot room keys sold by traders
* Gunsmith sells Gym key, Doctor sells Cellar key, Generalist sells Tunnel key, 5000 each.
* Files: `Scripts/Main.gd` `setup` (`lib.patch(ITEMS)` on `Key_Gymnasium`, `Key_Cellar`, `Key_Tunnel`).

---

## likhos-radiola

#### Station cycle on the radio
* Interact cycles Off, Vanilla, then each registered station.
* Files: `Scripts/Hooks/Radio.gd` (`on_interact` replace, `_tune_to`, `_tick_tuning`, `_play_tuning`). Hook: `radio-interact`.

#### Interaction prompt shows current state
* Files: `Scripts/Hooks/Radio.gd` `on_update_tooltip_post`. Hook: `radio-updatetooltip-post`.

#### Auto-play on find
* Chance configurable in MCM.
* Files: `Scripts/Hooks/Radio.gd` `on_physics_process_pre`, `Scripts/ModConfig.gd`. Hook: `radio-_physics_process-pre`.

#### Wall-clock playback
* Stations do not restart on activation.
* Files: `Scripts/RadioStation.gd` `now_playing`, `Scripts/Nodes/RadioPlayer.gd` (`start`, `_play_current`).

#### Old FM sound and tuning static
* Files: `Scripts/RadioBus.gd` (`LikhosRadiola` bus), `Scripts/Nodes/StaticNoisePlayer3D.gd`, `Scripts/Nodes/RadioPlayer.gd` `_sync_static`, `Lib/AudioChunkPlayer3D.gd`.

#### Station pack plugin system
* Files: `Scripts/RadioRegistry.gd` (`register_dir`), `Scripts/RadioTrack.gd`.
* Packs (each only `Main.gd` + `mod.txt` + audio): `likhos-radiola-doomer`, `likhos-radiola-hardboss`, `likhos-radiola-kolkhoz`, `likhos-radiola-sovietwave`.

---

## mod-lib

Shared base library copied into every mod as `Lib/` by the build.

* `Main.gd`: base class with `setup`, `register_hook`, `register_action`, `remove_action`, `create_key_input`, `create_mouse_input`, `create_config` and `load_config`.
* `Out.gd`: normalised debug, warning and `protip` output.
* `Inputs.gd`: in-game action binding control (`get_binding`).
* `Tooltip.gd`: base tooltip helpers (`_hide_row`) used by tag and vostac.
* `AudioChunkPlayer.gd`, `AudioChunkPlayer3D.gd`, `AudioEventPlayer.gd`: audio helpers (refactored sound helpers in VosTac 2.18, radio playback in Radiola).
