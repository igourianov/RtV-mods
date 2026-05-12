extends Node

const MCM_PATH := "res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres"
const Out = preload("./Out.gd")
const Inputs = preload("./Inputs.gd")

var _lib
var _hooks: Array[int]
var _menu_pos_auto: int = 0
var _inputs: Inputs

var mod_id: String
var mod_name: String
var mod_desc: String



func _ready() -> void:

	_load_mod_info()

	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		Out.warning("RTVModLib not available")
		return

	_init_config()
	_init_setup()



func _load_mod_info():
	var config = ConfigFile.new()
	var configFile = (get_script().resource_path.get_base_dir() + "/../mod.txt").simplify_path()
	config.load(configFile)
	mod_id = config.get_value("mod", "id", "")
	mod_name = config.get_value("mod", "name", "")
	mod_desc = config.get_value("mod", "description", "")
	Out.prefix = config.get_value("mod", "prefix", "[likho-lib]")
	Out.debug_enabled = bool(config.get_value("mod", "debug", true))
	config.queue_free()


func _init_config():

	_menu_pos_auto = 0
	var config = ConfigFile.new()
	create_config(config)
	if !config.get_sections().size():
		load_config(config)
		return

	var configDir = "user://MCM/" + mod_id
	var filePath = configDir + "/config.ini"
	var helper = load(MCM_PATH) if ResourceLoader.exists(MCM_PATH) else null

	if !FileAccess.file_exists(filePath):
		DirAccess.open("user://").make_dir(configDir)
		config.save(filePath)
	elif helper:
		helper.CheckConfigurationHasUpdated(mod_id, config, filePath)
		config.load(filePath)

	load_config(config)

	if helper:
		helper.RegisterConfiguration(mod_id, mod_name, configDir, mod_desc, {
			"config.ini": load_config
		})


func _init_setup():
	await _lib.frameworks_ready

	_hooks = []
	setup(_lib)

	var registered = _hooks.filter(func(id): return id > -1)
	if registered.size() == _hooks.size():
		Out.debug("all hooks registered successfully")
		return

	Out.warning("mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)


func register_hook(hookName: String, callback: Callable):
	var id = _lib.hook(hookName, callback)
	if id != -1:
		Out.debug("hook(%s):%s registered" % [hookName, id])
	else:
		Out.warning("hook(%s) failed" % hookName)
	return id


func next_menu_pos() -> int:
	_menu_pos_auto += 1
	return _menu_pos_auto


func register_action(action: String, label: String, event: InputEvent, hidden: bool = false):
	_init_inputs_hooks()
	_inputs.extra_actions.append({
		"action": action,
		"label": label,
		"event": event,
		"hidden": hidden
	})
	# register empty action right away to avoid errors from InputMap
	if !InputMap.has_action(action):
		InputMap.add_action(action)


func remove_action(action: String):
	_init_inputs_hooks()
	_inputs.remove_actions.append(action)


func _init_inputs_hooks():
	if !_inputs:
		_inputs = Inputs.new(_lib)
		register_hook("inputs-createactions-pre", _inputs.on_create_actions_pre)
		register_hook("inputs-createactions-post", _inputs.on_create_actions_post)
		register_hook("inputs-resetactions-post", _inputs.on_reset_actions_post)

func setup(lib):
	pass

func load_config(config: ConfigFile):
	pass

func create_config(config: ConfigFile):
	pass

