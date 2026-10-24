
const Out := preload("../../Lib/Out.gd")

# Tunable: beam range per ItemData.Power tier: None, Low, Medium, High. Half of vanilla's 25, 50 and 100.
const BEAM_RANGES: Array[float] = [0.0, 12.5, 25.0, 50.0]
# Tunable: beam cone angle in degrees. Vanilla authors 25.
const BEAM_CONE := 45.0
# Tunable: beam shadow opacity. Vanilla authors 0, which hides the shadows.
const BEAM_SHADOW_OPACITY := 0.7
# Beam source per light item file, relative to the camera: -Z is forward, -X is left.
# The near light that lights the player's own hands and weapon always sits at the camera.
# Vanilla puts the beam at (0, 0, 0.1) and the near light at (-1, 0, -2).
const LIGHT_POSITIONS := {
	"Narva": Vector3(-0.1, -0.05, -0.1),
	"Polaris": Vector3(0, 0.05, -0.1),
}
# Phoenix, also used for lights from other mods.
const DEFAULT_LIGHT_POSITION := Vector3(-0.15, 0.0, -0.1)
const WEAPON_LAYER := 1 << 1
# Tunable: seconds the near light takes to fade in or out with inspect, roughly the inspect start and exit animations.
const FPS_LIGHT_FADE := 0.5

var gameData := preload("res://Resources/GameData.tres")
var _lib
var _fps_fade := 0.0


func _init(lib) -> void:
	_lib = lib


func on_activate_post() -> void:
	var caller = _lib._caller
	var data = caller.lightData

	if !data:
		return

	caller.lightFPS.position = Vector3.ZERO

	var beam: SpotLight3D = caller.lightWorld
	beam.spot_range = BEAM_RANGES[data.power]
	beam.spot_angle = BEAM_CONE
	beam.position = LIGHT_POSITIONS.get(data.file, DEFAULT_LIGHT_POSITION)
	# Vanilla enables shadows but hides them with zero opacity and a caster mask of layers 21-32 only.
	beam.shadow_opacity = BEAM_SHADOW_OPACITY
	beam.shadow_caster_mask |= WEAPON_LAYER


func on_physics_process(delta: float) -> void:
	_lib.skip_super()
	var caller = _lib._caller

	# The slot is resolved 0.1 s after _ready, and ResetCheck dereferences it.
	if !caller.lightSlot:
		return

	caller.ResetCheck()
	if !gameData.freeze && gameData.flashlight:
		caller.Consumption(delta)

	# Vanilla keeps the beam off the weapon layer. Only canted and raised hold the weapon up into the beam.
	var beam: SpotLight3D = caller.lightWorld
	var mask: int = beam.light_cull_mask
	if gameData.isAiming || gameData.isCanted || gameData.weaponPosition == 2:
		mask |= WEAPON_LAYER
	else:
		mask &= ~WEAPON_LAYER
	if beam.light_cull_mask != mask:
		beam.light_cull_mask = mask

	# Lighting the weapon only pays off while inspecting it.
	_fps_fade = move_toward(_fps_fade, 1.0 if gameData.isInspecting else 0.0, delta / FPS_LIGHT_FADE)
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
