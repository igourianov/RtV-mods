extends RefCounted

const _PREFIX = "[likho-second-hand]"

# gun_id -> new size. Slots are unconditionally set to ["Primary", "Secondary"]
# so the weapon fits the secondary equipment slot in addition to the primary.
const RESIZE := {
	"AKS_74U": Vector2(4, 2),
	"VSS": Vector2(4, 2),
	"Remington_870": Vector2(5, 2),
	"KP_31": Vector2(4, 2),
}


static func apply(lib) -> void:
	var slots: Array[String] = ["Primary", "Secondary"]
	for gun_id in RESIZE:
		var gun = lib.get_entry(lib.Registry.ITEMS, gun_id)
		if gun == null:
			push_warning(_PREFIX, "could not find gun: ", gun_id)
			continue

		if !lib.patch(lib.Registry.ITEMS, gun_id, {"slots": slots, "size": RESIZE[gun_id]}):
			push_warning(_PREFIX, "patch failed for ", gun_id)
			continue

		print(_PREFIX, "patched ", gun_id, " size=", RESIZE[gun_id], " slots=", slots)
