extends RefCounted

# Tunable: the flicker starts below this charge, in percent.
const THRESHOLD := 5.0
# Tunable: brightness during a dip as a multiple of the vanilla energy, picked at random in this range for every dimmed activation.
const DIM_MIN := 0.3
const DIM_MAX := 0.7
# Tunable: a burst holds 1 to this many dips.
const BURST_MAX_DIPS := 3
# Tunable: a dip, and the pause after it inside a burst, each last 1 to this many activations.
const DIP_MAX_ACTIVATIONS := 2
# Tunable: mean seconds of lit time between bursts at the threshold and at empty, and the random spread around the mean.
const GAP_THRESHOLD_S := 8.0
const GAP_EMPTY_S := 1.0
const GAP_SPREAD := 0.5
# Vanilla ResetCheck re-activates a lit flashlight once in this many physics frames, every 83 ms.
const ACTIVATION_FRAMES := 10

var _lib
# Activations left until the next burst. Not positive while none is scheduled.
# Counted in activations so it only runs down while the light is on.
var _gap_left: int
# Remaining activations of the running burst, one bit each from the lowest up. A set bit is a dimmed activation.
var _burst: int


func _init(lib) -> void:
	_lib = lib


func on_activate_post() -> void:
	var caller = _lib._caller
	var data = caller.lightData

	# Vanilla writes energy only for an equipped light with a power tier.
	# Without that write the energy can still be the one dimmed last time, and dimming it again would compound.
	if caller.lightSlot.get_child_count() == 0 || !data || data.power == data.Power.None:
		return

	var charge: float = caller.lightSlot.get_child(0).slotData.condition
	if charge >= THRESHOLD:
		_gap_left = 0
		_burst = 0
		return

	if !_burst:
		if _gap_left <= 0:
			var mean: float = lerpf(GAP_EMPTY_S, GAP_THRESHOLD_S, charge / THRESHOLD)
			_gap_left = int(mean * randf_range(1.0 - GAP_SPREAD, 1.0 + GAP_SPREAD) * Engine.physics_ticks_per_second / ACTIVATION_FRAMES)

		_gap_left -= 1
		if _gap_left > 0:
			return

		# The pause after the last dip sets no bit, so the burst ends on its last dimmed activation.
		var bit := 0
		for _dip in randi_range(1, BURST_MAX_DIPS):
			for _activation in randi_range(1, DIP_MAX_ACTIVATIONS):
				_burst |= 1 << bit
				bit += 1
			bit += randi_range(1, DIP_MAX_ACTIVATIONS)

	# No restore is needed: vanilla rewrites the full energy on the next activation.
	if _burst & 1:
		var dim := randf_range(DIM_MIN, DIM_MAX)
		caller.lightWorld.light_energy *= dim
		caller.lightFPS.light_energy *= dim

	_burst >>= 1
