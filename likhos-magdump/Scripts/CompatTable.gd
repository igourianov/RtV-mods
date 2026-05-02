extends RefCounted

const _PREFIX = "[likho-magdump]"

# gun_id -> [foreign_mag_id, ...]. Direction matters: a gun accepting another's
# mag does not imply the reverse.
const COMPAT := {
	"AK_12": ["AKS_74U_Magazine"],
	"AKS_74U": ["AK_12_Magazine"],
	"RK_62": ["AKM_Magazine"],
	"RK_62M": ["AKM_Magazine"],
	"RK_95": ["AKM_Magazine"],
	"AKM": ["RK_Magazine"],
	"HK416": ["KAR_21_223_Magazine"],
	"M4A1": ["KAR_21_223_Magazine"],
	"MK18": ["KAR_21_223_Magazine"],
	"KAR_21_223": ["STANAG_Magazine"],
}


static func apply(lib) -> void:
	for gun_id in COMPAT:
		var gun = lib.get_entry(lib.Registry.ITEMS, gun_id)
		if gun == null:
			push_warning(_PREFIX, "could not find gun: ", gun_id)
			continue

		var mags: Array = []
		for mag_id in COMPAT[gun_id]:
			var mag = lib.get_entry(lib.Registry.ITEMS, mag_id)
			if mag == null:
				push_warning(_PREFIX, "could not find attachment: ", mag_id, " | for gun: ", gun_id)
			else:
				mags.append(mag)
				
		_inject_mags(lib, gun, mags)


# Bakes foreign-mag sprite children into a clone of the gun's tetris PackedScene
# and patches the gun's `tetris` field via the registry. Vanilla
# Item.UpdateAttachments matches sprite children by node name, so once the
# foreign sprite ships in the prefab no per-instance hook is needed.
static func _inject_mags(lib, gun, mags: Array) -> void:
	if mags.is_empty():
		return

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
	for mag in mags:
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
			gun.compatible.insert(1, mag)

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

	if !lib.patch(lib.Registry.ITEMS, gun.file, {"tetris": repacked}):
		push_warning(_PREFIX, "patch failed for ", gun.file)
