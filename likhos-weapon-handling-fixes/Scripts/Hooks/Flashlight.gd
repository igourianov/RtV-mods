
const Out = preload("../../Lib/Out.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_physics_process(delta: float) -> void:
	_lib.skip_super()
	var caller = _lib._caller

	caller.ResetCheck()
	if !caller.gameData.freeze && caller.gameData.flashlight:
		caller.Consumption(delta)

	if !caller.has_node("FlashlightDriver"):
		var driver = FlashlightDriver.new()
		driver.name = "FlashlightDriver"
		caller.add_child(driver)
		Out.debug("flashlight input driver attached to", caller)


class FlashlightDriver extends Node:
	const HOLD_THRESHOLD = 0.25
	const AttachmentClickPlayer = preload("../Audio/AttachmentClickPlayer.gd")

	var gameData = preload("res://Resources/GameData.tres")
	var _hold_elapsed := 0.0
	var _click_sound: AttachmentClickPlayer


	func _init() -> void:
		_click_sound = AttachmentClickPlayer.new()
		add_child(_click_sound)


	func _physics_process(delta: float):
		if gameData.flashlight:
			_hold_elapsed += delta


	func _input(evt: InputEvent) -> void:
		var parent = get_parent()
		var slot = parent.lightSlot
		var light = slot.get_child(0) if slot && slot.get_child_count() else null

		if !light:
			return

		if evt.is_action_pressed("flashlight", false) && !gameData.freeze:
			_click_sound.click_in()
			if !gameData.flashlight:
				parent.Activate()
				_hold_elapsed = 0.0
		elif evt.is_action_released("flashlight") && gameData.flashlight:
			_click_sound.click_out()
			if _hold_elapsed > HOLD_THRESHOLD:
				parent.Deactivate()
