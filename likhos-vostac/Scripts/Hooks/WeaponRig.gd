extends RefCounted

const Out := preload("../../Lib/Out.gd")
const WeaponRig_Fire := preload("../Nodes/WeaponRig_Fire.gd")
const WeaponRig_Reload := preload("../Nodes/WeaponRig_Reload.gd")
const WeaponRig_ManualReload := preload("../Nodes/WeaponRig_ManualReload.gd")
const WeaponRig_Optic := preload("../Nodes/WeaponRig_Optic.gd")
const WeaponRig_Inspect := preload("../Nodes/WeaponRig_Inspect.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_ready_post() -> void:
	var rig: WeaponRig = _lib._caller
	if !rig:
		return
	Out.debug("WeaponRig: injecting handlers")
	_inject_handler(rig, WeaponRig_Fire, "Likho_WeaponRig_Fire")
	_inject_handler(rig, WeaponRig_Reload, "Likho_WeaponRig_Reload")
	_inject_handler(rig, WeaponRig_ManualReload, "Likho_WeaponRig_ManualReload")
	_inject_handler(rig, WeaponRig_Optic, "Likho_WeaponRig_Optic")
	_inject_handler(rig, WeaponRig_Inspect, "Likho_WeaponRig_Inspect")


func _inject_handler(rig: WeaponRig, klass: GDScript, node_name: String) -> void:
	var h: Node = klass.new()
	h.name = node_name
	rig.add_child(h)


func on_casing_eject_post() -> void:
	var rig: WeaponRig = _lib._caller
	if !rig:
		return
	# BUGFIX: always clear chamber flag when clearing casing
	if rig.data.weaponType == "Bolt":
		rig.slotData.chamber = false
