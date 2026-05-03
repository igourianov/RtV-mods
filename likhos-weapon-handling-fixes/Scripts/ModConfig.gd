extends RefCounted

var McmHelpers = preload("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

const PREFIX = "[likho-vostac]"

var crosshair_style: String
var crosshair_color: Color
var cant_mode: String
var lpvo_oof_zoom: String
var disable_zoom_dof: bool
var disable_optic_override: bool
var disable_canted_override: bool
var disable_lowered_override: bool
var nvg_pip_blur: bool
var ammo_tooltips: bool
var crouch_speed: float
var walk_speed: float
var sprint_speed: float
var aim_speed_mult: float
var cant_speed_mult: float
var scope_speed_mult: float
var laser_auto_on: bool
var attachment_tooltips: bool
var pip_anti_aliasing: bool
var override_handling_speed: bool
var handling_speed_weight_factor: float
var eye_relief_offset: float

const MOD_ID = "likhos-weapon-handling-fixes"
const FILE_PATH = "user://MCM/likhos-weapon-handling-fixes"
const FILE_NAME = "config.ini"
const DEFAULT_CROSSHAIR_COLOR = Color(1.0, 0.4, 0.0, 0.65)
const DEFAULT_CROSSHAIR = "2dot"
const DEFAULT_CANT_MODE = "1default"
const DEFAULT_LPVO_OOF_ZOOM = "1enabled"
const DEFAULT_ENABLED = true
const DEFAULT_CROUCH_SPEED = 0.7
const DEFAULT_WALK_SPEED = 3.0
const DEFAULT_SPRINT_SPEED = 6.0
const DEFAULT_AIM_SPEED_MULT = 0.6
const DEFAULT_CANT_SPEED_MULT = 0.75
const DEFAULT_SCOPE_SPEED_MULT = 0.3
const DEFAULT_HANDLING_SPEED_WEIGHT_FACTOR = 0.5
const SPEED_MIN = 0.0
const SPEED_MAX = 20.0
const MULT_MIN = 0.1
const MULT_MAX = 1.5
const HANDLING_WEIGHT_FACTOR_MIN = 0.0
const HANDLING_WEIGHT_FACTOR_MAX = 1.5
const DEFAULT_EYE_RELIEF_OFFSET = 0.0


func _init():
	var config = _create_config_template()

	var fullPath = FILE_PATH + "/" + FILE_NAME
	if !FileAccess.file_exists(fullPath):
		DirAccess.open("user://").make_dir(FILE_PATH)
		config.save(fullPath)
	else:
		McmHelpers.CheckConfigurationHasUpdated(MOD_ID, config, fullPath)
		config.load(fullPath)

	_apply_config(config)

	McmHelpers.RegisterConfiguration(
		MOD_ID,
		"Likho's VosTac",
		FILE_PATH,
		"Likho's collection of game fixes and realism improvements",
		{
			FILE_NAME: _apply_config
		}
	)

func _apply_config(config: ConfigFile):
	crosshair_style = config.get_value("Dropdown", "crosshair", {}).get("value", DEFAULT_CROSSHAIR).substr(1)
	crosshair_color = config.get_value("Color", "crosshairColor", {}).get("value", DEFAULT_CROSSHAIR_COLOR)
	cant_mode = config.get_value("Dropdown", "cantMode", {}).get("value", DEFAULT_CANT_MODE).substr(1)
	lpvo_oof_zoom = config.get_value("Dropdown", "lpvoOofZoom", {}).get("value", DEFAULT_LPVO_OOF_ZOOM).substr(1)
	disable_zoom_dof = !config.get_value("Bool", "enableZoomDof", {}).get("value", DEFAULT_ENABLED)
	disable_optic_override = !config.get_value("Bool", "enableOpticOverride", {}).get("value", DEFAULT_ENABLED)
	disable_canted_override = !config.get_value("Bool", "enableCantedOverride", {}).get("value", DEFAULT_ENABLED)
	disable_lowered_override = !config.get_value("Bool", "enableLoweredOverride", {}).get("value", DEFAULT_ENABLED)
	nvg_pip_blur = config.get_value("Bool", "nvgPipBlur", {}).get("value", DEFAULT_ENABLED)
	ammo_tooltips = config.get_value("Bool", "ammoTooltips", {}).get("value", DEFAULT_ENABLED)
	crouch_speed = config.get_value("Float", "crouchSpeed", {}).get("value", DEFAULT_CROUCH_SPEED)
	walk_speed = config.get_value("Float", "walkSpeed", {}).get("value", DEFAULT_WALK_SPEED)
	sprint_speed = config.get_value("Float", "sprintSpeed", {}).get("value", DEFAULT_SPRINT_SPEED)
	aim_speed_mult = config.get_value("Float", "aimSpeedMult", {}).get("value", DEFAULT_AIM_SPEED_MULT)
	cant_speed_mult = config.get_value("Float", "cantSpeedMult", {}).get("value", DEFAULT_CANT_SPEED_MULT)
	scope_speed_mult = config.get_value("Float", "scopeSpeedMult", {}).get("value", DEFAULT_SCOPE_SPEED_MULT)
	laser_auto_on = config.get_value("Bool", "laserAutoOn", {}).get("value", DEFAULT_ENABLED)
	attachment_tooltips = config.get_value("Bool", "attachmentTooltips", {}).get("value", DEFAULT_ENABLED)
	pip_anti_aliasing = config.get_value("Bool", "pipAntiAliasing", {}).get("value", DEFAULT_ENABLED)
	override_handling_speed = config.get_value("Bool", "overrideHandlingSpeed", {}).get("value", DEFAULT_ENABLED)
	handling_speed_weight_factor = config.get_value("Float", "handlingSpeedWeightFactor", {}).get("value", DEFAULT_HANDLING_SPEED_WEIGHT_FACTOR)
	eye_relief_offset = config.get_value("Float", "eyeReliefOffset", {}).get("value", DEFAULT_EYE_RELIEF_OFFSET) / 100.0

func _create_config_template():
	var config := ConfigFile.new()
	var pos = [0]
	var next_pos = func(): pos[0] += 1; return pos[0]

	config.set_value("Category", "Crosshair", { "menu_pos": 1 })
	config.set_value("Category", "Canted mode", { "menu_pos": 2 })
	config.set_value("Category", "Inspect", { "menu_pos": 3 })
	config.set_value("Category", "Aim tweaks", { "menu_pos": 4 })
	config.set_value("Category", "Movement speeds", { "menu_pos": 5 })

	config.set_value("Dropdown", "crosshair", {
		"name": "Crosshair",
		"tooltip": "Used for exploration only",
		"default": DEFAULT_CROSSHAIR,
		"value": DEFAULT_CROSSHAIR,
		"options": {
			"1off": "Off",
			"2dot": "Dot",
			"3seg-cross": "Segmented cross"
		},
		"menu_pos": next_pos.call(),
		"category": "Crosshair"
	})

	config.set_value("Color", "crosshairColor", {
		"name": "Crosshair Color",
		"tooltip": "Crosshair Color",
		"default": DEFAULT_CROSSHAIR_COLOR,
		"value": DEFAULT_CROSSHAIR_COLOR,
		"menu_pos": next_pos.call(),
		"category": "Crosshair"
	})

	config.set_value("Dropdown", "cantMode", {
		"name": "Canted Aim Mode",
		"tooltip": "Behavior of the canted aim input",
		"default": DEFAULT_CANT_MODE,
		"value": DEFAULT_CANT_MODE,
		"options": {
			"1default": "Default (follow Aim Mode)",
			"2hold": "Hold",
			"3toggle": "Toggle"
		},
		"menu_pos": next_pos.call(),
		"category": "Canted mode"
	})

	config.set_value("Bool", "laserAutoOn", {
		"name": "Laser Auto-On",
		"tooltip": "Auto-activate the laser when entering canted aim in hold mode",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Canted mode"
	})

	config.set_value("Bool", "ammoTooltips", {
		"name": "Show ammo cards",
		"tooltip": "Show magazine and chamber overlays while inspecting the weapon",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Inspect"
	})

	config.set_value("Bool", "attachmentTooltips", {
		"name": "Show attachment cards",
		"tooltip": "Show attachment names (optic, muzzle, laser) over the weapon while inspecting",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Inspect"
	})

	config.set_value("Dropdown", "lpvoOofZoom", {
		"name": "LPVO out-of-aim zoom",
		"tooltip": "Allow changing LPVO zoom level when not aiming. Rail movement: require Rail Movement binding held as a modifier.",
		"default": DEFAULT_LPVO_OOF_ZOOM,
		"value": DEFAULT_LPVO_OOF_ZOOM,
		"options": {
			"1enabled": "Enabled",
			"2disabled": "Disabled",
			"3rail": "Rail movement"
		},
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Bool", "nvgPipBlur", {
		"name": "Blur scope PIP under NVG",
		"tooltip": "Blur the magnified optic's picture-in-picture image while aiming with night vision active",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Bool", "pipAntiAliasing", {
		"name": "Scope PIP Anti-Aliasing",
		"tooltip": "Enable anti-aliasing on the magnified optic's picture-in-picture view",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Bool", "enableZoomDof", {
		"name": "Enable zoom DOF",
		"tooltip": "Apply depth-of-field blur when looking through scopes",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Bool", "enableOpticOverride", {
		"name": "Override optic position",
		"tooltip": "Apply the mod's eye-relief and Y-offset adjustments when scoped. Disable to use vanilla aim position.",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Bool", "enableCantedOverride", {
		"name": "Override canted position",
		"tooltip": "Apply the mod's Y offset and roll tweak when canted. Disable to use vanilla canted position and rotation.",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Bool", "enableLoweredOverride", {
		"name": "Override lowered position",
		"tooltip": "Apply the mod's patrol-mode replacement. Disable to use vanilla low position and rotation.",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Bool", "overrideHandlingSpeed", {
		"name": "Override handling speed",
		"tooltip": "Apply the mod's handling speed math (mode-specific multiplier and weapon weight scaling). Disable to use vanilla handling speed.",
		"default": DEFAULT_ENABLED,
		"value": DEFAULT_ENABLED,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Float", "handlingSpeedWeightFactor", {
		"name": "Handling speed weight factor",
		"tooltip": "How strongly total weapon weight (base + attachments) slows handling. 0 = no influence, 1 = full influence.",
		"default": DEFAULT_HANDLING_SPEED_WEIGHT_FACTOR,
		"value": DEFAULT_HANDLING_SPEED_WEIGHT_FACTOR,
		"minRange": HANDLING_WEIGHT_FACTOR_MIN,
		"maxRange": HANDLING_WEIGHT_FACTOR_MAX,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Float", "eyeReliefOffset", {
		"name": "Eye relief offset for magnified optics (cm)",
		"tooltip": "Adjust how close the scope is during zoom",
		"default": DEFAULT_EYE_RELIEF_OFFSET,
		"value": DEFAULT_EYE_RELIEF_OFFSET,
		"minRange": 0.0,
		"maxRange": 5.0,
		"menu_pos": next_pos.call(),
		"category": "Aim tweaks"
	})

	config.set_value("Float", "crouchSpeed", {
		"name": "Crouch Speed",
		"tooltip": "Movement speed while crouching",
		"default": DEFAULT_CROUCH_SPEED,
		"value": DEFAULT_CROUCH_SPEED,
		"minRange": SPEED_MIN,
		"maxRange": SPEED_MAX,
		"menu_pos": next_pos.call(),
		"category": "Movement speeds"
	})

	config.set_value("Float", "walkSpeed", {
		"name": "Walk Speed",
		"tooltip": "Base walking speed",
		"default": DEFAULT_WALK_SPEED,
		"value": DEFAULT_WALK_SPEED,
		"minRange": SPEED_MIN,
		"maxRange": SPEED_MAX,
		"menu_pos": next_pos.call(),
		"category": "Movement speeds"
	})

	config.set_value("Float", "sprintSpeed", {
		"name": "Sprint Speed",
		"tooltip": "Movement speed while sprinting",
		"default": DEFAULT_SPRINT_SPEED,
		"value": DEFAULT_SPRINT_SPEED,
		"minRange": SPEED_MIN,
		"maxRange": SPEED_MAX,
		"menu_pos": next_pos.call(),
		"category": "Movement speeds"
	})

	config.set_value("Float", "aimSpeedMult", {
		"name": "Aim Speed Multiplier",
		"tooltip": "Walk-speed multiplier while aiming",
		"default": DEFAULT_AIM_SPEED_MULT,
		"value": DEFAULT_AIM_SPEED_MULT,
		"minRange": MULT_MIN,
		"maxRange": MULT_MAX,
		"menu_pos": next_pos.call(),
		"category": "Movement speeds"
	})

	config.set_value("Float", "cantSpeedMult", {
		"name": "Cant Speed Multiplier",
		"tooltip": "Walk-speed multiplier while canted",
		"default": DEFAULT_CANT_SPEED_MULT,
		"value": DEFAULT_CANT_SPEED_MULT,
		"minRange": MULT_MIN,
		"maxRange": MULT_MAX,
		"menu_pos": next_pos.call(),
		"category": "Movement speeds"
	})

	config.set_value("Float", "scopeSpeedMult", {
		"name": "Scope Speed Multiplier",
		"tooltip": "Walk-speed multiplier while scoped at full zoom",
		"default": DEFAULT_SCOPE_SPEED_MULT,
		"value": DEFAULT_SCOPE_SPEED_MULT,
		"minRange": MULT_MIN,
		"maxRange": MULT_MAX,
		"menu_pos": next_pos.call(),
		"category": "Movement speeds"
	})

	return config

