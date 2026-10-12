extends RefCounted

const Out := preload("../Lib/Out.gd")

# Attachments on weapons that ship without a mounting point for them.
# Vanilla shows an attachment through a child named after its `file`: under the Attachments node of the weapon's rig and pickup, and under the sprite of its inventory icon.
#
# Key format: "<weapon file>" -> "<attachment file>"
# "transform" is in the frame of the Attachments node, which a weapon's rig and pickup share.
# "icon_transform" is in the frame of the weapon sprite: texture pixels from its center.
const MOUNTS: Dictionary[String, Dictionary] = {
	"VSS": {
		"OZ5": {
			"rig": "res://Items/Attachments/OZ5/OZ5_Active.tscn",
			"pickup": "res://Items/Attachments/OZ5/OZ5_Static.tscn",
			# The suppressor is a 19mm radius cylinder around the origin axis. The clamp is sunk into it to hide the missing rail.
			"transform": Transform3D(Vector3(-0.9, 0, 0), Vector3(0, -0.9, 0), Vector3(0, 0, 0.9), Vector3(0, -0.035, 0.4)),
			"icon": "res://Items/Attachments/OZ5/OZ5_2x1.tscn",
			# 0.42 brings the laser icon to the weapon icon's 640 px per meter.
			"icon_transform": Transform2D(Vector2(0.42, 0), Vector2(0, -0.42), Vector2(196, -7)),
		},
	},
}


static func apply(lib) -> void:
	for weapon_file: String in MOUNTS:
		var weapon: ItemData = lib.get_entry(lib.Registry.ITEMS, weapon_file)
		if !weapon:
			Out.warning("mount weapon not found: %s" % weapon_file)
			continue

		var compatible: Array[ItemData] = weapon.compatible.duplicate()
		var icon: Node2D = weapon.tetris.instantiate()
		var changed := false
		var mounts: Dictionary = MOUNTS[weapon_file]
		for attachment_file: String in mounts:
			var attachment: ItemData = lib.get_entry(lib.Registry.ITEMS, attachment_file)
			if !attachment:
				Out.warning("mount attachment not found: %s | for weapon: %s" % [attachment_file, weapon_file])
				continue

			if !icon.has_node(attachment_file):
				var entry: Dictionary = mounts[attachment_file]
				var path: String = entry["icon"]
				var scene: PackedScene = load(path)
				if !scene:
					Out.warning("mount scene missing: %s" % path)
					continue

				var sprite: Node2D = scene.instantiate()
				sprite.name = attachment_file
				sprite.transform = entry["icon_transform"]
				# Hides the part that overlaps the weapon sprite, as the clamp is sunk in 3D.
				sprite.show_behind_parent = true
				sprite.visible = false
				icon.add_child(sprite)
				# pack() only serializes nodes owned by the scene root.
				sprite.owner = icon
				changed = true

			if !compatible.has(attachment):
				# Vanilla reads compatible[0] as the weapon's magazine, so the mounts go last.
				compatible.append(attachment)
				changed = true

		if !changed:
			icon.free()
			continue

		var tetris := PackedScene.new()
		var err := tetris.pack(icon)
		icon.free()
		if err != OK:
			Out.warning("mount icon repack failed for %s err=%s" % [weapon_file, err])
			continue

		if !lib.patch(lib.Registry.ITEMS, weapon_file, {"compatible": compatible, "tetris": tetris}):
			Out.warning("mount patch failed for %s" % weapon_file)


static func mount(attachments: Node, weapon_file: String, kind: String, owner: Node = null) -> void:
	if !attachments:
		return

	var mounts: Dictionary = MOUNTS.get(weapon_file, {})
	for attachment_file: String in mounts:
		if attachments.has_node(attachment_file):
			continue

		var entry: Dictionary = mounts[attachment_file]
		var path: String = entry[kind]
		var scene: PackedScene = load(path)
		if !scene:
			Out.warning("mount scene missing: %s" % path)
			continue

		var node: Node3D = scene.instantiate()
		node.name = attachment_file
		node.transform = entry["transform"]
		node.visible = false
		attachments.add_child(node)
		# Laser.gd reaches the rig through `owner`, which a node added at runtime does not have.
		node.owner = owner
