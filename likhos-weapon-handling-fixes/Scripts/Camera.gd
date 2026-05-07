extends RefCounted

const ModConfig = preload("./ModConfig.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_scope_dof_post(_delta: float) -> void:
	var cam = _lib._caller
	if cam == null || cam.attribute == null:
		return
	if ModConfig.disable_zoom_dof:
		cam.attribute.dof_blur_far_enabled = false
		cam.attribute.dof_blur_near_enabled = false
		cam.attribute.dof_blur_amount = 0.0
		return
	if ModConfig.current_scope_mag <= 0.0:
		return
	cam.attribute.dof_blur_near_enabled = true
	cam.attribute.dof_blur_near_distance = 0.04
	cam.attribute.dof_blur_near_transition = 5.0
	cam.attribute.dof_blur_amount = clamp((ModConfig.current_scope_mag - 2.0) * 0.03, 0.0, 0.20)
