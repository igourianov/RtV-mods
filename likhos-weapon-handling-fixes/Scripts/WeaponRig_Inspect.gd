extends "./WeaponRig_Base.gd"

const ScopeCatalog = preload("./ScopeCatalog.gd")

const FPS_LIGHT_PATH := "/root/Map/Core/Camera/Flashlight/FPS"
const INSPECT_LIGHT_POSITION := Vector3(0, 0.15, 0.2)
const LIGHT_LERP_SPEED := 10.0

var _fps_light
var _fps_light_origin


func _ready() -> void:
	set_process_input(true)
	set_process(true)


func _process(delta: float) -> void:
	if !_fps_light:
		_fps_light = get_node_or_null(FPS_LIGHT_PATH)
		if !_fps_light:
			return
		_fps_light_origin = _fps_light.position

	var target = INSPECT_LIGHT_POSITION if gameData.isInspecting else _fps_light_origin
	_fps_light.position = _fps_light.position.lerp(target, delta * LIGHT_LERP_SPEED)


func _input(event) -> void:
	if is_engine_busy() || gameData.isInserting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var rig = get_parent()

	if event.is_action_pressed("inspect"):
		_inspect_toggle()
		return

	if !gameData.isInspecting:
		return

	if event.is_action_pressed("canted"):
		if gameData.inspectPosition == 1:
			rig.PlayInspectRotate()
			rig.animator["parameters/conditions/Inspect_Front"] = false
			rig.animator["parameters/conditions/Inspect_Back"] = true
			gameData.inspectPosition = 2
		elif gameData.inspectPosition == 2:
			rig.PlayInspectRotate()
			rig.animator["parameters/conditions/Inspect_Front"] = true
			rig.animator["parameters/conditions/Inspect_Back"] = false
			gameData.inspectPosition = 1
		return

	var optic = rig.activeOptic
	var zoomIn = event.is_action_pressed("optic_zoom_in", true)
	var zoomOut = event.is_action_pressed("optic_zoom_out", true)

	if (zoomIn || zoomOut) && optic && optic.railMovement:
		if zoomIn && optic.position.z < optic.maxPosition:
			optic.position.z += 0.01
			rig.slotData.position += 0.01
			ScopeCatalog.update_optic_cache(rig, optic)
			rig.PlayRailMove()
		elif zoomOut && optic.position.z > optic.minPosition:
			optic.position.z -= 0.01
			rig.slotData.position -= 0.01
			ScopeCatalog.update_optic_cache(rig, optic)
			rig.PlayRailMove()
		return


func _inspect_toggle():
	var rig = get_parent()
	gameData.isInspecting = !gameData.isInspecting
	gameData.isFiring = false

	if gameData.isInspecting:
		gameData.inspectPosition = 1
		rig.PlayInspectStart()
		rig.animator["parameters/conditions/Inspect_Front"] = true
		rig.animator["parameters/conditions/Inspect_Idle"] = false
		rig.UpdateBullets()
		rig.UpdateHUD()
		Out.protip("inspect-rotate", "Press [%s] to rotate or [%s] / [%s] to move optic" % [
			Inputs.get_binding("canted"),
			Inputs.get_binding("optic_zoom_in"),
			Inputs.get_binding("optic_zoom_out")
		])
	elif gameData.inspectPosition == 1:
		rig.PlayInspectEnd()
		rig.animator["parameters/conditions/Inspect_Front"] = false
		rig.animator["parameters/conditions/Inspect_Idle"] = true
	elif gameData.inspectPosition == 2:
		rig.PlayInspectEnd()
		rig.animator["parameters/conditions/Inspect_Back"] = false
		rig.animator["parameters/conditions/Inspect_Idle"] = true
		gameData.inspectPosition = 1
