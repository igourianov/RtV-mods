
# dynamic state vars
static var current_scope_mag: float = 1.0
static var current_weapon_weight: float = 0.0
static var ammo_check_view := false
static var hold_breath_state: float = 0.0
static var optic_shiner: bool = false
static var binoculars_active: bool = false
static var binoculars_mag: float = 6.0
static var kills: PackedByteArray = PackedByteArray([0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0])
static var gameData = preload("res://Resources/GameData.tres")

# config vars
static var crosshair_style: StringName
static var crosshair_color: Color
static var crosshair_while_running: bool
static var crosshair_while_canted: bool
static var crosshair_while_raised: bool
static var cant_mode: StringName
static var lpvo_ooa_zoom: StringName
static var mag_schema: StringName
static var zoom_dof: bool
static var override_movement_speeds: bool
static var nvg_pip_blur: bool
static var ammo_icons: bool
static var chamber_card_mode: StringName
static var ammo_cards_check: bool
static var ammo_cards_inspect: bool
static var ammo_cards_manual_reload: bool
static var crouch_speed: float
static var walk_speed: float
static var sprint_speed: float
static var walk_aim_mult: float
static var walk_cant_mult: float
static var walk_scope_mult: float
static var laser_auto_on: bool
static var attachment_cards: bool
static var firemode_card: bool
static var kill_counter_card: bool
static var pip_anti_aliasing: bool
static var show_protips: bool
static var debug_enabled: bool
static var free_look: bool
static var patrol_position: bool
static var negligent_discharge: bool
static var custom_stamina: bool

static var _menu_pos_auto: int = 0

const DEFAULT_CROSSHAIR_COLOR := Color(0, 1, 0.04, 0.55)
const DEFAULT_CROSSHAIR := "3seg-cross"
const DEFAULT_CANT_MODE := "1default"
const DEFAULT_LPVO_OOA_ZOOM := "3rail"
const DEFAULT_MAG_SCHEMA := "2normalized"
const DEFAULT_CHAMBER_CARD := "1enabled"
const DEFAULT_ENABLED := true
const DEFAULT_CROUCH_SPEED := 0.7
const DEFAULT_WALK_SPEED := 3.0
const DEFAULT_SPRINT_SPEED := 7.0
const DEFAULT_AIM_SPEED_MULT := 0.6
const DEFAULT_CANT_SPEED_MULT := 0.75
const DEFAULT_SCOPE_SPEED_MULT := 0.3
const SPEED_MIN := 0.0
const SPEED_MAX := 20.0
const MULT_MIN := 0.1
const MULT_MAX := 1.5
const BASE_WEAPON_WEIGHT := 4.0

const Out = preload("../Lib/Out.gd")


# tier 1 - weapon handling concern does not run at all
static func gated() -> bool:
	return gameData.menu || gameData.freeze || gameData.isDead || gameData.isTransitioning || gameData.isCaching


# tier 2 - modal weapon actions that own the hands until they complete
static func locked() -> bool:
	return (gameData.isReloading || gameData.isInspecting || gameData.isChecking
		|| gameData.isInserting || gameData.isPlacing || gameData.isDrawing
		|| gameData.isClearing)


static func _get_config_value(config: ConfigFile, section: String, key: String, default_val):
	var value = config.get_value(section, key, {}).get("value", default_val)
	if section == "Dropdown":
		value = value.substr(1)
	return value


static func apply_config(config: ConfigFile) -> void:
	Out.show_protips = _get_config_value(config, "Bool", "show_protips", DEFAULT_ENABLED)
	Out.debug_enabled = _get_config_value(config, "Bool", "debug_enabled", !DEFAULT_ENABLED)
	crosshair_style = _get_config_value(config, "Dropdown", "crosshair", DEFAULT_CROSSHAIR)
	crosshair_color = _get_config_value(config, "Color", "crosshairColor", DEFAULT_CROSSHAIR_COLOR)
	crosshair_while_running = _get_config_value(config, "Bool", "crosshairWhileRunning", !DEFAULT_ENABLED)
	crosshair_while_canted = _get_config_value(config, "Bool", "crosshairWhileCanted", !DEFAULT_ENABLED)
	crosshair_while_raised = _get_config_value(config, "Bool", "crosshairWhileRaised", !DEFAULT_ENABLED)
	cant_mode = _get_config_value(config, "Dropdown", "cantMode", DEFAULT_CANT_MODE)
	lpvo_ooa_zoom = _get_config_value(config, "Dropdown", "lpvoOofZoom", DEFAULT_LPVO_OOA_ZOOM)
	mag_schema = _get_config_value(config, "Dropdown", "magSchema", DEFAULT_MAG_SCHEMA)
	zoom_dof = _get_config_value(config, "Bool", "enableZoomDof", DEFAULT_ENABLED)
	override_movement_speeds = _get_config_value(config, "Bool", "overrideMovementSpeeds", DEFAULT_ENABLED)
	nvg_pip_blur = _get_config_value(config, "Bool", "nvgPipBlur", DEFAULT_ENABLED)
	ammo_icons = _get_config_value(config, "Bool", "replaceAmmoCount", !DEFAULT_ENABLED)
	chamber_card_mode = _get_config_value(config, "Dropdown", "chamberCard", DEFAULT_CHAMBER_CARD)
	ammo_cards_check = _get_config_value(config, "Bool", "ammoCardsCheck", DEFAULT_ENABLED)
	ammo_cards_inspect = _get_config_value(config, "Bool", "ammoCardsInspect", DEFAULT_ENABLED)
	ammo_cards_manual_reload = _get_config_value(config, "Bool", "ammoCardsManualReload", DEFAULT_ENABLED)
	crouch_speed = _get_config_value(config, "Float", "crouchSpeed", DEFAULT_CROUCH_SPEED)
	walk_speed = _get_config_value(config, "Float", "walkSpeed", DEFAULT_WALK_SPEED)
	sprint_speed = _get_config_value(config, "Float", "sprintSpeed2", DEFAULT_SPRINT_SPEED)
	walk_aim_mult = _get_config_value(config, "Float", "aimSpeedMult", DEFAULT_AIM_SPEED_MULT)
	walk_cant_mult = _get_config_value(config, "Float", "cantSpeedMult", DEFAULT_CANT_SPEED_MULT)
	walk_scope_mult = _get_config_value(config, "Float", "scopeSpeedMult", DEFAULT_SCOPE_SPEED_MULT)
	laser_auto_on = _get_config_value(config, "Bool", "laserAutoOn", DEFAULT_ENABLED)
	attachment_cards = _get_config_value(config, "Bool", "attachmentTooltips", DEFAULT_ENABLED)
	firemode_card = _get_config_value(config, "Bool", "firemodeCard", DEFAULT_ENABLED)
	kill_counter_card = _get_config_value(config, "Bool", "killCounterCard", DEFAULT_ENABLED)
	pip_anti_aliasing = _get_config_value(config, "Bool", "pipAntiAliasing", DEFAULT_ENABLED)
	free_look = _get_config_value(config, "Bool", "enableFreeLook", DEFAULT_ENABLED)
	patrol_position = _get_config_value(config, "Bool", "patrolPosition", DEFAULT_ENABLED)
	negligent_discharge = _get_config_value(config, "Bool", "allowNegligentDischarge", DEFAULT_ENABLED)
	custom_stamina = _get_config_value(config, "Bool", "customStamina", DEFAULT_ENABLED)


static func _next_pos() -> int:
	_menu_pos_auto += 1
	return _menu_pos_auto


static func _set_config_entry(config: ConfigFile, section: String, category: String, key: String, name: String, tooltip: String, default_val, extra: Dictionary = {}) -> void:
	var value = {
		"name": name,
		"tooltip": tooltip,
		"default": default_val,
		"value": default_val,
		"menu_pos": _next_pos(),
		"category": category
	}
	value.merge(extra)
	config.set_value(section, key, value)


static func create_template(config: ConfigFile) -> void:
	config.set_value("Category", "General", { "menu_pos": 0 })
	config.set_value("Category", "Crosshair", { "menu_pos": 1 })
	config.set_value("Category", "Canted mode", { "menu_pos": 2 })
	config.set_value("Category", "Weapon Cards", { "menu_pos": 3 })
	config.set_value("Category", "Aim tweaks", { "menu_pos": 4 })
	config.set_value("Category", "Movement speeds", { "menu_pos": 5 })
	config.set_value("Category", "Stamina", { "menu_pos": 6 })

	_set_config_entry(config, "Bool", "General", "debug_enabled", "Debug", "Writing this mod's debug into stdout", !DEFAULT_ENABLED)
	_set_config_entry(config, "Bool", "General", "show_protips", "Pro-tips", "In-game tips that help with new features and bindings", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "General", "killCounterCard", "Kill counter card", "Show a tally of kills scratched into the receiver while inspecting. Resets on changing zone", DEFAULT_ENABLED)

	_set_config_entry(config, "Dropdown", "Crosshair", "crosshair", "Crosshair", "Used for exploration only", DEFAULT_CROSSHAIR, {
		"options": {
			"1off": "Off",
			"2dot": "Dot",
			"3seg-cross": "Segmented cross"
		}
	})

	_set_config_entry(config, "Color", "Crosshair", "crosshairColor", "Crosshair Color", "Crosshair Color", DEFAULT_CROSSHAIR_COLOR)

	_set_config_entry(config, "Bool", "Crosshair", "crosshairWhileRunning", "Show while running", "Keep the crosshair visible while running", !DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Crosshair", "crosshairWhileCanted", "Show while canted", "Keep the crosshair visible while in canted aim", !DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Crosshair", "crosshairWhileRaised", "Show while weapon raised", "Keep the crosshair visible while the weapon is in the high-ready position", !DEFAULT_ENABLED)

	_set_config_entry(config, "Dropdown", "Canted mode", "cantMode", "Canted Aim Mode", "Behavior of the canted aim input", DEFAULT_CANT_MODE, {
		"options": {
			"1default": "Default (follow Aim Mode)",
			"2hold": "Hold",
			"3toggle": "Toggle"
		}
	})

	_set_config_entry(config, "Bool", "Canted mode", "laserAutoOn", "Laser Auto-On", "Auto-activate the laser when entering canted aim", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Weapon Cards", "firemodeCard", "Fire mode card", "Show the current fire mode (semi/auto) over the fire selector while inspecting", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Weapon Cards", "attachmentTooltips", "Attachment cards", "Show attachment names (optic, muzzle, laser) over the weapon while inspecting", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Weapon Cards", "replaceAmmoCount", "Replace ammo counts with icons", "Show the magazine fill as bars and the chamber as a bullet icon instead of raw numbers", !DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Weapon Cards", "ammoCardsCheck", "Ammo cards on ammo check", "Show magazine and chamber cards while performing an ammo check", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Weapon Cards", "ammoCardsInspect", "Ammo cards on inspect", "Show magazine and chamber cards while inspecting the weapon", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Weapon Cards", "ammoCardsManualReload", "Ammo cards on manual reload", "Show magazine and chamber cards while manually loading rounds", DEFAULT_ENABLED)

	_set_config_entry(config, "Dropdown", "Weapon Cards", "chamberCard", "Chamber card", "When to show the chamber card alongside the ammo cards", DEFAULT_CHAMBER_CARD, {
		"options": {
			"1enabled": "Enabled",
			"2manual": "Manual guns only",
			"3disabled": "Disabled"
		}
	})

	_set_config_entry(config, "Bool", "Aim tweaks", "enableFreeLook", "Adaptive free look", "Allow camera to go into free look when weapon is idle", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "patrolPosition", "Patrol position for idle mode", "Hold the weapon in a relaxed patrol position when idle instead of the default low ready", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "allowNegligentDischarge", "Allow negligent discharge", "Allow the weapon to fire even when not raised, aiming or canted", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Stamina", "customStamina", "Stamina overhaul", "Use the mod's weight-based body and arm stamina model. Disable to fall back to vanilla stamina", DEFAULT_ENABLED)

	_set_config_entry(config, "Dropdown", "Aim tweaks", "lpvoOofZoom", "LPVO out-of-aim zoom", "Allow changing LPVO zoom level when not aiming. Rail movement: requires Rail Movement binding held as a modifier.", DEFAULT_LPVO_OOA_ZOOM, {
		"options": {
			"1enabled": "Enabled",
			"2disabled": "Disabled",
			"3rail": "Rail movement"
		}
	})

	_set_config_entry(config, "Dropdown", "Aim tweaks", "magSchema", "Magnification schema", "Which set of magnification steps variable optics use. Falls back to Short when an optic lacks the chosen schema.", DEFAULT_MAG_SCHEMA, {
		"options": {
			"1discrete": "Discrete",
			"2normalized": "Normalized",
			"3short": "Short"
		}
	})

	_set_config_entry(config, "Bool", "Aim tweaks", "nvgPipBlur", "Blur scope PIP under NVG", "Blur the magnified optic's picture-in-picture image while aiming with night vision active", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "pipAntiAliasing", "Scope PIP Anti-Aliasing", "Enable anti-aliasing on the magnified optic's picture-in-picture view", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "enableZoomDof", "Enable zoom DOF", "Apply depth-of-field blur when looking through scopes", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Movement speeds", "overrideMovementSpeeds", "Override movement speed", "Change default walk/crouch/spring speeds", DEFAULT_ENABLED)

	_set_config_entry(config, "Float", "Movement speeds", "crouchSpeed", "Crouch Speed", "Movement speed while crouching", DEFAULT_CROUCH_SPEED, {
		"minRange": SPEED_MIN,
		"maxRange": SPEED_MAX
	})

	_set_config_entry(config, "Float", "Movement speeds", "walkSpeed", "Walk Speed", "Base walking speed", DEFAULT_WALK_SPEED, {
		"minRange": SPEED_MIN,
		"maxRange": SPEED_MAX
	})

	_set_config_entry(config, "Float", "Movement speeds", "sprintSpeed2", "Sprint Speed", "Movement speed while sprinting", DEFAULT_SPRINT_SPEED, {
		"minRange": SPEED_MIN,
		"maxRange": SPEED_MAX
	})

	_set_config_entry(config, "Float", "Movement speeds", "aimSpeedMult", "Aim Speed Multiplier", "Walk-speed multiplier while aiming", DEFAULT_AIM_SPEED_MULT, {
		"minRange": MULT_MIN,
		"maxRange": MULT_MAX
	})

	_set_config_entry(config, "Float", "Movement speeds", "cantSpeedMult", "Cant Speed Multiplier", "Walk-speed multiplier while canted", DEFAULT_CANT_SPEED_MULT, {
		"minRange": MULT_MIN,
		"maxRange": MULT_MAX
	})

	_set_config_entry(config, "Float", "Movement speeds", "scopeSpeedMult", "Scope Speed Multiplier", "Walk-speed multiplier while scoped at full zoom", DEFAULT_SCOPE_SPEED_MULT, {
		"minRange": MULT_MIN,
		"maxRange": MULT_MAX
	})
