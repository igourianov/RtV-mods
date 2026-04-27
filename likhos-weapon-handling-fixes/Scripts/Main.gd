extends Node

const _Handling = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Handling.gd")
const _WeaponRig = preload("res://mods/likhos-weapon-handling-fixes/Scripts/WeaponRig.gd")
const _Camera = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Camera.gd")

var _handling
var _weapon_rig
var _camera

func _ready() -> void:
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
	_handling = _Handling.new(lib, preferences)
	_camera = _Camera.new(lib, _weapon_rig)

	var hooks: Array[int] = [
		_register_hook(lib, "handling-weaponhandling", _handling.on_weapon_handling),
		_register_hook(lib, "weaponrig-ammocheck", _weapon_rig.on_ammo_check),
		_register_hook(lib, "weaponrig-ads-post", _weapon_rig.on_ads_post),
		_register_hook(lib, "camera-scopedof-post", _camera.on_scope_dof_post)
	]

	var registered = hooks.filter(func(id): return id > -1)
	if registered.size() == hooks.size():
		print("[likho] all hooks registered")
		return

	print("[likho] mod registration failed, rolling back")
	for id in registered:
		lib.unhook(id)


func _register_hook(lib, name: String, callback: Callable):
	var id = lib.hook(name, callback)
	if id != -1:
		print("[likho] hook(%s):%s registered" % [name, id])
	else:
		push_error("[likho] hook(%s) failed" % name)
	return id
	