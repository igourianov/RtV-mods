extends Node

const MCM_PATH := "res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres"
const Out = preload("./Out.gd")
const Inputs = preload("./Inputs.gd")

var _lib
var _hooks: Array[int]
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
	Out.mod_main = self
	Out.prefix = config.get_value("mod", "prefix", "[likho-lib]")
	Out.debug_enabled = bool(config.get_value("mod", "debug", true))
	config.queue_free()


func _init_config():

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
	_hooks.append(_lib.hook(hookName, callback) as int)


func register_action(action: String, label: String, event: InputEvent):
	_init_inputs_hooks()
	_inputs.extra_actions.append({
		"action": action,
		"label": label,
		"event": event
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


func noop(_arg = null) -> void:
	_lib.skip_super()


func create_mouse_input(button: int) -> InputEventMouseButton:
	var input = InputEventMouseButton.new()
	input.button_index = button
	input.pressed = true
	return input


func create_key_input(keycode: int, ctrl_pressed: bool = false, shift_pressed: bool = false) -> InputEventKey:
	var input = InputEventKey.new()
	input.physical_keycode = keycode
	input.pressed = true
	input.ctrl_pressed = ctrl_pressed
	input.shift_pressed = shift_pressed
	return input


func setup(lib):
	pass

func load_config(config: ConfigFile):
	pass

func create_config(config: ConfigFile):
	pass

