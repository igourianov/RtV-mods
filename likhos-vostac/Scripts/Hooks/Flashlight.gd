
const Out := preload("../../Lib/Out.gd")

# Tunable: beam shape as multiples of the vanilla range and cone angle.
const RANGE_FACTOR := 0.5
const CONE_FACTOR := 1.8
# Shared by the beam and the near light that lights the player's own hands and weapon.
# Vanilla puts the beam at (0, 0, 0.1) and the near light at (-1, 0, -2).
const LIGHT_POSITION := Vector3(0, 0.1, 0.2)
const WEAPON_LAYER := 1 << 1
# Tunable: seconds the near light takes to fade in or out with inspect, roughly the inspect start and exit animations.
const FPS_LIGHT_FADE := 0.5

var _lib
var _authored_cone: float
var _fps_fade := 0.0


func _init(lib) -> void:
	_lib = lib


func on_activate_post() -> void:
	var caller = _lib._caller
	var data = caller.lightData

	# Vanilla writes a range only for an equipped light with a power tier.
	# Without that write it is still the one scaled last time, and scaling it again would compound.
	if caller.lightSlot.get_child_count() == 0 || !data || data.power == data.Power.None:
		return

	var beam: SpotLight3D = caller.lightWorld

	# Vanilla never writes the cone and every flashlight node comes from the same scene, so the first cone seen is the authored one.
	# Scaling the node's current cone instead would compound on every activation.
	if !_authored_cone:
		_authored_cone = beam.spot_angle

	beam.spot_range *= RANGE_FACTOR
	beam.spot_angle = _authored_cone * CONE_FACTOR
	beam.position = LIGHT_POSITION
	caller.lightFPS.position = LIGHT_POSITION

	# Vanilla keeps the beam off the weapon layer.
	beam.light_cull_mask |= WEAPON_LAYER


func on_physics_process(delta: float) -> void:
	_lib.skip_super()
	var caller = _lib._caller

	# The slot is resolved 0.1 s after _ready, and ResetCheck dereferences it.
	if !caller.lightSlot:
		return

	caller.ResetCheck()
	if !caller.gameData.freeze && caller.gameData.flashlight:
		caller.Consumption(delta)

	# Lighting the weapon only pays off while inspecting it.
	_fps_fade = move_toward(_fps_fade, 1.0 if caller.gameData.isInspecting else 0.0, delta / FPS_LIGHT_FADE)
	var fps_light = caller.lightFPS
	fps_light.visible = _fps_fade > 0.0

	# Fading the color leaves the energy to vanilla and to mods that dim it, like Likho's Battery Powered.
	if caller.lightData:
		fps_light.light_color = caller.lightData.color * _fps_fade

	if !caller.has_node("FlashlightDriver"):
		var driver := FlashlightDriver.new()
		driver.name = "FlashlightDriver"
		caller.add_child(driver)
		Out.debug("flashlight input driver attached to", caller)


class FlashlightDriver extends Node:
	const Config := preload("../Config.gd")
	const AttachmentClickPlayer := preload("../Audio/AttachmentClickPlayer.gd")

	var gameData := preload("res://Resources/GameData.tres")
	var _activated_ms: int = 0
	var _click_sound: AttachmentClickPlayer


	func _init() -> void:
		_click_sound = AttachmentClickPlayer.new()
		add_child(_click_sound)


	func _input(evt: InputEvent) -> void:
		var parent = get_parent()
		var slot = parent.lightSlot
		var light = slot.get_child(0) if slot && slot.get_child_count() else null

		if !light || gameData.freeze:
			return

		if evt.is_action_pressed("flashlight", false):
			_click_sound.click_in()
			if !gameData.flashlight && light.slotData.condition > 0:
				parent.Activate()
				_activated_ms = Time.get_ticks_msec()
		elif evt.is_action_released("flashlight"):
			_click_sound.click_out()
			if gameData.flashlight && Time.get_ticks_msec() - _activated_ms > Config.BUTTON_HOLD_MS:
				parent.Deactivate()
