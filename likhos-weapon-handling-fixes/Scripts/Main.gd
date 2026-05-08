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


func setup(lib):

	var preferences = Preferences.Load()
	
	_weapon_rig = WeaponRig.new(lib, preferences)
	_handling = Handling.new(lib, preferences)
	_camera = Camera.new(lib)
	_controller = Controller.new(lib, _weapon_rig)
	_noise = _Noise.new(lib, preferences)
	_tilt = Tilt.new(lib)
	_hud = HUD.new(lib)
	_recoil = Recoil.new(lib)
	_character = Character.new(lib)
	_optic = Optic.new(lib, preferences)

	register_hook("handling-weaponhandling", _handling.on_weapon_handling)
	register_hook("rigmanager-updaterig-post", _handling.on_rig_update_post)
	register_hook("weaponrig-ammocheck-pre", _weapon_rig.on_ammo_check_pre)
	register_hook("weaponrig-ammocheck-post", _weapon_rig.on_ammo_check_post)
	register_hook("weaponrig-ads-post", _weapon_rig.on_ads_post)
	register_hook("weaponrig-_input", _weapon_rig.on_input)
	register_hook("weaponrig-_physics_process-pre", _weapon_rig.on_physics_process_pre)
	register_hook("weaponrig-updateaimoffset", _weapon_rig.on_update_aim_offset)
	register_hook("weaponrig-insert-post", _weapon_rig.on_insert_post)
	register_hook("camera-scopedof-post", _camera.on_scope_dof_post)
	register_hook("controller-movementstates-pre", _controller.on_movement_states_pre)
	register_hook("controller-movementstates-post", _controller.on_movement_states_post)
	register_hook("controller-_input", _controller.on_input)
	register_hook("noise-_physics_process-post", _noise.on_physics_process_post)
	register_hook("tilt-_physics_process-pre", _tilt.on_physics_process_pre)
	register_hook("hud-_ready-post", _hud.on_ready_post)
	register_hook("recoil-applyrecoil-post", _recoil.on_apply_recoil_post)
	register_hook("character-stamina", _character.on_stamina)
	register_hook("optic-_physics_process-pre", _optic.on_physics_process_pre)

	var zoomIn = InputEventMouseButton.new()
	zoomIn.button_index = MOUSE_BUTTON_WHEEL_UP
	zoomIn.pressed = true
	register_action("optic_zoom_in", "Optic Zoom In", zoomIn)

	var zoomOut = InputEventMouseButton.new()
	zoomOut.button_index = MOUSE_BUTTON_WHEEL_DOWN
	zoomOut.pressed = true
	register_action("optic_zoom_out", "Optic Zoom Out", zoomOut)


func load_config(config: ConfigFile):
	ModConfig.apply_config(config)


func create_config(config: ConfigFile):
	ModConfig.create_template(config)