extends RefCounted

const Out = preload("../Lib/Out.gd")
const WeaponRig_Reload = preload("./WeaponRig_Reload.gd")
const WeaponRig_ManualReload = preload("./WeaponRig_ManualReload.gd")
const WeaponRig_Optic = preload("./WeaponRig_Optic.gd")
const WeaponRig_Inspect = preload("./WeaponRig_Inspect.gd")

var gameData = preload("res://Resources/GameData.tres")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_ready_post() -> void:
	var rig = _lib._caller
	if rig == null:
		return
	Out.debug("WeaponRig: injecting handlers")
	_inject_handler(rig, WeaponRig_Reload, "Likho_WeaponRig_Reload")
	_inject_handler(rig, WeaponRig_ManualReload, "Likho_WeaponRig_ManualReload")
	_inject_handler(rig, WeaponRig_Optic, "Likho_WeaponRig_Optic")
	_inject_handler(rig, WeaponRig_Inspect, "Likho_WeaponRig_Inspect")


func _inject_handler(rig, klass, node_name: String) -> void:
	var h = klass.new()
	h.name = node_name
	rig.add_child(h)
	h.owner = rig
	h.set_process_input(true)
	h.set_process(true)


func on_physics_process(delta: float) -> void:
	var rig = _lib._caller
	if rig == null:
		return
	_lib.skip_super()

	if _is_busy() || gameData.isReloading || gameData.isClearing || gameData.isInserting || gameData.isInspecting:
		return

	rig.FireInput()
	rig.FireTimer(delta)
	rig.FireImpulse(delta)


func _is_busy() -> bool:
	return (gameData.freeze
		|| gameData.isDead
		|| gameData.isPlacing
		|| gameData.isDrawing
		|| gameData.isCaching
		|| gameData.isTransitioning
		|| gameData.isOccupied)
