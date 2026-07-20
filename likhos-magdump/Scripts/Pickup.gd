extends RefCounted

const Out := preload("../Lib/Out.gd")

var _lib
var _compat: Dictionary
var _statics: Dictionary


func _init(lib, compat: Dictionary, statics: Dictionary) -> void:
	_lib = lib
	_compat = compat
	_statics = statics


func on_ready_post() -> void:
	var pickup: Node = _lib._caller
	if !pickup || !pickup.slotData || !pickup.slotData.itemData:
		return
	var gun_file: String = pickup.slotData.itemData.file
	if !_compat.has(gun_file):
		return
	var attachments := pickup.get_node_or_null("Attachments")
	if !attachments:
		return

	var native_node = _find_native_mag_node(attachments, pickup.slotData.itemData)
	if !native_node:
		Out.warning("no native mag node in %s pickup" % gun_file)
		return

	for foreign_id in _compat[gun_file]:
		if attachments.get_node_or_null(foreign_id) != null:
			continue
		var static_path: String = _statics.get(foreign_id, "")
		if static_path.is_empty():
			Out.warning("no static path for %s" % foreign_id)
			continue
		if !ResourceLoader.exists(static_path):
			Out.warning("static missing: %s" % static_path)
			continue
		var scene: PackedScene = load(static_path)
		if !scene:
			Out.warning("failed to load %s" % static_path)
			continue
		var foreign := scene.instantiate()
		foreign.name = foreign_id
		foreign.transform = native_node.transform
		foreign.visible = false
		attachments.add_child(foreign)


func _find_native_mag_node(attachments: Node, item_data):
	for compat_item in item_data.compatible:
		if compat_item.subtype != "Magazine":
			continue
		var node := attachments.get_node_or_null(compat_item.file)
		if node:
			return node
	return null
