extends Resource

# event function -> the setting that holds its probability
const PROBABILITIES: Dictionary[String, StringName] = {
	"FighterJet": &"fighter_jets",
	"Police": &"punisher",
	"Airdrop": &"airdrops",
	"CrashSite": &"helicopter_crash_sites",
	"BTR": &"BTR_patrols",
	"Helicopter": &"attack_helicopters",
	"Bogeyman": &"bogeyman"
}

@export var debug_enabled: bool = false

@export_group("Probabilities")
@export_range(0.0, 100.0, 1.0) var fighter_jets: float = 25.0
@export_range(0.0, 100.0, 1.0) var punisher: float = 10.0
@export_range(0.0, 100.0, 1.0) var airdrops: float = 10.0
@export_range(0.0, 100.0, 1.0) var helicopter_crash_sites: float = 10.0
@export_range(0.0, 100.0, 1.0) var BTR_patrols: float = 25.0
@export_range(0.0, 100.0, 1.0) var attack_helicopters: float = 25.0
@export_range(0.0, 100.0, 1.0) var bogeyman: float = 10.0


func get_probability(function_name: String, fallback: float) -> float:
	var setting: StringName = PROBABILITIES.get(function_name, &"")
	return get(setting) if setting else fallback
