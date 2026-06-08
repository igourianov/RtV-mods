extends RefCounted

const KICK_Z_MULTIPLIER := 0.2

var _lib


func _init(lib) -> void:
	_lib = lib


func on_apply_recoil_post() -> void:
	var recoil = _lib._caller
	var rig = recoil.owner if recoil else null
	if rig && rig.gameData.isAiming && rig.gameData.isScoped:
		recoil.currentKick.z *= KICK_Z_MULTIPLIER
