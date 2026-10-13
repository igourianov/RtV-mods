extends RefCounted

const Flicker := preload("./Flicker.gd")

# Tunable: amplification during a dip as a multiple of the vanilla one, picked at random in this range for every dimmed activation.
# Amplification is the part of the exposure above 1.0, the unaided level, so a dip never shows less than the naked eye does.
const DIM_MIN := 0.3
const DIM_MAX := 0.7

var _lib
var _flicker := Flicker.new()


func _init(lib) -> void:
	_lib = lib


func on_activate_post() -> void:
	var caller = _lib._caller
	var data = caller.NVGData

	# Vanilla writes an exposure only for an equipped NVG with one of its own three power tiers.
	# Without that write it is still the one dimmed last time, and dimming it again would compound.
	# NVGData outlives an emptied slot until the next deactivation, so the slot is checked too.
	if caller.NVGSlot.get_child_count() == 0 || !data || data.power == data.Power.None || data.power > data.Power.High:
		return

	# No restore is needed: vanilla rewrites the full exposure on the next activation.
	if _flicker.step(caller.NVGSlot.get_child(0).slotData.condition):
		var environment: Environment = caller.world.environment.environment
		environment.tonemap_exposure = lerpf(1.0, environment.tonemap_exposure, randf_range(DIM_MIN, DIM_MAX))
