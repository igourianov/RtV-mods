extends RefCounted

var gameData := preload("res://Resources/GameData.tres")

# local-space offset from the bone-tracked anchor toward the magazine body center
const _MAG_CENTER_OFFSET := Vector3(0, -0.05, 0)

var _lib
var _rig_manager: Node3D


func _init(lib) -> void:
	_lib = lib


# center the magazine ammo tooltip on the magazine body while inspecting
func on_physics_process_post(_delta: float) -> void:
	var node: Node3D = _lib._caller
	if !is_instance_valid(node) || node.type != node.Type.Magazine || !node.target:
		return
	if !gameData.isInspecting:
		return

	if !_rig_manager || !is_instance_valid(_rig_manager):
		_rig_manager = node.get_node_or_null("/root/Map/Core/Camera/Manager")
	var rig: Node = _rig_manager.get_child(0) if _rig_manager && _rig_manager.get_child_count() > 0 else null
	if !(rig is WeaponRig) || !rig.magazine || !rig.magazine.visible:
		return

	var anchor := node.global_position + node.global_transform.basis * _MAG_CENTER_OFFSET
	node.target.global_position = node.camera.unproject_position(anchor)
