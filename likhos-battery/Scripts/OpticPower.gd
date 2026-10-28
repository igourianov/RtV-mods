extends Node

const Config := preload("./Config.gd")
const BatteryUtil := preload("./BatteryUtil.gd")
const Flicker := preload("./Flicker.gd")
const AudioChunkPlayer := preload("../Lib/AudioChunkPlayer.gd")
const _RIM_SHADER := preload("res://mods/likhos-battery/Shaders/RimGlow.gdshader")
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
enum Sight { DOT, SCOPE, SCOPE_WHOLE, SCOPE_DOT }
# What a lens draws for its reticle.
enum ReticleState { NONE, UNLIT, LIT, LIT_WHOLE }

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
}

# A lens material's own reticle and intensity, kept before the first state push overwrites them.
class Authored:
	var reticle: Texture2D
	var intensity: float
	# The reticle with every opaque texel red, for a SCOPE_WHOLE sight. A worker thread builds it into `whole_image`.
	var whole: Texture2D
	var whole_image: Image
	var whole_task := -1

var gameData := preload("res://Resources/GameData.tres")
var config := Config.instance

var _rig_manager: Node
var _click := AudioChunkPlayer.new(_CLICK_AUDIO, _CLICK_VOLUME)
var _blank := ImageTexture.create_from_image(Image.create_empty(1, 1, false, Image.FORMAT_RGBA8))
var _authored: Dictionary[ShaderMaterial, Authored] = {}
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
	if !optic || SIGHTS[optic.attachmentData.file] == Sight.DOT:
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

	var dot: ReticleState = ReticleState.LIT if powered || !dot_on_battery else ReticleState.NONE
	var illuminated: bool = lit && powered
	# Null while the copy is being built, so the scope shows as authored until it is ready.
	var whole: Texture2D = _whole(optic.reticle) if sight == Sight.SCOPE_WHOLE else null
	var scope: ReticleState = ReticleState.LIT
	if scope_on_battery && !illuminated:
		scope = ReticleState.UNLIT
	elif scope_on_battery && whole:
		scope = ReticleState.LIT_WHOLE
	_push_state(optic.reticle, dot if sight == Sight.DOT else scope, illuminated, whole)

	if sight == Sight.SCOPE_DOT:
		# The second dot is one more surface of the scope's mesh, with a lens material that is not `optic.reticle`.
		var mesh: MeshInstance3D = optic.mesh
		for surface in mesh.get_surface_override_material_count():
			var lens := mesh.get_surface_override_material(surface) as ShaderMaterial
			if lens && lens != optic.reticle && lens.get_shader_parameter("reticle"):
				_push_state(lens, dot, false)


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

	# the last child, as vanilla UpdateRig reads it; other mods park their own nodes in front of the rig
	var rig := _rig_manager.get_child(-1) as WeaponRig
	var optic = rig.activeOptic if rig && rig.slotData else null
	if !optic || !optic.reticle || !SIGHTS.has(optic.attachmentData.file):
		return null
	return rig


# A lens material is shared by every instance of its sight, so the weapon in hands pushes its state each frame.
# The lens shader, vanilla's or another mod's, draws the reticle from these uniforms with its own placement, shadow and aim fade.
func _push_state(lens: ShaderMaterial, state: ReticleState, rim_glow: bool, whole: Texture2D = null) -> void:
	var authored := _authored_of(lens)
	var texture: Texture2D = authored.reticle
	var intensity: float = authored.intensity
	if state == ReticleState.NONE:
		texture = _blank
	elif state == ReticleState.UNLIT:
		# The lens shaders glow red texels by `intensity`. At 0 every texel is a black line.
		intensity = 0.0
	elif state == ReticleState.LIT_WHOLE:
		texture = whole
	lens.set_shader_parameter("reticle", texture)
	lens.set_shader_parameter("intensity", intensity)

	var rim := lens.next_pass as ShaderMaterial
	if !rim || rim.shader != _RIM_SHADER:
		rim = ShaderMaterial.new()
		rim.shader = _RIM_SHADER
		# Godot orders the passes of a surface by priority, not by the chain.
		rim.render_priority = lens.render_priority + 1
		lens.next_pass = rim
	rim.set_shader_parameter("opacity", lens.get_shader_parameter("opacity"))
	rim.set_shader_parameter("rim_glow", rim_glow)


# The reticle and intensity a lens material came with, kept the first time the mod meets it.
func _authored_of(lens: ShaderMaterial) -> Authored:
	var authored: Authored = _authored.get(lens)
	if !authored:
		authored = Authored.new()
		authored.reticle = lens.get_shader_parameter("reticle")
		authored.intensity = lens.get_shader_parameter("intensity")
		_authored[lens] = authored
	return authored


# The lens's reticle with every opaque texel red, or null until a worker thread has built it.
# Built from the texture on the lens, so a game update or another mod's replacement carries over.
func _whole(lens: ShaderMaterial) -> Texture2D:
	var authored := _authored_of(lens)
	if authored.whole || !authored.reticle:
		return authored.whole

	if authored.whole_task < 0:
		# The readback stays on the main thread, the work on the pixels goes to the worker.
		authored.whole_image = authored.reticle.get_image()
		authored.whole_task = WorkerThreadPool.add_task(_fill_red.bind(authored.whole_image))
	elif WorkerThreadPool.is_task_completed(authored.whole_task):
		WorkerThreadPool.wait_for_task_completion(authored.whole_task)
		authored.whole = ImageTexture.create_from_image(authored.whole_image)
		authored.whole_image = null
	return authored.whole


# Runs on a worker thread.
static func _fill_red(image: Image) -> void:
	# Imported reticles are VRAM compressed.
	image.decompress()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RGBA8)
	var data := image.get_data()
	for i in range(0, data.size(), 4):
		data[i] = 255
	image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, data)
	# Stays uncompressed. Export builds ship no BC compressor and Image.compress logs an error there.
	image.generate_mipmaps()
