extends RefCounted

const Out := preload("../Lib/Out.gd")

const NATIVE_KEY := &"likho_magdump_native"
const OVERLAYS_KEY := &"likho_magdump_overlays"

const SWAP_DELAY := 1.2

var _lib
# gun_file -> { mag_file: {mesh: Mesh, material: Material, bullet_xform: Transform3D, bullet_stagger: Vector3} }
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



# Pickup .tscn carries LOD0/LOD1 meshes plus a Bullets/Cartridge_Rifle(_2) pair
# at the topmost staggered rounds in mesh-local frame. We extract the mesh,
# material, top-round pose and the stagger vector (mag width) in one pass.
func _extract_pickup_data(pickup_path: String) -> Dictionary:
	if !ResourceLoader.exists(pickup_path):
		Out.warning("pickup missing: %s" % pickup_path)
		return {}
	var scene: PackedScene = load(pickup_path)
	if !scene:
		Out.warning("failed to load %s" % pickup_path)
		return {}
	var instance := scene.instantiate()
	var lod0: MeshInstance3D = instance.get_node_or_null("LOD0")
	if !lod0 || !(lod0 is MeshInstance3D):
		Out.warning("no LOD0 MeshInstance3D in %s" % pickup_path)
		instance.free()
		return {}
	var cartridge: Node3D = instance.get_node_or_null("Bullets/Cartridge_Rifle")
	if !cartridge:
		Out.warning("no Bullets/Cartridge_Rifle in %s" % pickup_path)
	var bullet_xform := Transform3D.IDENTITY
	if cartridge:
		bullet_xform = cartridge.transform
	# Vector between the staggered top pair encodes the mag's width. Used to scale
	# the overlay along its width axis so a narrower/wider foreign mag still fills
	# the host magwell and lines up with the host's rounds.
	var bullet_stagger := Vector3.ZERO
	var cartridge2: Node3D = instance.get_node_or_null("Bullets/Cartridge_Rifle_2")
	if cartridge && cartridge2:
		bullet_stagger = cartridge2.position - cartridge.position
	var data := {
		"mesh": lod0.mesh,
		"material": lod0.get_surface_override_material(0),
		"bullet_xform": bullet_xform,
		"bullet_stagger": bullet_stagger,
	}
	instance.free()
	return data


func on_ready_post() -> void:
	var rig = _lib._caller
	if !rig || !rig.data || !rig.skeleton || !rig.magazine:
		return
	var gun_file: String = rig.data.file
	if !_table.has(gun_file):
		return
	var overlay_data: Dictionary = _table[gun_file]

	var bone_name := _find_mag_bone(rig.skeleton)
	if bone_name.is_empty():
		Out.warning("could not detect mag bone for %s" % gun_file)
		return
	var bone_idx: int = rig.skeleton.find_bone(bone_name)
	if bone_idx == -1:
		Out.warning("bone %s missing in skeleton of %s" % [bone_name, gun_file])
		return

	# Anchor by topmost-round full pose, scale included. The host rig has
	# Bullets/Cartridge_Rifle in mag-bone-local frame, marking the chamber feed
	# point, orientation and scale. Each foreign mag's pickup carries the same node
	# in mesh-local frame. We align the overlay so the two cartridge poses coincide.
	# This handles translation (works regardless of mag length), rotation (rotated
	# magwells) and scale: the cartridge is a shared scene, so its per-gun scale
	# (e.g. 1.2 in KAR-21 vs 1.1 in MK18) is the exact factor needed to re-fit a
	# foreign mag mesh into a host gun modelled at a different scale.
	var host_xform := Transform3D.IDENTITY
	var host_stagger := Vector3.ZERO
	if rig.bullets && rig.bullets.get_child_count() > 0:
		var host_cart: Node3D = rig.bullets.get_child(0)
		host_xform = host_cart.transform
		if rig.bullets.get_child_count() > 1:
			host_stagger = rig.bullets.get_child(1).position - host_cart.position
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
		var foreign_xform: Transform3D = data["bullet_xform"]

		var mesh_node := MeshInstance3D.new()
		mesh_node.layers = rig.magazine.layers
		mesh_node.cast_shadow = MeshInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_node.mesh = mesh
		if data["material"]:
			mesh_node.set_surface_override_material(0, data["material"])
		var basis := host_xform.basis * foreign_xform.basis.inverse()
		# Match the mag's width without rolling it. Scale only along the host's
		# lateral axis (perpendicular to round-forward and to the mag's length) by the
		# ratio of the staggered rounds' lateral spacing. Scaling along the raw stagger
		# vector instead would stretch along a diagonal and shear the mesh, which reads
		# as a spurious tilt/offset.
		var foreign_stagger: Vector3 = data["bullet_stagger"]
		var v := basis * foreign_stagger
		var lat := host_xform.basis.x.normalized()
		var v_lat := absf(v.dot(lat))
		var d_lat := absf(host_stagger.dot(lat))
		if v_lat > 0.0001 && d_lat > 0.0001:
			basis = _scale_along_axis(lat, d_lat / v_lat) * basis
		# Anchor on the midpoint of the staggered pair, not a single round, so the
		# mag centres on the magwell instead of biasing toward one side.
		var foreign_mid := foreign_xform.origin + foreign_stagger * 0.5
		var host_mid := host_xform.origin + host_stagger * 0.5
		var origin := host_mid - basis * foreign_mid
		mesh_node.transform = Transform3D(basis, origin)
		mesh_node.visible = false
		attachment.add_child(mesh_node)

		overlays[mag_file] = mesh_node

	rig.set_meta(NATIVE_KEY, rig.magazine)
	rig.set_meta(OVERLAYS_KEY, overlays)

	_resolve_pointer(rig, false)


func on_update_rig_pre(_animate = false) -> void:
	var rm: Node = _lib._caller
	if !rm || rm.get_child_count() == 0:
		return
	var rig = rm.get_child(rm.get_child_count() - 1)
	if !rig || !rig.has_meta(OVERLAYS_KEY):
		return
	# Detach path needs `magazine.visible == true` for the drop animation to
	# play, so we leave the pointer alone there.
	if _get_loaded_mag_file(rig).is_empty():
		return

	var native: MeshInstance3D = rig.get_meta(NATIVE_KEY)
	var overlays: Dictionary = rig.get_meta(OVERLAYS_KEY)
	var mag_file := _get_loaded_mag_file(rig)
	var target: MeshInstance3D = overlays.get(mag_file, native)
	if !target || rig.magazine == target:
		return

	# Inventory drag-drop reloads route through here instead of GetMagazine, so
	# mirror the bind-path refresh semantics. A currently visible magazine means
	# a swap (old mag still on screen mid-animation): defer the mesh switch until
	# the reload animation completes, matching refresh_after_cross_swap. A hidden
	# magazine means attach: switch the pointer now so the vanilla magazine.show()
	# at the animation tail reveals the overlay, matching refresh_after_attach.
	if rig.magazine && rig.magazine.visible:
		_await_then_resolve(rig)
	else:
		_resolve_pointer(rig, false)


func refresh_after_cross_swap(iface) -> void:
	var rig = _get_rig(iface)
	if !rig:
		return
	_await_then_resolve(rig)


func refresh_after_attach(iface) -> void:
	var rig = _get_rig(iface)
	if !rig:
		return
	# Magazine_Attach_* paths: gun had no mag visible. rig.magazine points at the
	# (hidden) native mesh. Swap the pointer now so the vanilla magazine.show()
	# at the tail of WeaponRig.Reload reveals the foreign overlay instead.
	_resolve_pointer(rig, false)


func _get_rig(iface):
	if !iface || !iface.rigManager:
		return null
	var rm: Node = iface.rigManager
	if rm.get_child_count() == 0:
		return null
	var rig := rm.get_child(rm.get_child_count() - 1)
	if !rig || !rig.has_meta(OVERLAYS_KEY):
		return null
	return rig


func _await_then_resolve(rig) -> void:
	var tree: SceneTree = rig.get_tree()
	if !tree:
		return
	await tree.create_timer(SWAP_DELAY, false).timeout
	if !is_instance_valid(rig):
		return
	_resolve_pointer(rig, true)


func _resolve_pointer(rig, transfer_visibility: bool) -> void:
	var native: MeshInstance3D = rig.get_meta(NATIVE_KEY)
	var overlays: Dictionary = rig.get_meta(OVERLAYS_KEY)
	var mag_file := _get_loaded_mag_file(rig)
	var target: MeshInstance3D = overlays.get(mag_file, native)
	if !target || rig.magazine == target:
		return
	var was_visible: bool = rig.magazine.visible if rig.magazine else false
	if rig.magazine:
		rig.magazine.hide()
	rig.magazine = target
	if transfer_visibility && was_visible:
		target.show()


# Non-uniform scale of factor k along unit axis n: I + (k-1) * (n outer n).
func _scale_along_axis(n: Vector3, k: float) -> Basis:
	var m := k - 1.0
	return Basis(
		Vector3(1.0 + m * n.x * n.x, m * n.x * n.y, m * n.x * n.z),
		Vector3(m * n.x * n.y, 1.0 + m * n.y * n.y, m * n.y * n.z),
		Vector3(m * n.x * n.z, m * n.y * n.z, 1.0 + m * n.z * n.z)
	)


func _find_mag_bone(skeleton: Skeleton3D) -> String:
	for child in skeleton.get_children():
		if child is BoneAttachment3D && child.name == "Ammo_Magazine":
			return child.bone_name
	return ""


func _get_loaded_mag_file(rig) -> String:
	if !rig.slotData:
		return ""
	for nested in rig.slotData.nested:
		if nested.subtype == "Magazine":
			return nested.file
	return ""
