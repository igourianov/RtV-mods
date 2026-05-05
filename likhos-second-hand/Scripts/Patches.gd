extends RefCounted

const Out = preload("../Lib/Out.gd")

# Inventory footprint shrink. id -> new Vector2(width, height).
const RESIZE := {
	"AKS_74U": Vector2(4, 2),
	"VSS": Vector2(4, 2),
	"Remington_870": Vector2(6, 1),
	"KP_31": Vector2(4, 2),
	"Mosin": Vector2(7, 1),
}

# Guns that gain Secondary slot eligibility on top of vanilla Primary.
const SECONDARY := {
	"AKS_74U": null,
	"VSS": null,
	"Remington_870": null,
}

# Item.gd assigns `sprite.scale = Vector2(<field>, <field>)` for each attachment combo proportional inside the smaller cell box.
const FLOAT_SCALE_FIELDS := [
	"magazineScale",
	"opticScale",
	"suppressorScale",
	"magazineOpticScale",
	"magazineSuppressorScale",
	"opticSuppressorScale",
	"fullyModdedScale",
]

# Item.gd applies these as cell-pixel shifts to sprite.position.
const FLOAT_OFFSET_FIELDS := [
	"magazineOffset",
	"opticOffset",
	"suppressorOffset",
	"magazineOpticOffset",
	"magazineSuppressorOffset",
	"opticSuppressorOffset",
	"fullyModdedOffset",
]


static func apply(lib) -> void:
	_apply_resize(lib)
	_apply_secondary(lib)


static func _apply_resize(lib) -> void:
	for gun_id in RESIZE:
		var gun = lib.get_entry(lib.Registry.ITEMS, gun_id)
		if gun == null:
			Out.warning("could not find gun: %s" % gun_id)
			continue

		var new_size: Vector2 = RESIZE[gun_id]
		var old_size: Vector2 = gun.size
		if old_size.x <= 0 || old_size.y <= 0:
			Out.warning("%s has non-positive vanilla size, skipping" % gun_id)
			continue

		var fx: float = float(new_size.x) / float(old_size.x)
		var fy: float = float(new_size.y) / float(old_size.y)

		var fields := {
			"size": new_size,
		}
		for f in FLOAT_SCALE_FIELDS:
			fields[f] = float(gun.get(f)) * min(fx, fy * 1.8)
		for f in FLOAT_OFFSET_FIELDS:
			fields[f] = float(gun.get(f)) * fy

		if !lib.patch(lib.Registry.ITEMS, gun_id, fields):
			Out.warning("resize patch failed for %s" % gun_id)
			continue

		Out.debug("resized %s size=%s" % [gun_id, new_size])


static func _apply_secondary(lib) -> void:
	var slots: Array[String] = ["Primary", "Secondary"]
	for gun_id in SECONDARY:
		var gun = lib.get_entry(lib.Registry.ITEMS, gun_id)
		if gun == null:
			Out.warning("could not find gun: %s" % gun_id)
			continue

		if !lib.patch(lib.Registry.ITEMS, gun_id, {"slots": slots}):
			Out.warning("secondary patch failed for %s" % gun_id)
			continue

		Out.debug("secondary slot enabled for %s" % gun_id)
