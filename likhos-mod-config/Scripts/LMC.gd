# Public API of Likho's Mod Config.
# Consumers load this script by its path, so it can never move or be renamed.

const Out := preload("../Lib/Out.gd")

const STORE_DIR := "user://LMC"
const STORE_SECTION := "values"
const EXPORTED := PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_EDITOR
const SUPPORTED_TYPES: Array[int] = [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_COLOR, TYPE_VECTOR2, TYPE_VECTOR3]


class Entry:
	var uid: String
	var name: String
	var config: Resource
	var on_applied: Callable
	# property infos of the settings in declaration order, each with the "group" it is declared under
	var fields: Array[Dictionary]
	var defaults: Dictionary[String, Variant]


# static rather than autoload state, so a consumer can register before this mod's Main runs
static var mods: Dictionary[String, Entry] = {}


static func RegisterConfig(mod_uid: String, mod_name: String, config: Resource, on_applied: Callable = Callable()) -> void:
	if mods.has(mod_uid):
		Out.warning("config for %s is already registered" % mod_uid)
		return

	var entry := Entry.new()
	entry.uid = mod_uid
	entry.name = mod_name
	entry.config = config
	entry.on_applied = on_applied
	mods[mod_uid] = entry

	var group: String = ""
	for property in config.get_property_list():
		var usage: int = property.usage
		# a group declared by a base class ends where the next class begins
		if usage & PROPERTY_USAGE_CATEGORY:
			group = ""
			continue
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

	var store := ConfigFile.new()
	if store.load(_store_path(mod_uid)) != OK:
		return

	for field in entry.fields:
		var field_name: String = field.name
		if !store.has_section_key(STORE_SECTION, field_name):
			continue
		var value: Variant = store.get_value(STORE_SECTION, field_name)
		# a value stored for a field that has since changed its type stays out, and the next save drops it
		if typeof(value) == field.type:
			config.set(field_name, value)
	if on_applied.is_valid():
		on_applied.call()


# values holds a value for every field of the mod
static func apply(mod_uid: String, values: Dictionary) -> void:
	var entry := mods[mod_uid]
	var config := entry.config
	var store := ConfigFile.new()
	var changed: bool = false
	for field in entry.fields:
		var field_name: String = field.name
		var value: Variant = values[field_name]
		if value != config.get(field_name):
			config.set(field_name, value)
			changed = true
		# only what differs from the default is stored, so a default changed by a mod update reaches untouched settings
		if value != entry.defaults[field_name]:
			store.set_value(STORE_SECTION, field_name, value)
	if !changed:
		return

	var path := _store_path(mod_uid)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	store.save(path)
	if entry.on_applied.is_valid():
		entry.on_applied.call()


static func _store_path(mod_uid: String) -> String:
	return "%s/%s.cfg" % [STORE_DIR, mod_uid]
