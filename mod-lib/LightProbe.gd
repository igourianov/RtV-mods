extends SubViewport

# Reads the light the renderer puts on a point of the world.
# One small quad per Sample, lit and shadowed by the shared world, is rendered by a camera of this viewport and read back without stalling the GPU.
# A reading is the linear lit color of a white surface, ready in `readings` a frame or two after its render.

class Sample:
	# World space direction the sampled surface faces. Light counts by its angle to it.
	var normal := Vector3.UP
	var shadows := true
	# Also counts light arriving from behind, as a spatial shader's BACKLIGHT does.
	var backlight := false

	func _init(normal := Vector3.UP, shadows := true, backlight := false) -> void:
		self.normal = normal
		self.shadows = shadows
		self.backlight = backlight

enum _Phase { IDLE, RENDERING, READING }

const _QUAD_SIZE := 0.01
const _CAMERA_DISTANCE := 0.05
# Luminance weights of linear sRGB.
const LUMA := Vector3(0.2126, 0.7152, 0.0722)

var origin: Vector3
# The camera's view direction onto the quads. It decides nothing about the light, each sample's normal does.
var view := Vector3.DOWN
# Seconds between renders.
var interval := 0.25
var samples: Array[Sample]
var readings := PackedColorArray()

var _camera := Camera3D.new()
var _quads: Array[MeshInstance3D] = []
var _phase := _Phase.IDLE
# Starts due, so the first reading does not wait out a whole interval.
var _elapsed := INF


func _init(samples: Array[Sample]) -> void:
	self.samples = samples
	size = Vector2i(samples.size(), 1)
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	# Half floats, so readings above 1 and below 1/255 survive.
	use_hdr_2d = true
	readings.resize(samples.size())

	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.size = _QUAD_SIZE
	_camera.near = 0.001
	_camera.far = _CAMERA_DISTANCE * 2.0
	# Exposure 1 and no auto exposure, whatever the world's camera attributes.
	_camera.attributes = CameraAttributesPractical.new()
	add_child(_camera)

	for sample in samples:
		var mesh := QuadMesh.new()
		mesh.size = Vector2(_QUAD_SIZE, _QUAD_SIZE)
		var quad := MeshInstance3D.new()
		quad.mesh = mesh
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = Shader.new()
		material.shader.code = _shader_code(sample)
		quad.material_override = material
		_quads.append(quad)
		add_child(quad)


func _ready() -> void:
	world_3d = get_tree().root.find_world_3d()
	_camera.current = true
	RenderingServer.frame_post_draw.connect(_read_back)


func _process(delta: float) -> void:
	_elapsed += delta
	if _phase != _Phase.IDLE || _elapsed < interval:
		return
	_elapsed = 0.0

	# Quads side by side, facing the camera that looks at them along `view`.
	var up := Vector3.FORWARD if absf(view.dot(Vector3.UP)) > 0.99 else Vector3.UP
	var basis := Basis.looking_at(view, up)
	_camera.global_transform = Transform3D(basis, origin - view * _CAMERA_DISTANCE)
	for i in _quads.size():
		var offset := (i - (_quads.size() - 1) * 0.5) * _QUAD_SIZE
		_quads[i].global_transform = Transform3D(basis, origin + basis.x * offset)
		var material := _quads[i].material_override as ShaderMaterial
		material.set_shader_parameter("probe_camera", _camera.global_position)
		material.set_shader_parameter("surface_normal", samples[i].normal)

	# The world's environment as it is now, minus everything that is not light on a surface.
	var env := world_3d.environment if world_3d.environment else world_3d.fallback_environment
	if env:
		env = env.duplicate()
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.tonemap_exposure = 1.0
		env.glow_enabled = false
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.ssao_enabled = false
		env.ssil_enabled = false
		env.ssr_enabled = false
		env.adjustment_enabled = false
	_camera.environment = env

	render_target_update_mode = SubViewport.UPDATE_ONCE
	_phase = _Phase.RENDERING


# After the frame that rendered the probe, asks the GPU for its pixels.
func _read_back() -> void:
	if _phase != _Phase.RENDERING:
		return
	_phase = _Phase.READING
	var texture := RenderingServer.texture_get_rd_texture(get_texture().get_rid())
	# RenderingDevice calls belong to the render thread. The callback runs there too.
	RenderingServer.call_on_render_thread(func() -> void:
		RenderingServer.get_rendering_device().texture_get_data_async(texture, 0, func(data: PackedByteArray) -> void:
			_store.call_deferred(data)
		)
	)


func _store(data: PackedByteArray) -> void:
	var stride := data.size() / readings.size()
	for i in readings.size():
		var at := i * stride
		if stride == 8:
			readings[i] = Color(data.decode_half(at), data.decode_half(at + 2), data.decode_half(at + 4))
		else:
			readings[i] = Color8(data[at], data[at + 1], data[at + 2]).srgb_to_linear()
	_phase = _Phase.IDLE


func luminance(index: int) -> float:
	var reading := readings[index]
	return LUMA.dot(Vector3(reading.r, reading.g, reading.b))


static func _shader_code(sample: Sample) -> String:
	var code := "shader_type spatial;\n"
	if !sample.shadows:
		code += "render_mode shadows_disabled;\n"
	code += """
uniform vec3 probe_camera;
uniform vec3 surface_normal = vec3(0.0, 1.0, 0.0);

void fragment()
{
	// The quads share the game's world. Only the probe's own camera sees them.
	if (distance(CAMERA_POSITION_WORLD, probe_camera) > 0.001)
	{
		discard;
	}
	// Lit as the sampled surface, whichever way the quad faces the camera.
	NORMAL = normalize((VIEW_MATRIX * vec4(surface_normal, 0.0)).xyz);
	ALBEDO = vec3(1.0);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
"""
	if sample.backlight:
		code += "\tBACKLIGHT = vec3(1.0);\n"
	code += "}\n"
	return code
