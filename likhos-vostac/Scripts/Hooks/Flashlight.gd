
const Out := preload("../../Lib/Out.gd")

# Tunable: beam shape as multiples of the vanilla range and cone angle.
const RANGE_FACTOR := 0.5
const CONE_FACTOR := 1.8
# Tunable: a flicker burst plays as the charge drains through this whole percent and through each one below it.
const FLICKER_THRESHOLD := 5
# Tunable: at or below this whole percent bursts follow each other without a break.
const STROBE_POINT := 1
# Tunable: brightness during a dip as a multiple of the vanilla energy, picked at random in this range for every dimmed activation.
const DIM_MIN := 0.3
const DIM_MAX := 0.7
# Tunable: a burst holds 1 to this many dips.
const BURST_MAX_DIPS := 3
# Tunable: a dip, and the pause before it, each last 1 to this many activations.
# Vanilla re-activates a lit flashlight every 10 physics frames, 83 ms.
const DIP_MAX_ACTIVATIONS := 2

var _lib
var _authored_cone: float
# The whole percent the charge was at or below on the last activation.
var _charge_point: int
# Remaining activations of the running burst, one bit each from the lowest up. A set bit is a dimmed activation.
var _burst: int


func _init(lib) -> void:
	_lib = lib


func on_activate_post() -> void:
	var caller = _lib._caller
	var data = caller.lightData

	# Vanilla writes a range and an energy only for an equipped light with a power tier.
	# Without that write they are still the ones scaled last time, and scaling them again would compound.
	if caller.lightSlot.get_child_count() == 0 || !data || data.power == data.Power.None:
		return

	var beam: SpotLight3D = caller.lightWorld

	# Vanilla never writes the cone and every flashlight node comes from the same scene, so the first cone seen is the authored one.
	# Scaling the node's current cone instead would compound on every activation.
	if !_authored_cone:
		_authored_cone = beam.spot_angle

	beam.spot_range *= RANGE_FACTOR
	beam.spot_angle = _authored_cone * CONE_FACTOR

	var point := ceili(caller.lightSlot.get_child(0).slotData.condition)

	# A light that died or was recharged mid-burst must not play the leftover dips at its new charge.
	if point > _charge_point:
		_burst = 0

	# Draining moves the charge by one whole percent at most between activations.
	# A larger drop is a swapped battery or another light, and a first sighting has no previous point. Neither is a cue.
	if (point == _charge_point - 1 && point <= FLICKER_THRESHOLD) || (point <= STROBE_POINT && !_burst):
		# The pause comes before its dip, so two bursts in a row never merge their dips.
		var bit := 0
		for _dip in randi_range(1, BURST_MAX_DIPS):
			bit += randi_range(1, DIP_MAX_ACTIVATIONS)
			for _activation in randi_range(1, DIP_MAX_ACTIVATIONS):
				_burst |= 1 << bit
				bit += 1

	_charge_point = point

	# No restore is needed: vanilla rewrites the full energy on the next activation.
	if _burst & 1:
		var dim := randf_range(DIM_MIN, DIM_MAX)
		beam.light_energy *= dim
		caller.lightFPS.light_energy *= dim

	_burst >>= 1


func on_physics_process(delta: float) -> void:
	_lib.skip_super()
	var caller = _lib._caller

	# The slot is resolved 0.1 s after _ready, and ResetCheck dereferences it.
	if !caller.lightSlot:
		return

	caller.ResetCheck()
	if !caller.gameData.freeze && caller.gameData.flashlight:
		caller.Consumption(delta)

	if !caller.has_node("FlashlightDriver"):
		var driver := FlashlightDriver.new()
		driver.name = "FlashlightDriver"
		caller.add_child(driver)
		Out.debug("flashlight input driver attached to", caller)


class FlashlightDriver extends Node:
	const ModConfig := preload("../ModConfig.gd")
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
			if gameData.flashlight && Time.get_ticks_msec() - _activated_ms > ModConfig.BUTTON_HOLD_MS:
				parent.Deactivate()
