extends RefCounted

static var force_english_names: bool = false


static func create(config: ConfigFile) -> void:
	var pos = [0]
	var next_pos = func(): pos[0] += 1; return pos[0]

	config.set_value("Category", "General", { "menu_pos": next_pos.call() })

	config.set_value("Bool", "ForceEnglishNames", {
		"name": "Force English names (requires game restart)",
		"default": false,
		"value": false,
		"menu_pos": next_pos.call(),
		"category": "General"
	})


static func apply(config: ConfigFile) -> void:
	force_english_names = config.get_value("Bool", "ForceEnglishNames", {}).get("value", false)
