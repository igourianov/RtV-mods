extends RefCounted

var _lib
var _weapon_rig
var _config


func _init(lib, weapon_rig, config) -> void:
	_lib = lib
	_weapon_rig = weapon_rig
	_config = config


func on_scope_dof_post(_delta: float) -> void:
	var cam = _lib._caller
	if cam == null || cam.attribute == null:
		return
	if _config.disable_zoom_dof:
		cam.attribute.dof_blur_far_enabled = false
		cam.attribute.dof_blur_near_enabled = false
		cam.attribute.dof_blur_amount = 0.0
		return
	if _weapon_rig.current_scope_mag <= 0.0:
		return
	cam.attribute.dof_blur_near_enabled = true
	cam.attribute.dof_blur_near_distance = 0.04
	cam.attribute.dof_blur_near_transition = 5.0
	cam.attribute.dof_blur_amount = clamp((_weapon_rig.current_scope_mag - 2.0) * 0.03, 0.0, 0.20)
