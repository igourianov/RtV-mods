extends RefCounted

const _PREFIX = "[likho-second-hand]"

# gun_id -> new size. The long axis shrinks by one cell. Slots are
# unconditionally set to ["Primary", "Secondary"] so the weapon fits the
# secondary equipment slot in addition to the primary.
const RESIZE := {
	"AKS_74U": Vector2(4, 2),
	"VSS": Vector2(4, 2),
	"Remington_870": Vector2(5, 2),
	"KP_31": Vector2(4, 2),
}

# Item.gd assigns `sprite.scale = Vector2(<field>, <field>)` for each
# attachment combo. Multiplied by `factor`, the rendered picture stays
# proportional inside the smaller cell box.
const FLOAT_SCALE_FIELDS := [
	"magazineScale",
	"opticScale",
	"suppressorScale",
	"magazineOpticScale",
	"magazineSuppressorScale",
	"opticSuppressorScale",
	"fullyModdedScale",
]

# Item.gd applies these as cell-pixel shifts to sprite.position. They are
# tuned for the original cell box, so they need to scale with the linear
# shrink factor too.
const FLOAT_OFFSET_FIELDS := [
	"magazineOffset",
	"opticOffset",
	"suppressorOffset",
	"magazineOpticOffset",
]

const VECTOR2_OFFSET_FIELDS := [
	"magazineSuppressorOffset",
	"opticSuppressorOffset",
	"fullyModdedOffset",
]


static func apply(lib) -> void:
	var slots: Array[String] = ["Primary", "Secondary"]
	for gun_id in RESIZE:
		var gun = lib.get_entry(lib.Registry.ITEMS, gun_id)
		if gun == null:
			push_warning(_PREFIX, "could not find gun: ", gun_id)
			continue

		var new_size: Vector2 = RESIZE[gun_id]
		var old_size: Vector2 = gun.size
		if old_size.x <= 0:
			push_warning(_PREFIX, gun_id, " has non-positive size.x, skipping")
			continue

		var factor: float = float(new_size.x) / float(old_size.x)

		var fields := {
			"slots": slots,
			"size": new_size,
		}
		for f in FLOAT_SCALE_FIELDS:
			fields[f] = float(gun.get(f)) * factor
		for f in FLOAT_OFFSET_FIELDS:
			fields[f] = float(gun.get(f)) * factor
		for f in VECTOR2_OFFSET_FIELDS:
			var v: Vector2 = gun.get(f)
			fields[f] = v * factor

		if !lib.patch(lib.Registry.ITEMS, gun_id, fields):
			push_warning(_PREFIX, "patch failed for ", gun_id)
			continue

		print(_PREFIX, "patched ", gun_id, " size=", new_size, " factor=", factor)
