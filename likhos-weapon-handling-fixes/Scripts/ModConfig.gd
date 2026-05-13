
# dynamic state vars
static var current_scope_mag: float = 1.0
static var current_weapon_weight: float = 0.0
static var laser_latch: bool = false
static var ammo_check_view := false

# config vars
static var crosshair_style: String
static var crosshair_color: Color
static var cant_mode: String
static var lpvo_ooa_zoom: bool
static var disable_zoom_dof: bool
static var disable_optic_override: bool
static var disable_canted_override: bool
static var disable_lowered_override: bool
static var override_movement_speeds: bool
static var nvg_pip_blur: bool
static var ammo_tooltips: bool
static var crouch_speed: float
static var walk_speed: float
static var sprint_speed: float
static var walk_aim_mult: float
static var walk_cant_mult: float
static var walk_scope_mult: float
static var laser_auto_on: bool
static var attachment_tooltips: bool
static var pip_anti_aliasing: bool
static var eye_relief_offset: float

static var _menu_pos_auto: int = 0

const DEFAULT_CROSSHAIR_COLOR = Color(0, 1, 0.04, 0.55)
const DEFAULT_CROSSHAIR = "3seg-cross"
const DEFAULT_CANT_MODE = "1default"
const DEFAULT_LPVO_OOF_ZOOM = "1enabled"
const DEFAULT_ENABLED = true
const DEFAULT_CROUCH_SPEED = 0.7
const DEFAULT_WALK_SPEED = 3.0
const DEFAULT_SPRINT_SPEED = 7.0
const DEFAULT_AIM_SPEED_MULT = 0.6
const DEFAULT_CANT_SPEED_MULT = 0.75
const DEFAULT_SCOPE_SPEED_MULT = 0.3
const SPEED_MIN = 0.0
const SPEED_MAX = 20.0
const MULT_MIN = 0.1
const MULT_MAX = 1.5
const DEFAULT_EYE_RELIEF_OFFSET = 0.0
const BASE_WEAPON_WEIGHT: float = 4.0


static func _get_config_value(config: ConfigFile, section: String, key: String, default_val):
	var value = config.get_value(section, key, {}).get("value", default_val)
	if section == "Dropdown":
		value = value.substr(1)
	return value

static func apply_config(config: ConfigFile):
	crosshair_style = _get_config_value(config, "Dropdown", "crosshair", DEFAULT_CROSSHAIR)
	crosshair_color = _get_config_value(config, "Color", "crosshairColor", DEFAULT_CROSSHAIR_COLOR)
	cant_mode = _get_config_value(config, "Dropdown", "cantMode", DEFAULT_CANT_MODE)
	lpvo_ooa_zoom = _get_config_value(config, "Bool", "lpvoOofZoom2", DEFAULT_ENABLED)
	disable_zoom_dof = !_get_config_value(config, "Bool", "enableZoomDof", DEFAULT_ENABLED)
	disable_optic_override = !_get_config_value(config, "Bool", "enableOpticOverride", DEFAULT_ENABLED)
	disable_canted_override = !_get_config_value(config, "Bool", "enableCantedOverride", DEFAULT_ENABLED)
	disable_lowered_override = !_get_config_value(config, "Bool", "enableLoweredOverride", DEFAULT_ENABLED)
	override_movement_speeds = _get_config_value(config, "Bool", "overrideMovementSpeeds", DEFAULT_ENABLED)
	nvg_pip_blur = _get_config_value(config, "Bool", "nvgPipBlur", DEFAULT_ENABLED)
	ammo_tooltips = _get_config_value(config, "Bool", "ammoTooltips", DEFAULT_ENABLED)
	crouch_speed = _get_config_value(config, "Float", "crouchSpeed", DEFAULT_CROUCH_SPEED)
	walk_speed = _get_config_value(config, "Float", "walkSpeed", DEFAULT_WALK_SPEED)
	sprint_speed = _get_config_value(config, "Float", "sprintSpeed2", DEFAULT_SPRINT_SPEED)
	walk_aim_mult = _get_config_value(config, "Float", "aimSpeedMult", DEFAULT_AIM_SPEED_MULT)
	walk_cant_mult = _get_config_value(config, "Float", "cantSpeedMult", DEFAULT_CANT_SPEED_MULT)
	walk_scope_mult = _get_config_value(config, "Float", "scopeSpeedMult", DEFAULT_SCOPE_SPEED_MULT)
	laser_auto_on = _get_config_value(config, "Bool", "laserAutoOn", DEFAULT_ENABLED)
	attachment_tooltips = _get_config_value(config, "Bool", "attachmentTooltips", DEFAULT_ENABLED)
	pip_anti_aliasing = _get_config_value(config, "Bool", "pipAntiAliasing", DEFAULT_ENABLED)
	eye_relief_offset = _get_config_value(config, "Float", "eyeReliefOffset", DEFAULT_EYE_RELIEF_OFFSET) / 100.0


static func _next_pos():
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


static func create_template(config: ConfigFile):
	config.set_value("Category", "Crosshair", { "menu_pos": 1 })
	config.set_value("Category", "Canted mode", { "menu_pos": 2 })
	config.set_value("Category", "Inspect", { "menu_pos": 3 })
	config.set_value("Category", "Aim tweaks", { "menu_pos": 4 })
	config.set_value("Category", "Movement speeds", { "menu_pos": 5 })

	_set_config_entry(config, "Dropdown", "Crosshair", "crosshair", "Crosshair", "Used for exploration only", DEFAULT_CROSSHAIR, {
		"options": {
			"1off": "Off",
			"2dot": "Dot",
			"3seg-cross": "Segmented cross"
		}
	})

	_set_config_entry(config, "Color", "Crosshair", "crosshairColor", "Crosshair Color", "Crosshair Color", DEFAULT_CROSSHAIR_COLOR)

	_set_config_entry(config, "Dropdown", "Canted mode", "cantMode", "Canted Aim Mode", "Behavior of the canted aim input", DEFAULT_CANT_MODE, {
		"options": {
			"1default": "Default (follow Aim Mode)",
			"2hold": "Hold",
			"3toggle": "Toggle"
		}
	})

	_set_config_entry(config, "Bool", "Canted mode", "laserAutoOn", "Laser Auto-On", "Auto-activate the laser when entering canted aim", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Inspect", "ammoTooltips", "Show ammo cards", "Show magazine and chamber overlays while inspecting the weapon", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Inspect", "attachmentTooltips", "Show attachment cards", "Show attachment names (optic, muzzle, laser) over the weapon while inspecting", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "lpvoOofZoom2", "LPVO out-of-aim zoom", "Allow changing LPVO zoom level when not aiming.", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "nvgPipBlur", "Blur scope PIP under NVG", "Blur the magnified optic's picture-in-picture image while aiming with night vision active", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "pipAntiAliasing", "Scope PIP Anti-Aliasing", "Enable anti-aliasing on the magnified optic's picture-in-picture view", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "enableZoomDof", "Enable zoom DOF", "Apply depth-of-field blur when looking through scopes", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "enableOpticOverride", "Override optic position", "Apply the mod's eye-relief and Y-offset adjustments when scoped. Disable to use vanilla aim position.", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "enableCantedOverride", "Override canted position", "Apply the mod's Y offset and roll tweak when canted. Disable to use vanilla canted position and rotation.", DEFAULT_ENABLED)

	_set_config_entry(config, "Bool", "Aim tweaks", "enableLoweredOverride", "Override lowered position", "Apply the mod's patrol-mode replacement. Disable to use vanilla low position and rotation.", DEFAULT_ENABLED)

	_set_config_entry(config, "Float", "Aim tweaks", "eyeReliefOffset", "Eye relief offset for magnified optics (cm)", "Adjust how close the scope is during zoom", DEFAULT_EYE_RELIEF_OFFSET, {
		"minRange": 0.0,
		"maxRange": 5.0
	})

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

