extends RefCounted

# Tunable: a flicker burst plays as the charge drains through this whole percent and through each one below it.
const THRESHOLD := 5
# Tunable: at or below this whole percent bursts follow each other without a break.
const STROBE_POINT := 1
# Tunable: a burst holds 1 to this many dips.
const BURST_MAX_DIPS := 3
# Tunable: a dip, and the pause before it, each last 1 to this many steps.
const DIP_MAX_STEPS := 2
# Vanilla re-activates a lit flashlight every 10 physics frames, 83 ms, and that activation is its step.
# A source without such a tick steps itself at the same pace.
const STEP_FRAMES := 10

# The whole percent the charge was at or below on the last step.
var _charge_point: int
# Remaining steps of the running burst, one bit each from the lowest up. A set bit is a dip.
var _burst: int


# Advances the flicker by one step at the given charge. True while that step is inside a dip.
func step(charge: float) -> bool:
	var point := ceili(charge)

	# A source that died or was recharged mid-burst must not play the leftover dips at its new charge.
	if point > _charge_point:
		_burst = 0

	# Draining moves the charge by one whole percent at most between steps.
	# A larger drop is a swapped battery or another source, and a first sighting has no previous point. Neither is a cue.
	if (point == _charge_point - 1 && point <= THRESHOLD) || (point <= STROBE_POINT && !_burst):
		# The pause comes before its dip, so two bursts in a row never merge their dips.
		var bit := 0
		for _dip in randi_range(1, BURST_MAX_DIPS):
			bit += randi_range(1, DIP_MAX_STEPS)
			for _step in randi_range(1, DIP_MAX_STEPS):
				_burst |= 1 << bit
				bit += 1

	_charge_point = point

	var dip := bool(_burst & 1)
	_burst >>= 1
	return dip
