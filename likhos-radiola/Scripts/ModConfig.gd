
# config vars
static var static_enabled: bool

static var _menu_pos_auto: int = 0

const DEFAULT_ENABLED := true


static func _get_config_value(config: ConfigFile, section: String, key: String, default_val):
	return config.get_value(section, key, {}).get("value", default_val)


static func apply_config(config: ConfigFile) -> void:
	static_enabled = _get_config_value(config, "Bool", "static_enabled", DEFAULT_ENABLED)


static func _next_pos() -> int:
	_menu_pos_auto += 1
	return _menu_pos_auto


static func _set_config_entry(config: ConfigFile, section: String, category: String, key: String, name: String, tooltip: String, default_val, extra: Dictionary = {}) -> void:
	var value := {
		"name": name,
		"tooltip": tooltip,
		"default": default_val,
		"value": default_val,
		"menu_pos": _next_pos(),
		"category": category
	}
	value.merge(extra)
	config.set_value(section, key, value)


static func create_template(config: ConfigFile) -> void:
	config.set_value("Category", "General", { "menu_pos": 0 })
	_set_config_entry(config, "Bool", "General", "static_enabled", "Radio static", "Play the radio hiss/static bed underneath the music", DEFAULT_ENABLED)
