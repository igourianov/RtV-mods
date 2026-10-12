extends RefCounted

const Flicker := preload("./Flicker.gd")

# Tunable: brightness during a dip as a multiple of the vanilla energy, picked at random in this range for every dimmed activation.
const DIM_MIN := 0.3
const DIM_MAX := 0.7

var _lib
var _flicker := Flicker.new()


func _init(lib) -> void:
	_lib = lib


func on_activate_post() -> void:
	var caller = _lib._caller
	var data = caller.lightData

	# Vanilla writes an energy only for an equipped light with a power tier.
	# Without that write it is still the one dimmed last time, and dimming it again would compound.
	if caller.lightSlot.get_child_count() == 0 || !data || data.power == data.Power.None:
		return

	# No restore is needed: vanilla rewrites the full energy on the next activation.
	if _flicker.step(caller.lightSlot.get_child(0).slotData.condition):
		var dim := randf_range(DIM_MIN, DIM_MAX)
		caller.lightWorld.light_energy *= dim
		caller.lightFPS.light_energy *= dim
