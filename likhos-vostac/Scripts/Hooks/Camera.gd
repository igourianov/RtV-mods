extends RefCounted

const BLUR_SPEED := 1.0

# NVG tubes focus at distance. Near blur is full up to (distance - transition) and fades out at distance, which has to clear the longest rig at the hip.
const NVG_BLUR_AMOUNT := 0.3
const NVG_NEAR_DISTANCE := 1.2
const NVG_NEAR_TRANSITION := 1.0

var config := preload("../Config.gd").instance
var gameData := preload("res://Resources/GameData.tres")
var _lib


func _init(lib) -> void:
	_lib = lib


func on_dof(delta: float) -> void:
	_lib.skip_super()
	var cam = _lib._caller
	if !cam || !cam.attribute:
		return
	if gameData.settings || gameData.interface:
		cam.UIDOF(delta)
		return
	if gameData.NVG && config.NVG_weapon_blur:
		_nvg_dof(cam.attribute, delta)
		return
	if gameData.isScoped && gameData.isAiming && !gameData.isInspecting:
		_scope_dof(cam, delta)
		return
	cam.ResetDOF(delta)


# Near and far blur share one amount, so far blur stays off to keep the world sharp.
func _nvg_dof(attribute: CameraAttributesPractical, delta: float) -> void:
	attribute.dof_blur_far_enabled = false
	attribute.dof_blur_near_enabled = true
	attribute.dof_blur_near_distance = NVG_NEAR_DISTANCE
	attribute.dof_blur_near_transition = NVG_NEAR_TRANSITION
	attribute.dof_blur_amount = lerp(attribute.dof_blur_amount, NVG_BLUR_AMOUNT, delta * BLUR_SPEED)


func _scope_dof(cam, delta: float) -> void:
	var attribute: CameraAttributesPractical = cam.attribute
	if !config.zoom_DOF:
		attribute.dof_blur_far_enabled = false
		attribute.dof_blur_near_enabled = false
		attribute.dof_blur_amount = 0.0
		return
	if config.current_scope_mag <= 0.0:
		cam.ScopeDOF(delta)
		return
	attribute.dof_blur_far_enabled = true
	attribute.dof_blur_far_distance = 0.01
	attribute.dof_blur_far_transition = 5.0
	attribute.dof_blur_near_enabled = true
	attribute.dof_blur_near_distance = 0.04
	attribute.dof_blur_near_transition = 5.0
	var target := clamp((config.current_scope_mag - 1.0) * 0.05, 0.0, 0.50)
	attribute.dof_blur_amount = lerp(attribute.dof_blur_amount, target, delta * BLUR_SPEED)
