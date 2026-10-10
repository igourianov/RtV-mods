extends Node

const LCM_PATH := "res://mods/likhos-config-manager/Scripts/LCM.gd"
const Out := preload("./Out.gd")
const Inputs := preload("./Inputs.gd")

var _lib
var _hooks: Array[int]
var _inputs: Inputs

var mod_id: String
var mod_name: String



func _ready() -> void:

	_load_mod_info()

	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		Out.warning("RTVModLib not available")
		return

	_init_config()
	_init_setup()



func _load_mod_info():
	var config := ConfigFile.new()
	var configFile:String = (get_script().resource_path.get_base_dir() + "/../mod.txt").simplify_path()
	config.load(configFile)
	mod_id = config.get_value("mod", "id", "")
	mod_name = config.get_value("mod", "name", "")
	Out.mod_main = self
	Out.prefix = config.get_value("mod", "prefix", "[likho-lib]")
	Out.debug_enabled = bool(config.get_value("mod", "debug", true))


func _init_config():

	var config := get_config()
	if !config:
		return

	# LCM reports only the values it loaded from its store, so state derived from the defaults is set up here
	_on_config_applied()

	if !ResourceLoader.exists(LCM_PATH):
		Out.warning("Likho's Config Manager is not installed, settings stay on their defaults")
		return
	load(LCM_PATH).register_config(mod_id, mod_name, config, _on_config_applied)


func _on_config_applied() -> void:
	var config := get_config()
	# settings of the lib itself, picked up from the mods that declare them
	if "debug_enabled" in config:
		Out.debug_enabled = config.debug_enabled
	if "show_protips" in config:
		Out.show_protips = config.show_protips
	config_applied()


func _init_setup():
	await _lib.frameworks_ready

	_hooks = []
	setup(_lib)

	var registered := _hooks.filter(func(id): return id > -1)
	if registered.size() == _hooks.size():
		Out.debug("all hooks registered successfully")
		return

	Out.warning("mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)


func register_hook(hookName: String, callback: Callable):
	_hooks.append(_lib.hook(hookName, callback) as int)


# event is the default binding: an InputEvent, the name of another action to take the binding from, or null for no default
func register_action(action: String, label: String, event: Variant = null):
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
	var input := InputEventMouseButton.new()
	input.button_index = button
	input.pressed = true
	return input


func create_key_input(keycode: int, ctrl_pressed: bool = false, shift_pressed: bool = false) -> InputEventKey:
	var input := InputEventKey.new()
	input.physical_keycode = keycode
	input.pressed = true
	input.ctrl_pressed = ctrl_pressed
	input.shift_pressed = shift_pressed
	return input


func setup(lib):
	pass

# a Resource with @export fields for Likho's Config Manager, the same object on every call
# its debug_enabled and show_protips fields, when declared, drive Out
func get_config() -> Resource:
	return null

# runs once on startup with the defaults, then every time stored or changed settings are written into the object from get_config
func config_applied() -> void:
	pass

