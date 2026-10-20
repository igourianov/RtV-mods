extends "./WeaponRig_Base.gd"

const Sway := preload("res://Scripts/Sway.gd")

# Response to the summed misalignment angle, in degrees, and its reach in lens UV (lens width 1.0).
const _DEAD_ZONE := 1.0
const _FULL_ANGLE := 5.0
const _MAX_REACH := 0.6
# Total, in degrees, of each channel's random turn, rolled each time aiming starts.
const _SPREAD := 45.0
# Per second.
const _EXHAUSTION_RATE := 1.0


class Channel:
	# Reads the source in its own units, as view space x and y.
	var read: Callable
	# Per second. A transient channel reads its source minus a follower easing at this rate, a level channel has none.
	var rate: Callable
	# Degrees per source unit, signed so the angle points where the clear aperture shifts.
	var gain: float
	# Soft cap, in degrees, so a source driven past its usual range, such as a lean switched straight to the other side, does not grow in proportion.
	var cap: float
	var follower: Vector2
	var turn := 0.0

	func _init(p_read: Callable, p_rate: Callable, p_gain: float, p_cap: float) -> void:
		read = p_read
		rate = p_rate
		gain = p_gain
		cap = p_cap
		follower = read.call()


var _rig: WeaponRig
var _sway: Sway
var _noise: Node3D
var _impulse: Node3D
var _handling: Node3D
var _pelvis: Node3D
var _exhaustion := 0.0
var _was_aiming := false
var _channels: Array[Channel]


func _ready() -> void:
	# injected in the rig's _ready, so its node tree is complete
	_rig = get_parent()
	_handling = _rig.get_node("Handling")
	_sway = _rig.get_node("Handling/Sway")
	_noise = _rig.get_node("Handling/Sway/Noise")
	_impulse = _rig.get_node("Handling/Sway/Noise/Tilt/Impulse")
	_pelvis = get_node("/root/Map/Core/Controller/Pelvis")
	# The exhausted wobble and the crouch or stand kick peak around the dead zone on their own, so they count three times over.
	# Swing, exhaustion and stance cap well above the full reach angle, so the cap barely touches their tuned response.
	# Lean and aim signs were settled in game: the lean crescent comes from the side opposite the lean, the aim crescent from the side the rig travels toward.
	_channels = [
		Channel.new(func() -> Vector2: return _rotation_view(_sway.rotation_degrees - _sway.originalRotation), Callable(), 1.0, 10.0),
		Channel.new(func() -> Vector2: return _rotation_view(_noise.rotation_degrees) * _exhaustion, Callable(), 3.0, 10.0),
		Channel.new(func() -> Vector2: return _rotation_view(_impulse.rotation_degrees), Callable(), 3.0, 10.0),
		# The lean rolls positive to the left, and the rig rolls with it, so view space x stays lens x.
		Channel.new(func() -> Vector2: return Vector2(_pelvis.rotation_degrees.z, 0.0), func() -> float: return _pelvis.leanSpeed, 0.6, 3.2),
		Channel.new(func() -> Vector2: return Vector2(_handling.position.x, _handling.position.y), func() -> float: return config.current_handling_rate, -285.0, 4.5),
	]
	set_process(true)


# Pitch and yaw as x the yaw, y the pitch, in view space with y up.
# A yaw to the right tilts the lens normal left, and vanilla's view ray plus normal offset then clears the right side.
static func _rotation_view(rotation: Vector3) -> Vector2:
	return Vector2(-rotation.y, rotation.x)


func _process(delta: float) -> void:
	var offset := _update_offset(delta)
	var optic = _rig.activeOptic
	if !optic || !optic.reticle || !optic.attachmentData:
		return
	if optic.attachmentData.scope || optic.attachmentData.variable:
		optic.reticle.set_shader_parameter("shadow_offset", offset)


# Advances the channels, so followers track their source outside ADS too.
# Returns the clear aperture's shift in lens UV, zero unless aiming with a magnified optic.
func _update_offset(delta: float) -> Vector2:
	_exhaustion = move_toward(_exhaustion, 1.0 if gameData.armStamina <= 0.0 else 0.0, delta * _EXHAUSTION_RATE)

	var aiming: bool = gameData.isAiming
	if aiming && !_was_aiming:
		for channel in _channels:
			channel.turn = deg_to_rad(randf_range(-0.5, 0.5) * _SPREAD)
	_was_aiming = aiming

	var misalignment := Vector2.ZERO
	for channel in _channels:
		var reading: Vector2 = channel.read.call()
		if channel.rate.is_valid():
			channel.follower = channel.follower.lerp(reading, delta * channel.rate.call())
			reading -= channel.follower
		var angle := reading * channel.gain
		misalignment += angle.normalized().rotated(channel.turn) * tanh(angle.length() / channel.cap) * channel.cap

	if !aiming || !gameData.isScoped:
		return Vector2.ZERO

	var magnitude := misalignment.length()
	if magnitude <= _DEAD_ZONE:
		return Vector2.ZERO
	var reach := clampf(inverse_lerp(_DEAD_ZONE, _FULL_ANGLE, magnitude), 0.0, 1.0) * _MAX_REACH
	# Lens UV runs y down.
	return misalignment / magnitude * reach * Vector2(1.0, -1.0)
