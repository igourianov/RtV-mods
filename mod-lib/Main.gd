extends Node

const MCM_PATH := "res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres"
const MCM_CONFIG_PATH := "res://ModConfigurationMenu/Scripts/MCM_Config.gd"
const MCM_SIMPLE_TYPES := ["Bool", "Int", "Float", "String", "Color", "Vector2", "Vector3"]
# template key -> MCM value setter
const MCM_SETTERS := {
	"menu_pos": "setMenuPos",
	"category": "setCategory",
	"on_value_changed": "setOnValueChanged",
	"minRange": "setMinRange",
	"maxRange": "setMaxRange",
	"step": "setStep"
}
const Out := preload("./Out.gd")
const Inputs := preload("./Inputs.gd")

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
	var config := ConfigFile.new()
	var configFile:String = (get_script().resource_path.get_base_dir() + "/../mod.txt").simplify_path()
	config.load(configFile)
	mod_id = config.get_value("mod", "id", "")
	mod_name = config.get_value("mod", "name", "")
	mod_desc = config.get_value("mod", "description", "")
	Out.mod_main = self
	Out.prefix = config.get_value("mod", "prefix", "[likho-lib]")
	Out.debug_enabled = bool(config.get_value("mod", "debug", true))
	config.queue_free()


func _init_config():

	var config := ConfigFile.new()
	create_config(config)
	if !config.get_sections().size():
		load_config(config)
		return

	var helper = load(MCM_PATH) if ResourceLoader.exists(MCM_PATH) else null
	if !helper:
		load_config(config)
		return

	var mcm = load(MCM_CONFIG_PATH).new(mod_id, mod_name, mod_desc, load_config)
	_add_mcm_values(mcm, config)
	mcm.RegisterMod()
	# MCM keeps a separate file per Mod Loader profile, so the values have to come from its helper
	load_config(helper.GetModConfigFile(mod_id))


# Replays a template as MCM_Config builder calls, so mods keep defining their settings as plain dictionaries.
func _add_mcm_values(mcm, template: ConfigFile) -> void:
	for section in template.get_sections():
		for id in template.get_section_keys(section):
			var data: Dictionary = template.get_value(section, id)
			var value
			if section == "Category":
				value = mcm.CreateCategoryHeader(id, id)
			elif section == "Dropdown":
				value = mcm.CreateDropdownValue(id, data["name"], data["tooltip"], data["default"], data["options"])
			elif section in MCM_SIMPLE_TYPES:
				value = mcm.call("Create%sValue" % section, id, data["name"], data["tooltip"], data["default"])
			else:
				Out.warning("unsupported MCM value type %s for %s" % [section, id])
				continue

			if value == null:
				Out.warning("MCM rejected value %s" % id)
				continue
			for key in MCM_SETTERS:
				if data.has(key):
					value.call(MCM_SETTERS[key], data[key])


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

func load_config(config: ConfigFile):
	pass

func create_config(config: ConfigFile):
	pass

