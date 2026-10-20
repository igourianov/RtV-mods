const Out := preload("../Lib/Out.gd")
const Config := preload("./Config.gd")

static var gameData := preload("res://Resources/GameData.tres")

# PIP ADS puts the eye this many cm past the near eye relief bound
const _EYE_RELIEF_MARGIN := 0.5

# Entries for unknown scopes, e.g. added by other mods (see is_unknown).
# Vanilla ADS drives their zoom, so these only feed current_scope_mag and the zoom input's step count.
# The variable entry keeps three steps to match vanilla's zoom 1-3.
const _FALLBACK_FIXED := {
	"mag_range": [4.0],
	"eye_relief": Vector2(3.5, 6.0),
}
const _FALLBACK_VARIABLE := {
	"mag_range": [1.1, 3.0, 6.0],
	"eye_relief": Vector2(7.0, 11.0),
}

# weapon file -> scope file: rifles whose iron sights stay usable under that scope
const _IRON_SIGHTS: Dictionary[String, String] = {
	"Mosin": "PU",
	"M28": "PU",
}

# optic file -> lens center and radius measured from the lens mesh
static var _measured_lenses := {}

const DATA := {
	"ACOG": {
		"mag_range": [4.0],
		"eye_relief": Vector2(2.5, 4.5),
		"lens_radius": 0.013,
		"lens_center": Vector3(0.0, 0.0, -0.102),
	},
	"HMR": {
		"mag_range": [4.0],
		"eye_relief": Vector2(5.5, 8.0),
		"lens_radius": 0.017,
		"lens_center": Vector3(0.0, 0.0, -0.069),
	},
	"POSP": {
		"mag_range": [2.0, 3.5, 6.0],
		"mag_range_discrete": [2.0, 3.0, 4.0, 5.0, 6.0],
		"eye_relief": Vector2(6.5, 9.0),
		"lens_radius": 0.012,
		"lens_center": Vector3(0.0, 0.0, -0.078),
	},
	"PU": {
		"mag_range": [3.5],
		"eye_relief": Vector2(6.5, 8.5),
		"lens_radius": 0.0115,
		"lens_center": Vector3(0.0, 0.0, -0.081),
	},
	"Vudu": {
		"mag_range": [1.0, 3.2, 10.0],
		"mag_range_normalized": [1.0, 1.6, 2.5, 4.0, 6.3, 10.0],
		"mag_range_discrete": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
		"eye_relief": Vector2(6.5, 12.5),
		"lens_radius": 0.020,
		"lens_center": Vector3(0.0, 0.0, -0.131),
	},
	"Leopard": {
		"mag_range": [1.1, 3.0, 8.0],
		"mag_range_normalized": [1.1, 1.7, 2.8, 4.8, 8.0],
		"mag_range_discrete": [1.1, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0],
		"eye_relief": Vector2(7.0, 11.5),
		"lens_radius": 0.0185,
		"lens_center": Vector3(0.0, 0.0, -0.177),
	},
}


static func get_mag_range(att: AttachmentData) -> Array:
	var entry := _entry(att)
	var field := "mag_range"
	match Config.instance.magnification_schema:
		Config.MagnificationSchema.DISCRETE: field = "mag_range_discrete"
		Config.MagnificationSchema.NORMALIZED: field = "mag_range_normalized"
	return entry.get(field, entry["mag_range"])


# A scope or variable optic missing from DATA, e.g. added by another mod.
# VosTac leaves its zoom, isScoped, aim pose and tooltip to vanilla and to other mods.
static func is_unknown(att: AttachmentData) -> bool:
	return (att.scope || att.variable) && !DATA.has(att.file)


# Near and far bound in cm.
static func get_eye_relief(att: AttachmentData) -> Vector2:
	return _entry(att)["eye_relief"]


# Optic local lens center and radius, measured from the lens mesh where the catalog has none.
static func get_lens(optic: Node3D) -> Dictionary:
	var entry := _entry(optic.attachmentData)
	var center: Vector3 = entry.get("lens_center", Vector3.ZERO)
	var radius: float = entry.get("lens_radius", 0.0)

	if center == Vector3.ZERO || radius <= 0.0:
		var measured := _measure_lens(optic)
		if center == Vector3.ZERO:
			center = measured.center
		if radius <= 0.0:
			radius = measured.radius

	return {"center": center, "radius": radius}


# an optic's own top dot, or the iron sights of a listed weapon and scope pair
static func has_secondary_sight(rig: WeaponRig) -> bool:
	var optic = rig.activeOptic if rig else null
	return optic && (optic.secondary || _IRON_SIGHTS.get(rig.data.file) == optic.attachmentData.file)


static func sync_optic_state(rig: WeaponRig) -> void:
	var optic = rig.activeOptic if rig else null
	# BUGFIX: vanilla forgets to reset secondaryOptic when equipping another optic, breaking other scopes in PIP mode
	if gameData.secondaryOptic && !has_secondary_sight(rig):
		gameData.secondaryOptic = false
	var scoped: bool = optic && (optic.attachmentData.scope || optic.attachmentData.variable) && !gameData.secondaryOptic
	if !optic || !is_unknown(optic.attachmentData):
		gameData.isScoped = scoped
	if scoped:
		var mags := get_mag_range(optic.attachmentData)
		Config.instance.current_scope_mag = mags[clamp(rig.slotData.zoom, 1, mags.size()) - 1]
	else:
		Config.instance.current_scope_mag = 1.0

	if rig:
		if !optic:
			rig.aimOffset = 0.0
		elif !gameData.secondaryOptic:
			rig.aimOffset = optic.position.y
		elif optic.secondary:
			# BUGFIX: vanilla fails to factor optic.scale, causing incorrect Y offset on several guns
			rig.aimOffset = optic.position.y + optic.secondary.position.y * optic.scale.y
		else:
			# iron sights: Handling poses an optic aim at -aimOffset, so this lands on the no-optic aim pose
			rig.aimOffset = -rig.data.aimPosition.y


# ADS target position for the rig's active optic
static func get_aim_position(rig: WeaponRig) -> Vector3:
	var depth: float = rig.data.aimPosition.z
	var optic = rig.activeOptic
	# an unknown scope keeps vanilla's aim pose
	if gameData.PIP && gameData.isScoped && !is_unknown(optic.attachmentData):
		# the eye lands at the optic's eye relief behind the lens center, wherever the optic sits on the rail
		var lens_depth: float = (optic.transform * get_lens(optic).center).z
		depth = lens_depth - (get_eye_relief(optic.attachmentData).x + _EYE_RELIEF_MARGIN) * 0.01
	return Vector3(0.0, -rig.aimOffset, depth)


static func _measure_lens(optic: Node3D) -> Dictionary:
	var key: String = optic.attachmentData.file
	if _measured_lenses.has(key):
		return _measured_lenses[key]

	var result := {"center": Vector3.ZERO, "radius": 0.0}
	if optic.mesh == null || optic.mesh.mesh == null:
		return result
	var arrays: Array = optic.mesh.mesh.surface_get_arrays(optic.maskIndex)
	if arrays.is_empty():
		return result
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return result

	var t: Transform3D = optic.mesh.transform
	var center := Vector3.ZERO
	for v in verts:
		center += t * v
	center /= verts.size()

	var max_r_sq := 0.0
	for v in verts:
		var p: Vector3 = t * v
		max_r_sq = max(max_r_sq, (p.x - center.x) ** 2 + (p.y - center.y) ** 2)

	result.center = center
	result.radius = sqrt(max_r_sq)
	_measured_lenses[key] = result
	Out.debug("extracted lens geometry for", key, "center:", center, "radius:", result.radius)
	return result


static func _entry(att: AttachmentData) -> Dictionary:
	var entry = DATA.get(att.file)
	if entry != null:
		return entry
	if att.variable:
		return _FALLBACK_VARIABLE
	if att.scope:
		return _FALLBACK_FIXED
	return {}


static func apply(lib) -> void:
	lib.patch(lib.Registry.ITEMS, "HMR", {
		"rarity": 2, # legendary
		"value": 2000,
	})
	var posp = lib.get_entry(lib.Registry.ITEMS, "POSP")
	lib.patch(lib.Registry.ITEMS, "POSP", {
		"name": posp.name + " 2-6x",
		"scope": false,
		"variable": true,
		"reticleSize": Vector3(0.3, 0.3, 0.3), # fixed size across mag range
		"reticleSizeP": Vector3(0.35, 0.35, 0.35), # fixed size across mag range
	})
	lib.patch(lib.Registry.ITEMS, "Vudu", {
		"rarity": 2, # legendary
		"value": 3000,
		"reticleSizeP": Vector3(0.1, 0.3, 1.2), # default Z is too small
	})
	lib.patch(lib.Registry.ITEMS, "Leopard", {
		"reticleSizeP": Vector3(0.2, 0.4, 0.6), # default X is very small
	})
