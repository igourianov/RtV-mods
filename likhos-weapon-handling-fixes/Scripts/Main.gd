extends "../Lib/Main.gd"

const ModConfig = preload("./ModConfig.gd")
const Handling = preload("./Handling.gd")
const WeaponRig = preload("./WeaponRig.gd")
const Camera = preload("./Camera.gd")
const Controller = preload("./Controller.gd")
const _Noise = preload("./Noise.gd") # Noise is already take by something in global scope
const Tilt = preload("./Tilt.gd")
const HUD = preload("./HUD.gd")
const Recoil = preload("./Recoil.gd")
const Character = preload("./Character.gd")
const Optic = preload("./Optic.gd")
const Laser = preload("./Laser.gd")
const Flashlight = preload("./Flashlight.gd")


var _handling
var _weapon_rig
var _camera
var _controller
var _noise
var _tilt
var _hud
var _config
var _recoil
var _character
var _optic
var _laser
var _flashlight
var _item


func setup(lib):

	var preferences = Preferences.Load()

	_weapon_rig = WeaponRig.new(lib)
	_handling = Handling.new(lib, preferences)
	_camera = Camera.new(lib)
	_controller = Controller.new(lib)
	_noise = _Noise.new(lib, preferences)
	_tilt = Tilt.new(lib)
	_hud = HUD.new(lib)
	_recoil = Recoil.new(lib)
	_character = Character.new(lib)
	_optic = Optic.new(lib, preferences)
	_laser = Laser.new(lib)
	_flashlight = Flashlight.new(lib)

	register_hook("handling-weaponhandling", _handling.on_weapon_handling)
	register_hook("rigmanager-updaterig-post", _handling.on_rig_update_post)
	register_hook("weaponrig-_ready-post", _weapon_rig.on_ready_post)
	register_hook("weaponrig-ads", _noop)
	register_hook("weaponrig-_physics_process", _weapon_rig.on_physics_process)
	register_hook("weaponrig-_input", _noop)
	register_hook("camera-scopedof-post", _camera.on_scope_dof_post)
	register_hook("controller-movementstates", _controller.on_movement_states)
	register_hook("controller-_input", _controller.on_input)
	register_hook("noise-_physics_process-post", _noise.on_physics_process_post)
	register_hook("tilt-_physics_process-pre", _tilt.on_physics_process_pre)
	register_hook("hud-_ready-post", _hud.on_ready_post)
	register_hook("recoil-applyrecoil-post", _recoil.on_apply_recoil_post)
	register_hook("character-stamina", _character.on_stamina)
	register_hook("optic-_physics_process-pre", _optic.on_physics_process_pre)
	register_hook("laser-_input", _laser.on_input)
	register_hook("flashlight-_physics_process", _flashlight.on_physics_process)

	register_action("optic_zoom_in", "Optic Zoom In", _create_mouse_input(MOUSE_BUTTON_WHEEL_UP))
	register_action("optic_zoom_out", "Optic Zoom Out", _create_mouse_input(MOUSE_BUTTON_WHEEL_DOWN))
	remove_action("ammo_check")
	remove_action("insert")


func _noop(_arg = null) -> void:
	_lib.skip_super()


func _create_mouse_input(button: int) -> InputEventMouseButton:
	var input = InputEventMouseButton.new()
	input.button_index = button
	input.pressed = true
	return input


func load_config(config: ConfigFile):
	ModConfig.apply_config(config)


func create_config(config: ConfigFile):
	ModConfig.create_template(config)
