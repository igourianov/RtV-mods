extends Node

var _lib


func _ready() -> void:
	if not Engine.has_meta("RTVModLib"):
		push_error("[ammo-check-fix] RTVModLib meta not available")
		return
	_lib = Engine.get_meta("RTVModLib")
	_lib.hook("weaponrig-ammocheck", _on_replace)
	print("[ammo-check-fix] hook registered for weaponrig-ammocheck")


func _on_replace() -> void:
	var rig = _lib._caller
	if rig == null:
		return

	if rig.gameData.isChecking:
		_lib.skip_super()
		return

	_wrap_vanilla(rig)
	_lib.skip_super()


func _wrap_vanilla(rig) -> void:
	var prev_position = rig.gameData.weaponPosition
	print("[ammo-check-fix] wrap_vanilla pre, prev=", prev_position)
	await rig._rtv_vanilla_AmmoCheck()
	print("[ammo-check-fix] wrap_vanilla post, restoring=", prev_position)
	rig.gameData.weaponPosition = prev_position
