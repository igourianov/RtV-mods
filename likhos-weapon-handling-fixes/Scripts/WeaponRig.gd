extends RefCounted

const _FIXED_SCOPE_AIM_OFFSET = 0.015
const _VARIABLE_SCOPE_AIM_OFFSET = 0.03
const ModConfig = preload("./ModConfig.gd")
const Out = preload("../Lib/Out.gd")

var _lib
var _preferences: Preferences
var _ammo_check_saved_position: int = 0
var _last_optic_for_scale = null
var _cached_lens_scale: float = 1.0


func _init(lib, preferences: Preferences) -> void:
	_lib = lib
	_preferences = preferences


func on_input(event) -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	var gd = rig.gameData
	var optic = rig.activeOptic
	var zoomIn = Input.is_action_pressed("optic_zoom_in")
	var zoomOut = Input.is_action_pressed("optic_zoom_out")

	if (gd.freeze
		|| gd.isPlacing
		|| gd.isReloading
		|| gd.isInserting
		|| gd.isChecking
		|| gd.isCaching
		|| gd.isTransitioning
		|| gd.isFiring):
		return

	if event.is_action_pressed("inspect"):
		gd.isInspecting = !gd.isInspecting
		gd.isFiring = false

		if gd.isInspecting:
			gd.inspectPosition = 1
			rig.PlayInspectStart()
			rig.animator["parameters/conditions/Inspect_Front"] = true
			rig.animator["parameters/conditions/Inspect_Idle"] = false
			rig.UpdateBullets()
			rig.UpdateHUD()
		else:
			if gd.inspectPosition == 1:
				rig.PlayInspectEnd()
				rig.animator["parameters/conditions/Inspect_Front"] = false
				rig.animator["parameters/conditions/Inspect_Idle"] = true
			elif gd.inspectPosition == 2:
				rig.PlayInspectEnd()
				rig.animator["parameters/conditions/Inspect_Back"] = false
				rig.animator["parameters/conditions/Inspect_Idle"] = true
				gd.inspectPosition = 1
		return

	if gd.isInspecting:
		if event.is_action_pressed("canted"):
			if gd.inspectPosition == 1:
				rig.PlayInspectRotate()
				rig.animator["parameters/conditions/Inspect_Front"] = false
				rig.animator["parameters/conditions/Inspect_Back"] = true
				gd.inspectPosition = 2
			elif gd.inspectPosition == 2:
				rig.PlayInspectRotate()
				rig.animator["parameters/conditions/Inspect_Front"] = true
				rig.animator["parameters/conditions/Inspect_Back"] = false
				gd.inspectPosition = 1

		if (zoomIn || zoomOut) && optic && optic.railMovement:
			if zoomIn && optic.position.z < optic.maxPosition:
				optic.position.z += 0.01
				rig.slotData.position += 0.01
				rig.PlayRailMove()
			elif zoomOut && optic.position.z > optic.minPosition:
				optic.position.z -= 0.01
				rig.slotData.position -= 0.01
				rig.PlayRailMove()
		return

	if event.is_action_pressed("secondary_optic"):
		if optic && optic.secondary && optic.attachmentData.secondary:
			gd.secondaryOptic = !gd.secondaryOptic
			rig.UpdateAimOffset()

	var zoomAllowed = (gd.isAiming
		|| ModConfig.lpvo_oof_zoom == "enabled"
		|| (ModConfig.lpvo_oof_zoom == "rail" && Input.is_action_pressed("rail_movement")))

	if zoomAllowed && (zoomIn || zoomOut) && optic && optic.attachmentData.variable:
		var slotData = rig.slotData
		if zoomIn && slotData.zoom != 3:
			slotData.zoom += 1
			rig.PlayRailMove()
		elif zoomOut && slotData.zoom != 1:
			slotData.zoom -= 1
			rig.PlayRailMove()


func on_physics_process_pre(_delta: float) -> void:
	var rig = _lib._caller
	if rig == null:
		return
	if rig.gameData.isInspecting:
		_lib.skip_super()


func on_ammo_check_pre() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_ammo_check_saved_position = rig.gameData.weaponPosition


func on_ammo_check_post() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	rig.gameData.weaponPosition = _ammo_check_saved_position


func on_ready_post() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	# Vanilla M4A1_Rig.tscn sets backSightIndex but never sets frontSightIndex,
	# leaving it at the export default 0. With foldSights = true, UpdateAimOffset
	# writes a fold rotation to bone 0 (M4A1_Body, the root) every call, which
	# the AnimationTree reverts on the next physics tick — visible as a flicker.
	# Alias frontSightIndex to backSightIndex so the redundant write is harmless.
	if rig.data != null && rig.data.foldSights && rig.backSightIndex > 0 && rig.frontSightIndex == 0:
		rig.frontSightIndex = rig.backSightIndex


func on_ads_post(delta: float) -> void:
	var rig = _lib._caller
	var gd = rig.gameData
	var optic = rig.activeOptic
	var att = optic.attachmentData

	ModConfig.current_scope_mag = 1.0
	if rig.slotData.zoom == 1:
		gd.isScoped = gd.PIP # override vanilla behavior
		ModConfig.current_scope_mag = 1.1
	elif rig.slotData.zoom == 2:
		ModConfig.current_scope_mag = 3.0
	elif rig.slotData.zoom == 3:
		ModConfig.current_scope_mag = 6.0

	if !gd.PIP || !gd.isAiming || gd.isColliding || optic == null:
		return

	var lens_scale: float
	if optic == _last_optic_for_scale:
		lens_scale = _cached_lens_scale
	else:
		lens_scale = optic.transform.basis.get_scale().y
		_cached_lens_scale = lens_scale
		_last_optic_for_scale = optic

	if !att.variable && (!att.scope || gd.secondaryOptic):
		return

	gd.aimFOV = gd.baseFOV # override vanilla behavior

	if att.scope && !gd.secondaryOptic:
		ModConfig.current_scope_mag = 4.0
		var distance = distance_factor(_FIXED_SCOPE_AIM_OFFSET, ModConfig.eye_relief_offset)
		optic.camera.fov = distance * gd.baseFOV * lens_scale / ModConfig.current_scope_mag
		return

	var distance = distance_factor(_VARIABLE_SCOPE_AIM_OFFSET, ModConfig.eye_relief_offset)
	optic.camera.fov = lerp(optic.camera.fov, distance * gd.baseFOV * lens_scale / ModConfig.current_scope_mag, delta * 10.0)

func distance_factor(base: float, distance: float) -> float:
	var f: float = base / (base + distance)
	return f