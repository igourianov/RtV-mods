extends Node


func _ready() -> void:
	var RadioRegistry = load("res://mods/likhos-radiola/Scripts/RadioRegistry.gd")
	if !RadioRegistry:
		push_warning("[likhos-radiola-doomer] Likho's Radiola not installed; station skipped")
		return
	var audio_dir: String = get_script().resource_path.get_base_dir().path_join("Audio")
	RadioRegistry.register_dir("Doomer Nation 97.1", audio_dir)
