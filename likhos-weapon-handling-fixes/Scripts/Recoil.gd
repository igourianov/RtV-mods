extends RefCounted

const KICK_Z_MULTIPLIER := 0.2

var _lib
var _config


func _init(lib, config) -> void:
	_lib = lib
	_config = config


func on_apply_recoil_post() -> void:
	var recoil = _lib._caller
	var rig = recoil.owner
	if !recoil || !rig:
		return
	if rig.gameData.isScoped:
		recoil.currentKick.z *= KICK_Z_MULTIPLIER
