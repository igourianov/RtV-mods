extends Node

const CompatTable = preload("res://mods/likhos-magdump/Scripts/CompatTable.gd")

var _lib
var _foreign_mags_by_weapon: Dictionary = {}


func _ready() -> void:
	for weapon_path in CompatTable.COMPAT:
		_apply_for_weapon(weapon_path, CompatTable.COMPAT[weapon_path])

	if !Engine.has_meta("RTVModLib"):
		push_error("[likhos-magdump] RTVModLib not available; icon overlays disabled")
		return
	_lib = Engine.get_meta("RTVModLib")
	if _lib._is_ready:
		_register_hooks()
	else:
		_lib.frameworks_ready.connect(func(): _register_hooks())


func _register_hooks() -> void:
	# Initialize fires once per Item, often before our autoload registers hooks
	# (e.g. during save load). UpdateAttachments runs from inside Initialize and
	# on every nested change, so hooking it covers all cases.
	_lib.hook("item-updateattachments-pre", _on_update_attachments_pre)


func _apply_for_weapon(weapon_path: String, mag_entries: Dictionary) -> void:
	var weapon = load(weapon_path)
	if weapon == null:
		push_warning("[likhos-magdump] weapon not found: %s" % weapon_path)
		return
	var entries: Array = []
	for mag_path in mag_entries:
		var mag = load(mag_path)
		if mag == null:
			push_warning("[likhos-magdump] magazine not found: %s" % mag_path)
			continue
		if mag.subtype != "Magazine":
			push_warning("[likhos-magdump] %s is not a Magazine (subtype=%s)" % [mag_path, mag.subtype])
			continue
		if !weapon.compatible.has(mag):
			weapon.compatible.append(mag)
		entries.append({
			"mag": mag,
			"tweaks": mag_entries[mag_path],
		})
	if !entries.is_empty():
		_foreign_mags_by_weapon[weapon] = entries


func _on_update_attachments_pre() -> void:
	var item = _lib._caller
	if item == null || item.slotData == null || item.slotData.itemData == null:
		return
	var entries: Array = _foreign_mags_by_weapon.get(item.slotData.itemData, [])
	if entries.is_empty():
		return
	if item.sprite == null:
		return

	var native_mag_data = null
	for compat in item.slotData.itemData.compatible:
		if compat.subtype == "Magazine":
			native_mag_data = compat
			break
	if native_mag_data == null:
		return
	var native_sprite = item.sprite.get_node_or_null(native_mag_data.file)
	if native_sprite == null:
		return

	for entry in entries:
		var mag = entry["mag"]
		if item.sprite.has_node(mag.file):
			continue
		if mag.tetris == null:
			continue

		var tweaks: Dictionary = entry["tweaks"]
		var offset: Vector2 = tweaks.get("offset", Vector2.ZERO)
		var rotation_offset: float = tweaks.get("rotation_offset", 0.0)
		var scale_mult: Vector2 = tweaks.get("scale_mult", Vector2.ONE)

		var foreign_sprite = mag.tetris.instantiate()
		foreign_sprite.name = mag.file
		foreign_sprite.position = native_sprite.position + offset
		foreign_sprite.rotation = native_sprite.rotation + rotation_offset
		foreign_sprite.scale = native_sprite.scale * scale_mult
		foreign_sprite.show_behind_parent = native_sprite.show_behind_parent
		foreign_sprite.visible = false
		item.sprite.add_child(foreign_sprite)
