extends Node


func _ready() -> void:
	var RadioRegistry = load("res://mods/likhos-radiola/Scripts/RadioRegistry.gd")
	if !RadioRegistry:
		push_warning("[likhos-radiola-kolkhoz] Likho's Radiola not installed; station skipped")
		return
	var audio_dir: String = get_script().resource_path.get_base_dir().path_join("Audio")
	RadioRegistry.register_dir("Kolkhoz Punk 101.3", audio_dir)
