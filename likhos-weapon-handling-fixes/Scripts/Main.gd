extends "../Lib/Main.gd"

const Printer = preload("../Lib/Printer.gd")
const Handling = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Handling.gd")
const WeaponRig = preload("res://mods/likhos-weapon-handling-fixes/Scripts/WeaponRig.gd")
const Camera = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Camera.gd")
const Controller = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Controller.gd")
const Noise = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Noise.gd")
const Tilt = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Tilt.gd")
const HUD = preload("res://mods/likhos-weapon-handling-fixes/Scripts/HUD.gd")
const ModConfig = preload("res://mods/likhos-weapon-handling-fixes/Scripts/ModConfig.gd")
const Recoil = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Recoil.gd")
const Character = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Character.gd")
const Optic = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Optic.gd")
const Inputs = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Inputs.gd")

var _handling
var _weapon_rig
var _camera
var _controller
var _noise
var _tilt
var _hud
var _config
var _recoil
var _character
var _optic
var _inputs

func _init():
	_printer = Printer.new("[likho-vostac]")

func setup(lib):
	var preferences = Preferences.Load()
	
	_config = ModConfig.new()
	_weapon_rig = WeaponRig.new(lib, preferences, _config)
	_handling = Handling.new(lib, preferences, _config)
	_camera = Camera.new(lib, _weapon_rig, _config)
	_controller = Controller.new(lib, _weapon_rig, preferences, _config)
	_noise = Noise.new(lib, preferences, _config)
	_tilt = Tilt.new(lib, _config)
	_hud = HUD.new(lib, _config)
	_recoil = Recoil.new(lib, _config)
	_character = Character.new(lib, _config)
	_optic = Optic.new(lib, _weapon_rig, preferences, _config)
	_inputs = Inputs.new(lib, _config)

	register_hook("handling-weaponhandling", _handling.on_weapon_handling)
	register_hook("rigmanager-updaterig-post", _handling.on_rig_update_post)
	register_hook("weaponrig-ammocheck-pre", _weapon_rig.on_ammo_check_pre)
	register_hook("weaponrig-ammocheck-post", _weapon_rig.on_ammo_check_post)
	register_hook("weaponrig-ads-post", _weapon_rig.on_ads_post)
	register_hook("weaponrig-_input", _weapon_rig.on_input)
	register_hook("weaponrig-_physics_process-pre", _weapon_rig.on_physics_process_pre)
	register_hook("weaponrig-_ready-post", _weapon_rig.on_ready_post)
	register_hook("camera-scopedof-post", _camera.on_scope_dof_post)
	register_hook("controller-movementstates-pre", _controller.on_movement_states_pre)
	register_hook("controller-movementstates-post", _controller.on_movement_states_post)
	register_hook("noise-_physics_process-post", _noise.on_physics_process_post)
	register_hook("tilt-_physics_process-pre", _tilt.on_physics_process_pre)
	register_hook("hud-_ready-post", _hud.on_ready_post)
	register_hook("recoil-applyrecoil-post", _recoil.on_apply_recoil_post)
	register_hook("character-stamina", _character.on_stamina)
	register_hook("optic-_physics_process-pre", _optic.on_physics_process_pre)
	register_hook("inputs-createactions-post", _inputs.on_create_actions_post)
	register_hook("inputs-resetactions-post", _inputs.on_reset_actions_post)

