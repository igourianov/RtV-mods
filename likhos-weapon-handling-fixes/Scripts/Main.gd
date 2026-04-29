extends Node

const _Handling = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Handling.gd")
const _WeaponRig = preload("res://mods/likhos-weapon-handling-fixes/Scripts/WeaponRig.gd")
const _Camera = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Camera.gd")
const _Controller = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Controller.gd")
const _Noise = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Noise.gd")
const _Tilt = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Tilt.gd")
const _HUD = preload("res://mods/likhos-weapon-handling-fixes/Scripts/HUD.gd")
const _ModConfig = preload("res://mods/likhos-weapon-handling-fixes/Scripts/ModConfig.gd")
const _Recoil = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Recoil.gd")
const _Character = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Character.gd")

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

func _ready() -> void:
	_config = _ModConfig.new()
	var lib = Engine.get_meta("RTVModLib")
	if lib == null:
		push_error("[likho] RTVModLib meta not available")
		return
	if lib._is_ready:
		_init_hooks(lib)
	else:
		lib.frameworks_ready.connect(func():
			_init_hooks(lib)
		)

func _init_hooks(lib):
	var preferences = Preferences.Load()

	_weapon_rig = _WeaponRig.new(lib, preferences)
	_handling = _Handling.new(lib, preferences, _config)
	_camera = _Camera.new(lib, _weapon_rig)
	_controller = _Controller.new(lib, _weapon_rig, preferences, _config)
	_noise = _Noise.new(lib, preferences)
	_tilt = _Tilt.new(lib)
	_hud = _HUD.new(lib, _config)
	_recoil = _Recoil.new(lib)
	_character = _Character.new(lib)

	var hooks: Array[int] = [
		_register_hook(lib, "handling-weaponhandling", _handling.on_weapon_handling),
		_register_hook(lib, "weaponrig-ammocheck-pre", _weapon_rig.on_ammo_check_pre),
		_register_hook(lib, "weaponrig-ammocheck-post", _weapon_rig.on_ammo_check_post),
		_register_hook(lib, "weaponrig-ads-post", _weapon_rig.on_ads_post),
		_register_hook(lib, "weaponrig-_input", _weapon_rig.on_input),
		_register_hook(lib, "weaponrig-_physics_process-pre", _weapon_rig.on_physics_process_pre),
		_register_hook(lib, "camera-scopedof-post", _camera.on_scope_dof_post),
		_register_hook(lib, "controller-movementstates-pre", _controller.on_movement_states_pre),
		_register_hook(lib, "controller-movementstates-post", _controller.on_movement_states_post),
		_register_hook(lib, "noise-_physics_process-post", _noise.on_physics_process_post),
		_register_hook(lib, "tilt-_physics_process-pre", _tilt.on_physics_process_pre),
		_register_hook(lib, "hud-_ready-post", _hud.on_ready_post),
		_register_hook(lib, "hud-_physics_process-post", _hud.on_physics_process_post),
		_register_hook(lib, "recoil-applyrecoil-post", _recoil.on_apply_recoil_post),
		_register_hook(lib, "character-stamina", _character.on_stamina)
	]

	var registered = hooks.filter(func(id): return id > -1)
	if registered.size() == hooks.size():
		print("[likho] all hooks registered successfully")
		return

	print("[likho] mod registration failed, rolling back")
	for id in registered:
		lib.unhook(id)


func _register_hook(lib, hookName: String, callback: Callable):
	var id = lib.hook(hookName, callback)
	if id != -1:
		print("[likho] hook(%s):%s registered" % [hookName, id])
	else:
		push_error("[likho] hook(%s) failed" % hookName)
	return id
	
