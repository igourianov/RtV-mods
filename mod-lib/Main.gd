extends Node

var McmHelpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")
const Out = preload("./Out.gd")

var _lib
var _hooks: Array[int]
var _menu_pos_auto: int = 0

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

	if !FileAccess.file_exists(filePath):
		DirAccess.open("user://").make_dir(configDir)
		config.save(filePath)
	elif McmHelpers:
		McmHelpers.CheckConfigurationHasUpdated(mod_id, config, filePath)

		config.load(filePath)

	load_config(config)

	if McmHelpers:
		McmHelpers.RegisterConfiguration(mod_id, mod_name, configDir, mod_desc, {
			"config.ini": load_config
		})


func _init_setup():
	await _lib.frameworks_ready

	_hooks = []
	setup(_lib)

	var registered = _hooks.filter(func(id): return id > -1)
	if registered.size() == _hooks.size():
		#Out.debug("all hooks registered successfully")
		return

	Out.warning("mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)


func register_hook(hookName: String, callback: Callable):
	var id = _lib.hook(hookName, callback)
	if id != -1:
		#Out.debug("hook(%s):%s registered" % [hookName, id])
	else:
		Out.warning("hook(%s) failed" % hookName)
	return id


func next_menu_pos() -> int:
	_menu_pos_auto += 1
	return _menu_pos_auto




func setup(lib):
	pass

func load_config(config: ConfigFile):
	pass

func create_config(config: ConfigFile):
	pass

