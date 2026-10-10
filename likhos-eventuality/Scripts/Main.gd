extends "../Lib/Main.gd"

var LCM = load("res://mods/likhos-config-manager/Scripts/LCM.gd")
const EventSystem := preload("./EventSystem.gd")
const Police := preload("./Police.gd")
const Config := preload("./Config.gd")

var _event_system: EventSystem
var _police: Police
var _config := Config.new()


func setup(lib) -> void:
	# LCM reports only the values it loaded from its store, so Out is set up from the defaults here
	_on_config_applied()
	if is_instance_valid(LCM):
		LCM.register_config(mod_id, mod_name, _config, _on_config_applied)

	_event_system = EventSystem.new(lib, _config)
	_police = Police.new(lib)

	register_hook("eventsystem-activatedynamicevent", _event_system.on_activate_dynamic_event)
	register_hook("eventsystem-fighterjet-post", _event_system.on_fighter_jet_post)
	register_hook("eventsystem-crashsite", _event_system.on_crash_site)
	register_hook("police-_ready-post", _police.on_ready_post)
	register_hook("police-states-post", _police.on_states_post)


func _on_config_applied() -> void:
	Out.debug_enabled = _config.debug_enabled
