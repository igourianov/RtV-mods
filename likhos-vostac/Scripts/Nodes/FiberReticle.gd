extends Node

# Glows a fiber lit reticle by the light on its collector, plus the faint glow of its tritium lamp.
# Lives as long as the mod, so the probe is never freed with a rig while a readback is in flight.

const ScopeCatalog := preload("../ScopeCatalog.gd")
const LightProbe := preload("../../Lib/LightProbe.gd")
const _RIG_MANAGER := "/root/Map/Core/Camera/Manager"
# Tunable: reticle glow per unit of light on the fiber collector.
const FIBER_GAIN := 0.8
# Tunable: light the tritium lamp adds to the fiber's, all the reticle has in full darkness.
const TRITIUM := 0.0005

var _rig_manager: Node
# Light on the fiber collector atop the housing.
var _probe := LightProbe.new([LightProbe.Sample.new(Vector3.UP)] as Array[LightProbe.Sample])


func _init() -> void:
	add_child(_probe)


func _process(_delta: float) -> void:
	# The probe renders only while a fiber lit sight is in hands.
	_probe.set_process(false)
	if !is_instance_valid(_rig_manager):
		_rig_manager = get_node_or_null(_RIG_MANAGER)
	if !_rig_manager || _rig_manager.get_child_count() == 0:
		return

	# the last child, as vanilla UpdateRig reads it; other mods park their own nodes in front of the rig
	var rig := _rig_manager.get_child(-1) as WeaponRig
	var optic = rig.activeOptic if rig else null
	if !optic || !optic.reticle || !ScopeCatalog.is_fiber_lit(optic.attachmentData):
		return
	_probe.set_process(true)

	var mesh: MeshInstance3D = optic.mesh
	var bounds := mesh.global_transform * mesh.get_aabb()
	var center := bounds.get_center()
	_probe.origin = Vector3(center.x, bounds.end.y + 0.01, center.z)
	# The lens also lights its reticle as albedo by `intensity`, which would count the scene's light twice.
	optic.reticle.set_shader_parameter("intensity", 0.0)
	optic.reticle.set_shader_parameter("glow", FIBER_GAIN * (_probe.luminance(0) + TRITIUM))
