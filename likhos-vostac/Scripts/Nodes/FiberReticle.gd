extends Node

# Glows a fiber lit reticle by the light on its collector, never below the faint glow of its tritium lamp.
# Lives as long as the mod, so the probe is never freed with a rig while a readback is in flight.

const ScopeCatalog := preload("../ScopeCatalog.gd")
const LightProbe := preload("../../Lib/LightProbe.gd")
const _RIG_MANAGER := "/root/Map/Core/Camera/Manager"
# Tunable: reticle glow per unit of light on the fiber collector.
const FIBER_GAIN := 0.8
# Tunable: glow of the tritium lamp, the least the reticle shows however dark it gets.
const TRITIUM := 0.0004

var _rig_manager: Node
# Light on the fiber collector atop the housing.
var _probe := LightProbe.new([LightProbe.Sample.new(Vector3.UP)] as Array[LightProbe.Sample])
# Eased toward each reading, so the probe's 4 Hz updates do not show as steps.
var _glow := 0.0


func _init() -> void:
	add_child(_probe)


func _process(delta: float) -> void:
	# A map being left is out of the tree before it is freed, and its rig has no global transform.
	if !is_instance_valid(_rig_manager) || !_rig_manager.is_inside_tree():
		_rig_manager = get_node_or_null(_RIG_MANAGER)
	# the last child, as vanilla UpdateRig reads it; other mods park their own nodes in front of the rig
	var rig: WeaponRig = _rig_manager.get_child(-1) as WeaponRig if _rig_manager && _rig_manager.get_child_count() > 0 else null
	var optic = rig.activeOptic if rig else null
	var fiber: bool = optic && optic.reticle && ScopeCatalog.is_fiber_lit(optic.attachmentData)
	# The probe renders only while a fiber lit sight is in hands.
	_probe.set_process(fiber)
	if !fiber:
		# The next fiber sight in hands fades in from dark, not from the light this one last saw.
		_glow = 0.0
		return

	var mesh: MeshInstance3D = optic.mesh
	var bounds := mesh.global_transform * mesh.get_aabb()
	var center := bounds.get_center()
	_probe.origin = Vector3(center.x, bounds.end.y + 0.01, center.z)
	# The lens also lights its reticle as albedo by `intensity`, which would count the scene's light twice.
	optic.reticle.set_shader_parameter("intensity", 0.0)
	# Covers most of a step, about 85%, within one probe interval.
	_glow = lerpf(_glow, maxf(FIBER_GAIN * _probe.luminance(0), TRITIUM), minf(delta * 8.0, 1.0))
	optic.reticle.set_shader_parameter("glow", _glow)
