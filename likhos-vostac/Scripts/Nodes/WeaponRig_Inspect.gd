extends "./WeaponRig_Base.gd"

const FPS_LIGHT_PATH := "/root/Map/Core/Camera/Flashlight/FPS"
const INSPECT_LIGHT_POSITION := Vector3(0, 0.15, 0.2)
const LIGHT_LERP_SPEED := 10.0

var _fps_light: Node3D
var _fps_light_origin: Vector3


func _ready() -> void:
	set_process_input(true)
	set_process(true)


func _process(delta: float) -> void:
	if !_fps_light:
		_fps_light = get_node_or_null(FPS_LIGHT_PATH) as Node3D
		if !_fps_light:
			return
		_fps_light_origin = _fps_light.position

	var target := INSPECT_LIGHT_POSITION if gameData.isInspecting else _fps_light_origin
	_fps_light.position = _fps_light.position.lerp(target, delta * LIGHT_LERP_SPEED)


func _input(event: InputEvent) -> void:
	if is_engine_busy() || gameData.isInserting || gameData.isClearing || gameData.isReloading || gameData.isChecking:
		return

	var rig = get_parent()

	if event.is_action_pressed("inspect"):
		_inspect_toggle()
		return

	if !gameData.isInspecting:
		return

	gameData.isAiming = false

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
	var zoomIn := event.is_action_pressed("optic_zoom_in", true)
	var zoomOut := event.is_action_pressed("optic_zoom_out", true)

	if (zoomIn || zoomOut) && optic && optic.railMovement:
		var min_val := roundi(optic.minPosition * 100)
		var max_val := roundi(optic.maxPosition * 100)
		var new_z := roundi(optic.position.z * 100) + (1 if zoomIn else -1)

		if new_z >= min_val && new_z <= max_val:
			rig.slotData.position += 0.01 if zoomIn else -0.01
			optic.position.z = optic.defaultPosition + rig.slotData.position
			_zoom_audio.click()


func _inspect_toggle() -> void:
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
