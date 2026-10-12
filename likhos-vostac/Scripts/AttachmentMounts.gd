extends RefCounted

const Out := preload("../Lib/Out.gd")

# Attachments on weapons that ship without a mounting point for them.
# Vanilla shows an attachment by finding a child named after its `file` under the weapon's Attachments node.
# The weapon scenes have no such child, so it is added to live rig and pickup instances.
#
# Key format:   "<weapon file>" -> "<attachment file>"
# Value format: { "rig": <first person scene>, "pickup": <world model scene>, "transform": <placement> }
#
# The placement is in the frame of the Attachments node, which a weapon's rig and pickup share.
const MOUNTS := {
	"VSS": {
		"OZ5": {
			"rig": "res://Items/Attachments/OZ5/OZ5_Active.tscn",
			"pickup": "res://Items/Attachments/OZ5/OZ5_Static.tscn",
			# Upside down under the suppressor, which is a 19mm radius cylinder around the origin axis.
			# The body touches it and the clamp sinks into it, which hides that there is no rail to clamp on.
			"transform": Transform3D(Vector3(-0.9, 0, 0), Vector3(0, -0.9, 0), Vector3(0, 0, 0.9), Vector3(0, -0.035, 0.4)),
		},
	},
}


static func apply(lib) -> void:
	for weapon_file: String in MOUNTS:
		var weapon = lib.get_entry(lib.Registry.ITEMS, weapon_file)
		if !weapon:
			Out.warning("mount weapon not found: %s" % weapon_file)
			continue

		# Vanilla reads compatible[0] as the weapon's magazine, so the mounts go last.
		var compatible: Array[ItemData] = weapon.compatible.duplicate()
		for attachment_file: String in MOUNTS[weapon_file]:
			var attachment = lib.get_entry(lib.Registry.ITEMS, attachment_file)
			if !attachment:
				Out.warning("mount attachment not found: %s | for weapon: %s" % [attachment_file, weapon_file])
				continue
			if !compatible.has(attachment):
				compatible.append(attachment)

		if !lib.patch(lib.Registry.ITEMS, weapon_file, {"compatible": compatible}):
			Out.warning("mount patch failed for %s" % weapon_file)


# `kind` picks the scene of a mount: "rig" or "pickup".
static func mount(attachments: Node, weapon_file: String, kind: String, owner: Node = null) -> void:
	if !attachments:
		return

	var mounts: Dictionary = MOUNTS.get(weapon_file, {})
	for attachment_file: String in mounts:
		if attachments.has_node(attachment_file):
			continue

		var entry: Dictionary = mounts[attachment_file]
		var scene: PackedScene = load(entry[kind])
		if !scene:
			Out.warning("mount scene missing: %s" % entry[kind])
			continue

		var node: Node3D = scene.instantiate()
		node.name = attachment_file
		node.transform = entry["transform"]
		node.visible = false
		attachments.add_child(node)
		# Laser.gd reaches the rig through `owner`, which a node added at runtime does not have.
		node.owner = owner
