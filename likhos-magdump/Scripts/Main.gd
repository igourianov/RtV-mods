extends Node

const _PREFIX = "[likho-magdump]"
const CompatTable = preload("res://mods/likhos-magdump/Scripts/CompatTable.gd")
const _Interface = preload("res://mods/likhos-magdump/Scripts/Interface.gd")

var _interface
var _lib


func _ready() -> void:
	_lib = Engine.get_meta("RTVModLib")
	if _lib == null:
		push_warning(_PREFIX, "RTVModLib not available")
		return

	for gun_id in CompatTable.COMPAT:
		var gun = _lib.get_entry(_lib.Registry.ITEMS, gun_id)
		if gun == null:
			push_warning(_PREFIX, "could not find gun: ", gun_id)
			continue

		var foreign_mags: Array = []
		for attach_id in CompatTable.COMPAT[gun_id]:
			var mag = _lib.get_entry(_lib.Registry.ITEMS, attach_id)
			if mag == null:
				push_warning(_PREFIX, "could not find attachment: ", attach_id, " | for gun: ", gun_id)
				continue
			foreign_mags.append(mag)

		if !foreign_mags.is_empty():
			_bake_foreign_mags(gun, foreign_mags)

	if _lib._is_ready:
		_register_hooks()
	else:
		_lib.frameworks_ready.connect(func(): _register_hooks())


# Bakes foreign-mag sprite children into a clone of the gun's tetris PackedScene
# and patches the gun's `tetris` field via the registry. Vanilla
# Item.UpdateAttachments matches sprite children by node name, so once the
# foreign sprite ships in the prefab no per-instance hook is needed.
func _bake_foreign_mags(gun, foreign_mags: Array) -> void:
	var native_mag = null
	for c in gun.compatible:
		if c.type == "Attachment" && c.subtype == "Magazine":
			native_mag = c
			break
	if native_mag == null:
		push_warning(_PREFIX, "no native mag in compatible for ", gun.file)
		return

	var tree = gun.tetris.instantiate()
	var native_sprite = tree.get_node_or_null(native_mag.file)
	if native_sprite == null:
		push_warning(_PREFIX, "native mag sprite '", native_mag.file, "' not found in tetris of ", gun.file)
		tree.queue_free()
		return

	var added := 0
	for mag in foreign_mags:
		if tree.has_node(mag.file):
			continue

		var foreign = mag.tetris.instantiate()
		foreign.name = mag.file
		foreign.position = native_sprite.position
		foreign.rotation = native_sprite.rotation
		foreign.scale = native_sprite.scale
		foreign.show_behind_parent = native_sprite.show_behind_parent
		foreign.visible = false
		tree.add_child(foreign)
		# pack() only serializes nodes whose owner is the scene root.
		foreign.owner = tree
		added += 1

		if !gun.compatible.has(mag):
			gun.compatible.insert(0, mag)

		print(_PREFIX, "baked ", mag.file, " into ", gun.file)

	if added == 0:
		tree.queue_free()
		return

	var repacked := PackedScene.new()
	var err := repacked.pack(tree)
	tree.queue_free()
	if err != OK:
		push_warning(_PREFIX, "failed to repack tetris for ", gun.file, " err=", err)
		return

	if !_lib.patch(_lib.Registry.ITEMS, gun.file, {"tetris": repacked}):
		push_warning(_PREFIX, "patch failed for ", gun.file)


func _register_hooks() -> void:
	_interface = _Interface.new(_lib)

	var hooks: Array[int] = [
		_register_hook(_lib, "interface-getmagazine", _on_get_magazine)
	]

	var registered = hooks.filter(func(id): return id > -1)
	if registered.size() == hooks.size():
		print(_PREFIX, "all hooks registered successfully")
		return

	push_warning(_PREFIX, "mod registration failed, rolling back")
	for id in registered:
		_lib.unhook(id)


func _register_hook(lib, hookName: String, callback: Callable):
	var id = lib.hook(hookName, callback)
	if id != -1:
		print(_PREFIX, "hook(%s):%s registered" % [hookName, id])
	else:
		push_warning(_PREFIX, "hook(%s) failed" % hookName)
	return id
