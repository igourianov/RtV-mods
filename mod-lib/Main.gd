extends Node

const Out := preload("./Out.gd")
const Inputs := preload("./Inputs.gd")

var _lib
var _inputs: Inputs

var mod_id: String
var mod_name: String



func _ready() -> void:

	_load_mod_info()

	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		Out.warning("RTVModLib not available")
		return

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


func _init_setup():
	await _lib.frameworks_ready
	setup(_lib)


# Only a replace hook can be rejected, when another hook already owns its slot. The loader exposes the owner's hook id, not the mod.
# Lower priority values fire first within the same hook variant.
func register_hook(hookName: String, callback: Callable, priority: int = 100):
	if _lib.hook(hookName, callback, priority) < 0:
		Out.warning("hook %s rejected, slot owned by hook id %d" % [hookName, _lib.get_replace_owner(hookName)])


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

