extends Node

var McmHelpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")
const Printer = preload("./Printer.gd")

var _lib
var _hooks: Array[int] 
var _printer: Printer
var _modId: String
var _modName: String
var _modDesc: String
var _prefix: String 
var _menu_pos_auto: int = 0


func _ready() -> void:

	_load_mod_info()
	_printer = Printer.new(_prefix)

	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		_printer.warning("RTVModLib not available")
		return

	_init_config()
	_init_setup()



func _load_mod_info():
	var config = ConfigFile.new()
	var configFile = (get_script().resource_path.get_base_dir() + "/../mod.txt").simplify_path()
	config.load(configFile)
	_modId = config.get_value("mod", "id", "")
	_modName = config.get_value("mod", "name", "")
	_modDesc = config.get_value("mod", "description", "")
	_prefix = config.get_value("mod", "prefix", "[likho-lib]")
	config.queue_free()


func _init_config():

	_menu_pos_auto = 0
	var config = ConfigFile.new()
	create_config(config)
	if !config.get_sections().size():
		load_config(config)
		return

	var configDir = "user://MCM/" + _modId
	var filePath = configDir + "/config.ini"

	if !FileAccess.file_exists(filePath):
		DirAccess.open("user://").make_dir(configDir)
		config.save(filePath)
	elif McmHelpers:
		McmHelpers.CheckConfigurationHasUpdated(_modId, config, filePath)
		config.load(filePath)

	load_config(config)

	if McmHelpers:
		McmHelpers.RegisterConfiguration(_modId, _modName, configDir, _modDesc, {
			"config.ini": load_config
		})


func _init_setup():
	await _lib.frameworks_ready

	_hooks = []
	setup(_lib)

	var registered = _hooks.filter(func(id): return id > -1)
	if registered.size() == _hooks.size():
		_printer.debug("all hooks registered successfully")
		return

	_printer.warning("mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)


func register_hook(hookName: String, callback: Callable):
	var id = _lib.hook(hookName, callback)
	if id != -1:
		_printer.debug("hook(%s):%s registered" % [hookName, id])
	else:
		_printer.warning("hook(%s) failed" % hookName)
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

