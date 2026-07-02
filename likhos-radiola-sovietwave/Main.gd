extends Node


func _ready() -> void:
	var RadioRegistry = load("res://mods/likhos-radiola/Scripts/RadioRegistry.gd")
	if !RadioRegistry:
		push_warning("[likhos-radiola-sovietwave] Likho's Radiola not installed; station skipped")
		return
	var audio_dir: String = get_script().resource_path.get_base_dir().path_join("Audio")
	RadioRegistry.register_dir("Sovietwave FM 99.5", audio_dir)
