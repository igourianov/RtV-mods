extends "../Lib/Main.gd"

const EventSystem := preload("./EventSystem.gd")
const Police := preload("./Police.gd")
const ModConfig := preload("./ModConfig.gd")

var _event_system: EventSystem
var _police: Police
var _config := ModConfig.new()


func create_config(config: ConfigFile) -> void:
	_config.create_template(config)


func load_config(config: ConfigFile) -> void:
	_config.apply_config(config)


func setup(lib) -> void:
	_event_system = EventSystem.new(lib, _config)
	_police = Police.new(lib)

	register_hook("eventsystem-activatedynamicevent", _event_system.on_activate_dynamic_event)
	register_hook("eventsystem-fighterjet-post", _event_system.on_fighter_jet_post)
	register_hook("eventsystem-crashsite", _event_system.on_crash_site)
	register_hook("police-_ready-post", _police.on_ready_post)
	register_hook("police-states-post", _police.on_states_post)
