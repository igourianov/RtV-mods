extends Node

const _Handling = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Handling.gd")
const _WeaponRig = preload("res://mods/likhos-weapon-handling-fixes/Scripts/WeaponRig.gd")
const _Camera = preload("res://mods/likhos-weapon-handling-fixes/Scripts/Camera.gd")

const _FLASHLIGHT_WAV_PATH = "res://Audio/Interaction/Files/Flashlight.wav"

var _handling
var _weapon_rig
var _camera


func _ready() -> void:
	if not Engine.has_meta("RTVModLib"):
		push_error("[likho] RTVModLib meta not available")
		return
	var lib = Engine.get_meta("RTVModLib")
	var preferences = Preferences.Load()
	var flashlight_stream = load(_FLASHLIGHT_WAV_PATH)
	if flashlight_stream == null:
		push_warning("[likho] failed to load %s" % _FLASHLIGHT_WAV_PATH)

	_weapon_rig = _WeaponRig.new(lib, preferences)
	_handling = _Handling.new(lib, preferences, flashlight_stream)
	_camera = _Camera.new(lib, _weapon_rig)

	lib.hook("handling-weaponhandling", _handling.on_weapon_handling)
	lib.hook("weaponrig-ammocheck", _weapon_rig.on_ammo_check)
	lib.hook("weaponrig-ads-post", _weapon_rig.on_ads_post)
	lib.hook("camera-scopedof-post", _camera.on_scope_dof_post)
	print("[likho] hooks registered")
