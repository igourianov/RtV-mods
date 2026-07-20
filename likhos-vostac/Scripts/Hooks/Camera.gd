extends RefCounted

const ModConfig := preload("../ModConfig.gd")
const BLUR_SPEED := 1.0

var _lib


func _init(lib) -> void:
	_lib = lib


func on_scope_dof(delta: float) -> void:
	_lib.skip_super()
	var cam = _lib._caller
	if !cam || !cam.attribute:
		return
	if !ModConfig.zoom_dof:
		cam.attribute.dof_blur_far_enabled = false
		cam.attribute.dof_blur_near_enabled = false
		cam.attribute.dof_blur_amount = 0.0
		return
	if ModConfig.current_scope_mag <= 0.0:
		cam._rtv_vanilla_ScopeDOF(delta)
		return
	cam.attribute.dof_blur_far_enabled = true
	cam.attribute.dof_blur_far_distance = 0.01
	cam.attribute.dof_blur_far_transition = 5.0
	cam.attribute.dof_blur_near_enabled = true
	cam.attribute.dof_blur_near_distance = 0.04
	cam.attribute.dof_blur_near_transition = 5.0
	var target := clamp((ModConfig.current_scope_mag - 2.0) * 0.03, 0.0, 0.20)
	cam.attribute.dof_blur_amount = lerp(cam.attribute.dof_blur_amount, target, delta * BLUR_SPEED)
