extends Node

const Config := preload("./Config.gd")
const BatteryUtil := preload("./BatteryUtil.gd")
const Flicker := preload("./Flicker.gd")
const AudioChunkPlayer := preload("../Lib/AudioChunkPlayer.gd")
const _RETICLE_SHADER := preload("res://mods/likhos-battery/Shaders/Reticle.gdshader")
const _FIBER_SHADER := preload("res://mods/likhos-battery/Shaders/FiberReticle.gdshader")
const _CLICK_AUDIO := preload("res://Audio/Character/Handling/Files/Gadget.wav")
const _CLICK_VOLUME := -10.0
const _RIG_MANAGER := "/root/Map/Core/Camera/Manager"
# slotData meta: the weapon's manual illumination switch.
# Vanilla SlotData.Update copies no meta, so a map transition, a load or a drop and pick up resets it.
const _LIT_META := &"reticle_lit"
# Simulation.time values at which vanilla World.TOD swaps the sun for the moon.
const _SUNRISE := 600.0
const _SUNSET := 1800.0
# Tunable: how much faster a lit scope drains for carrying a second dot.
const SECONDARY_DRAIN := 1.25

# What a sight powers.
# DOT: the dot of a red dot sight, always on.
# SCOPE: illumination of the texels the reticle texture authors red.
# SCOPE_WHOLE: illumination of the whole reticle, for a texture that authors nothing red.
# SCOPE_DOT: a SCOPE that also carries an always-on dot on a lens surface of its own.
# FIBER: a reticle lit by the light around the scope, with a tritium floor. Draws no power and has no switch.
enum Sight { DOT, SCOPE, SCOPE_WHOLE, SCOPE_DOT, FIBER }
# What the reticle pass draws. The values are the `state` uniform of Reticle.gdshader.
enum Reticle { NONE, UNLIT, LIT, LIT_WHOLE }

# By item file. A sight that is not listed draws no power and is left as vanilla or VosTac draws it.
const SIGHTS: Dictionary[String, Sight] = {
	"SRO": Sight.DOT,
	"RMR": Sight.DOT,
	"PRO": Sight.DOT,
	"MRO": Sight.DOT,
	"Micro": Sight.DOT,
	"EXPS": Sight.DOT,
	"Kobra": Sight.DOT,
	"Vudu": Sight.SCOPE,
	"Leopard": Sight.SCOPE,
	"POSP": Sight.SCOPE_WHOLE,
	"HMR": Sight.SCOPE_DOT,
	"ACOG": Sight.FIBER,
}

var gameData := preload("res://Resources/GameData.tres")
var config := Config.instance

var _rig_manager: Node
var _click := AudioChunkPlayer.new(_CLICK_AUDIO, _CLICK_VOLUME)
var _blank := ImageTexture.create_from_image(Image.create_empty(1, 1, false, Image.FORMAT_RGBA8))
# One sight is live at a time, so the flicker state is kept once.
var _flicker := Flicker.new()
# Physics frame of the last flicker step, and whether that step was a dip.
var _step_frame: int
var _dip: bool


func _init() -> void:
	add_child(_click)


func _input(event: InputEvent) -> void:
	if !event.is_action_pressed("reticle_illumination") || config.scope_power_draw != Config.ScopePowerDraw.MANUAL:
		return
	if gameData.freeze || gameData.isDead || gameData.interface || gameData.settings || gameData.isTransitioning || gameData.isCaching:
		return

	var rig := _sighted_rig()
	var optic = rig.activeOptic if rig else null
	if !optic || SIGHTS[optic.attachmentData.file] in [Sight.DOT, Sight.FIBER]:
		return

	var slotData: SlotData = rig.slotData
	var lit: bool = !slotData.get_meta(_LIT_META, false)
	slotData.set_meta(_LIT_META, lit)
	# Two chunks of the vanilla gadget sound: its press and its release.
	if lit:
		_click.play_chunk(0.0, 0.015)
	else:
		_click.play_chunk(0.120)


func _process(delta: float) -> void:
	var rig := _sighted_rig()
	if !rig:
		return

	var optic = rig.activeOptic
	var item: ItemData = optic.attachmentData
	var sight: Sight = SIGHTS[item.file]
	if sight == Sight.FIBER:
		# The renderer lights the pass, so there is no state to push beyond its placement.
		_reticle_pass(optic.reticle, _FIBER_SHADER)
		return

	# A consumer whose setting is DISABLED draws no power and shows as authored, whatever the charge.
	var scope_on_battery: bool = sight != Sight.DOT && config.scope_power_draw != Config.ScopePowerDraw.DISABLED
	var dot_on_battery: bool = (sight == Sight.DOT || sight == Sight.SCOPE_DOT) && config.red_dot_power_draw != Config.RedDotPowerDraw.DISABLED
	var lit: bool = scope_on_battery && _illumination_on(rig)

	# A dot draws power whenever the weapon is in hands, scope illumination while it is on.
	var powered := false
	if lit || dot_on_battery:
		var rate := BatteryUtil.drain_rate(item.power)
		# A scope with a second dot runs the dot alone at the dot tier's rate, and both at its own rate times the multiplier.
		if sight == Sight.SCOPE_DOT && !lit:
			rate = BatteryUtil.drain_rate(BatteryUtil.POWER_DOT)
		elif sight == Sight.SCOPE_DOT && dot_on_battery:
			rate *= SECONDARY_DRAIN
		powered = _draw_power(rig.slotData, item, rate, delta)

	var dot: Reticle = Reticle.LIT if powered || !dot_on_battery else Reticle.NONE
	var illuminated: bool = lit && powered
	var scope: Reticle = Reticle.LIT
	if scope_on_battery && !illuminated:
		scope = Reticle.UNLIT
	elif scope_on_battery && sight == Sight.SCOPE_WHOLE:
		scope = Reticle.LIT_WHOLE
	_push(optic.reticle, dot if sight == Sight.DOT else scope, illuminated)

	if sight == Sight.SCOPE_DOT:
		# The second dot is one more surface of the scope's mesh, with a lens material that is not `optic.reticle`.
		var mesh: MeshInstance3D = optic.mesh
		for surface in mesh.get_surface_override_material_count():
			var lens := mesh.get_surface_override_material(surface) as ShaderMaterial
			if lens && lens != optic.reticle && lens.get_shader_parameter("reticle"):
				_push(lens, dot, false)


# Whether the weapon's scope illumination is on: by its own switch, or by the clock with the light sensor.
func _illumination_on(rig: WeaponRig) -> bool:
	if config.scope_power_draw == Config.ScopePowerDraw.MANUAL:
		return rig.slotData.get_meta(_LIT_META, false)
	# Night by the clock. Shelters are lit from the inside and never run the day cycle.
	return !gameData.shelter && (Simulation.time < _SUNRISE || Simulation.time > _SUNSET)


# Drains the sight for this frame at the given rate. True while it has charge left and is not inside a low charge flicker dip.
func _draw_power(weapon: SlotData, item: ItemData, rate: float, delta: float) -> bool:
	var holder := BatteryUtil.attachment_holder(weapon, item)
	if holder.condition > 0:
		holder.condition -= delta * rate

	if holder.condition <= 0:
		return false

	var frame := Engine.get_physics_frames()
	if frame - _step_frame >= Flicker.STEP_FRAMES:
		_step_frame = frame
		_dip = _flicker.step(holder.condition)
	return !_dip


# The weapon in hands, if its active optic is a listed sight.
func _sighted_rig() -> WeaponRig:
	if !is_instance_valid(_rig_manager):
		_rig_manager = get_node_or_null(_RIG_MANAGER)
	if !_rig_manager || _rig_manager.get_child_count() == 0:
		return null

	var rig := _rig_manager.get_child(0) as WeaponRig
	var optic = rig.activeOptic if rig && rig.slotData else null
	if !optic || !optic.reticle || !SIGHTS.has(optic.attachmentData.file):
		return null
	return rig


# A lens material is shared by every instance of its sight, so the weapon in hands pushes its state each frame.
func _push(lens: ShaderMaterial, state: Reticle, rim_glow: bool) -> void:
	var reticle := _reticle_pass(lens, _RETICLE_SHADER)
	reticle.set_shader_parameter("intensity", lens.get_shader_parameter("intensity"))
	reticle.set_shader_parameter("state", state)
	reticle.set_shader_parameter("rim_glow", rim_glow)


# The reticle pass of a lens on the given shader, placed for the frame.
func _reticle_pass(lens: ShaderMaterial, shader: Shader) -> ShaderMaterial:
	var reticle := lens.next_pass as ShaderMaterial
	if !reticle || reticle.shader != shader:
		reticle = ShaderMaterial.new()
		reticle.shader = shader
		for parameter: String in ["scope", "reticle"]:
			reticle.set_shader_parameter(parameter, lens.get_shader_parameter(parameter))
		# Godot orders the passes of a surface by priority, not by the chain. The reticle goes over the lens and its shadow.
		reticle.render_priority = lens.render_priority + 1
		lens.next_pass = reticle
		# The lens shader goes on drawing glass, shadow and reflection, and no reticle of its own.
		lens.set_shader_parameter("reticle", _blank)

	# Vanilla or VosTac wrote these two for the frame.
	reticle.set_shader_parameter("size", lens.get_shader_parameter("size"))
	reticle.set_shader_parameter("opacity", lens.get_shader_parameter("opacity"))
	# VosTac sets it on the lens materials it places from the lens UV. Absent, the pass keeps vanilla's placement.
	reticle.set_shader_parameter("lens_uv_scale", lens.get_shader_parameter("lens_uv_scale"))
	return reticle
