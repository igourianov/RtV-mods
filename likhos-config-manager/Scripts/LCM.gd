# Public API of Likho's Config Manager.
# Consumers load this script by its path, so it can never move or be renamed.

const Out := preload("./Out.gd")

const STORE_DIR := "user://LCM"
const LOADER_CONFIG := "user://mod_config.cfg"
const DEFAULT_PROFILE := "Default"
const EXPORTED := PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR
const SUPPORTED_TYPES: Array[int] = [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_COLOR, TYPE_VECTOR2, TYPE_VECTOR3]


class Entry:
	var uid: String
	var name: String
	var config: RefCounted
	var on_applied: Callable
	# property infos of the settings in declaration order, each with the "group" it is declared under
	var fields: Array[Dictionary]
	var defaults: Dictionary[String, Variant]


# static rather than autoload state, so a consumer can register before this mod's Main runs
static var _mods: Dictionary[String, Entry] = {}
# the uid names the store file, so it is held to what is a safe file name on every platform and cannot collide by case
static var _uid_pattern := RegEx.create_from_string("^[a-z0-9_-]+$")
# read once, because the loader can rename the active profile without a restart
static var _profile: String


static func register_config(mod_uid: String, mod_name: String, config: RefCounted, on_applied: Callable = Callable()) -> bool:
	if _uid_pattern.search(mod_uid) == null:
		Out.warning("config for \"%s\" is not registered, a mod uid can only contain a-z, 0-9, - and _" % mod_uid)
		return false
		
	if _mods.has(mod_uid):
		Out.warning("config for %s is already registered and will be replaced" % mod_uid)

	var entry := Entry.new()
	entry.uid = mod_uid
	entry.name = mod_name
	entry.config = config
	entry.on_applied = on_applied
	_mods[mod_uid] = entry

	var group: String = ""
	# the script's own list, because the object's list of a config that is a Resource opens with the engine's "Resource" group and only an editor build emits the category entry that would end that group before the script's fields
	for property in config.get_script().get_script_property_list():
		var usage: int = property.usage
		if usage & PROPERTY_USAGE_GROUP:
			group = property.name
			continue
		if usage & EXPORTED != EXPORTED:
			continue
		if property.type not in SUPPORTED_TYPES:
			Out.warning("%s: setting %s has an unsupported type and is skipped" % [mod_uid, property.name])
			continue
		property.group = group
		entry.fields.append(property)
		entry.defaults[property.name] = config.get(property.name)

	var profile := _active_profile()
	var store := _load_store(mod_uid)
	if !store.has_section(profile):
		return true

	for field in entry.fields:
		var field_name: String = field.name
		if !store.has_section_key(profile, field_name):
			continue
		var value: Variant = store.get_value(profile, field_name)
		# a value stored for a field that has since changed its type stays out, and the next save drops it
		if typeof(value) == field.type:
			config.set(field_name, value)
	if on_applied.is_valid():
		on_applied.call()
	return true


# values holds a value for every field of the mod
static func _apply(mod_uid: String, values: Dictionary) -> void:
	var entry := _mods[mod_uid]
	var config := entry.config
	var profile := _active_profile()
	var store := _load_store(mod_uid)
	var changed: bool = false
	for field in entry.fields:
		var field_name: String = field.name
		var value: Variant = values[field_name]
		if value != config.get(field_name):
			config.set(field_name, value)
			changed = true
		# only what differs from the default is stored, so a default changed by a mod update reaches untouched settings
		# null erases the key
		store.set_value(profile, field_name, value if value != entry.defaults[field_name] else null)
	if !changed:
		return

	var path := _store_path(mod_uid)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	store.save(path)
	if entry.on_applied.is_valid():
		entry.on_applied.call()


static func _active_profile() -> String:
	if !_profile:
		var loader_config := ConfigFile.new()
		# the loader has no accessor for it, and treats a missing file or key as Default
		loader_config.load(LOADER_CONFIG)
		_profile = str(loader_config.get_value("settings", "active_profile", DEFAULT_PROFILE))
	return _profile


static func _load_store(mod_uid: String) -> ConfigFile:
	var store := ConfigFile.new()
	store.load(_store_path(mod_uid))
	_adopt_legacy_section(store)
	return store


# Temporary, delete with its call once pre-profile files are gone.
# Such a file holds only a "values" section, which belongs to the Default profile.
static func _adopt_legacy_section(store: ConfigFile) -> void:
	const LEGACY_SECTION := "values"
	if store.get_sections() != PackedStringArray([LEGACY_SECTION]):
		return
	for key in store.get_section_keys(LEGACY_SECTION):
		store.set_value(DEFAULT_PROFILE, key, store.get_value(LEGACY_SECTION, key))
	store.erase_section(LEGACY_SECTION)


static func _store_path(mod_uid: String) -> String:
	return "%s/%s.cfg" % [STORE_DIR, mod_uid]
