extends RefCounted

const Out = preload("../Lib/Out.gd")

const NATIVE_KEY = &"likho_magdump_native"
const OVERLAYS_KEY = &"likho_magdump_overlays"

var _lib
# gun_file -> { mag_file: {mesh: ArrayMesh, material: Material, bullet_local: Vector3} }
var _table: Dictionary = {}


func _init(lib, compat: Dictionary, pickups: Dictionary) -> void:
	_lib = lib
	_build_table(compat, pickups)


func _build_table(compat: Dictionary, pickups: Dictionary) -> void:
	var cache := {}
	for gun_id in compat:
		var overlays := {}
		for mag_file in compat[gun_id]:
			if !pickups.has(mag_file):
				Out.warning("no pickup path for %s" % mag_file)
				continue
			if !cache.has(mag_file):
				cache[mag_file] = _extract_pickup_data(pickups[mag_file])
			var data: Dictionary = cache[mag_file]
			if !data.is_empty():
				overlays[mag_file] = data
		if !overlays.is_empty():
			_table[gun_id] = overlays


# Pickup .tscn carries LOD0/LOD1 meshes plus a Bullets/Cartridge_Rifle child
# positioned at the topmost-round point in mesh-local frame. We extract the
# mesh, material and bullet position in one pass.
func _extract_pickup_data(pickup_path: String) -> Dictionary:
	if !ResourceLoader.exists(pickup_path):
		Out.warning("pickup missing: %s" % pickup_path)
		return {}
	var scene: PackedScene = load(pickup_path)
	if !scene:
		Out.warning("failed to load %s" % pickup_path)
		return {}
	var instance = scene.instantiate()
	var lod0 = instance.get_node_or_null("LOD0")
	if !lod0 or !(lod0 is MeshInstance3D):
		Out.warning("no LOD0 MeshInstance3D in %s" % pickup_path)
		instance.free()
		return {}
	var cartridge = instance.get_node_or_null("Bullets/Cartridge_Rifle")
	if !cartridge:
		Out.warning("no Bullets/Cartridge_Rifle in %s" % pickup_path)
	var data := {
		"mesh": lod0.mesh,
		"material": lod0.get_surface_override_material(0),
		"bullet_local": cartridge.position if cartridge else Vector3.ZERO,
	}
	instance.free()
	return data


func on_ready_post() -> void:
	var rig = _lib._caller
	if !rig or !rig.data or !rig.skeleton or !rig.magazine:
		return
	var gun_file: String = rig.data.file
	if !_table.has(gun_file):
		return
	var overlay_data: Dictionary = _table[gun_file]

	var bone_name = _find_mag_bone(rig.skeleton)
	if bone_name.is_empty():
		Out.warning("could not detect mag bone for %s" % gun_file)
		return
	var bone_idx = rig.skeleton.find_bone(bone_name)
	if bone_idx == -1:
		Out.warning("bone %s missing in skeleton of %s" % [bone_name, gun_file])
		return

	# Anchor by topmost-round position. The host rig has Bullets/Cartridge_Rifle
	# in mag-bone-local frame, marking the chamber feed point. Each foreign mag's
	# pickup carries the same node in mesh-local frame. Translate the overlay so
	# the two coincide; the chamber-end of the foreign mag lines up regardless of
	# the mag's overall length.
	var host_bullet_local: Vector3 = Vector3.ZERO
	if rig.bullets and rig.bullets.get_child_count() > 0:
		host_bullet_local = rig.bullets.get_child(0).position
	else:
		Out.warning("no bullets node for %s, falling back to identity anchor" % gun_file)

	var overlays := {}
	for mag_file in overlay_data:
		var data: Dictionary = overlay_data[mag_file]
		var attachment := BoneAttachment3D.new()
		attachment.name = "MagOverlay_" + mag_file
		attachment.bone_name = bone_name
		attachment.bone_idx = bone_idx
		rig.skeleton.add_child(attachment)

		var mesh: Mesh = data["mesh"]
		var foreign_bullet_local: Vector3 = data["bullet_local"]

		var mesh_node := MeshInstance3D.new()
		mesh_node.layers = rig.magazine.layers
		mesh_node.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_node.mesh = mesh
		if data["material"]:
			mesh_node.set_surface_override_material(0, data["material"])
		mesh_node.position = host_bullet_local - foreign_bullet_local
		mesh_node.visible = false
		attachment.add_child(mesh_node)

		overlays[mag_file] = mesh_node

	rig.set_meta(NATIVE_KEY, rig.magazine)
	rig.set_meta(OVERLAYS_KEY, overlays)

	_resolve_pointer(rig, false)


func on_update_rig_pre() -> void:
	var rm = _lib._caller
	if !rm or rm.get_child_count() == 0:
		return
	var rig = rm.get_child(rm.get_child_count() - 1)
	if !rig or !rig.has_meta(OVERLAYS_KEY):
		return
	# Detach path needs `magazine.visible == true` for the drop animation to
	# play, so we leave the pointer alone there. On attach / cross-swap we
	# transfer visibility so the new mesh appears (or stays hidden) in lockstep.
	if _get_loaded_mag_file(rig).is_empty():
		return
	_resolve_pointer(rig, true)


func refresh_after_cross_swap(iface) -> void:
	if !iface or !iface.rigManager:
		return
	var rm = iface.rigManager
	if rm.get_child_count() == 0:
		return
	var rig = rm.get_child(rm.get_child_count() - 1)
	if !rig or !rig.has_meta(OVERLAYS_KEY):
		return
	_resolve_pointer(rig, true)


func _resolve_pointer(rig, transfer_visibility: bool) -> void:
	var native = rig.get_meta(NATIVE_KEY)
	var overlays: Dictionary = rig.get_meta(OVERLAYS_KEY)
	var mag_file := _get_loaded_mag_file(rig)
	var target = overlays.get(mag_file, native)
	if !target or rig.magazine == target:
		return
	var was_visible: bool = rig.magazine.visible if rig.magazine else false
	if rig.magazine:
		rig.magazine.hide()
	rig.magazine = target
	if transfer_visibility and was_visible:
		target.show()


func _find_mag_bone(skeleton: Skeleton3D) -> String:
	for child in skeleton.get_children():
		if child is BoneAttachment3D and child.bone_name.ends_with("_Magazine"):
			return child.bone_name
	return ""


func _get_loaded_mag_file(rig) -> String:
	if !rig.slotData:
		return ""
	for nested in rig.slotData.nested:
		if nested.subtype == "Magazine":
			return nested.file
	return ""
