extends RefCounted

const Out := preload("../../Lib/Out.gd")
const AttachmentMounts := preload("../AttachmentMounts.gd")
const ScopeCatalog := preload("../ScopeCatalog.gd")
const SlotMeta := preload("./SlotMeta.gd")
const WeaponRig_Fire := preload("../Nodes/WeaponRig_Fire.gd")
const WeaponRig_Reload := preload("../Nodes/WeaponRig_Reload.gd")
const WeaponRig_ManualReload := preload("../Nodes/WeaponRig_ManualReload.gd")
const WeaponRig_Optic := preload("../Nodes/WeaponRig_Optic.gd")
const WeaponRig_Inspect := preload("../Nodes/WeaponRig_Inspect.gd")
const WeaponRig_Shadow := preload("../Nodes/WeaponRig_Shadow.gd")

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
	_inject_handler(rig, WeaponRig_Shadow, "Likho_WeaponRig_Shadow")
	AttachmentMounts.mount(rig.attachments, rig.data.file, "rig", rig)
	# vanilla _ready clears the secondary sight choice, so the weapon's own choice is restored over it.
	# activeOptic is not set yet, so the RigManager.UpdateRig post hook syncs the optic state.
	if rig.slotData:
		ScopeCatalog.gameData.secondaryOptic = rig.slotData.get_meta(SlotMeta.SECONDARY_OPTIC, false)


func _inject_handler(rig: WeaponRig, klass: GDScript, node_name: String) -> void:
	var h: Node = klass.new()
	h.name = node_name
	rig.add_child(h)


# an unknown scope keeps vanilla ADS, and with it the ADS hooks of other mods
func on_ads(_delta: float) -> void:
	var rig: WeaponRig = _lib._caller
	var optic = rig.activeOptic if rig else null
	if optic && ScopeCatalog.is_unknown(optic.attachmentData):
		return
	_lib.skip_super()


func on_casing_eject_post() -> void:
	var rig: WeaponRig = _lib._caller
	if !rig:
		return
	# BUGFIX: always clear chamber flag when clearing casing
	if rig.data.weaponType == "Bolt":
		rig.slotData.chamber = false
