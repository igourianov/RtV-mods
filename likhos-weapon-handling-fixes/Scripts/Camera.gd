extends RefCounted

var _lib
var _weapon_rig


func _init(lib, weapon_rig) -> void:
	_lib = lib
	_weapon_rig = weapon_rig


func on_scope_dof_post(_delta: float) -> void:
	if _weapon_rig.current_scope_mag <= 0.0:
		return
	var cam = _lib._caller
	if cam == null || cam.attribute == null:
		return
	cam.attribute.dof_blur_near_enabled = true
	cam.attribute.dof_blur_near_distance = 0.04
	cam.attribute.dof_blur_near_transition = 5.0
	cam.attribute.dof_blur_amount = clamp((_weapon_rig.current_scope_mag - 2.0) * 0.010, 0.0, 0.20)
