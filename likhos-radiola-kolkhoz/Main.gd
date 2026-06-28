extends Node

# Bootstrap: inject the Kolkhoz Punk station into Likho's Radiola, then get out of
# the way. No hooks, no config, no RTVModLib. The only dependency is the core's
# Station script being mounted; if the core is absent we log and do nothing.
# Appending to the core's static REGISTRY is order-independent, so this runs in
# plain _ready without waiting on the framework.

const STATION_SCRIPT := "res://mods/likhos-radiola/Scripts/RadioStation.gd"
const STATION_DATA := "res://mods/likhos-radiola-kolkhoz/kolkhoz-punk.tres"


func _ready() -> void:
	var station_script = load(STATION_SCRIPT)
	if !station_script:
		push_warning("[likho-radiola-kolkhoz] Likho's Radiola not installed; station skipped")
		return
	var def = load(STATION_DATA)
	if !def:
		push_warning("[likho-radiola-kolkhoz] failed to load station data")
		return
	station_script.REGISTRY.append(def)
