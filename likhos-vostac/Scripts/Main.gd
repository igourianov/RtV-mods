extends "../Lib/Main.gd"

var LCM = load("res://mods/likhos-config-manager/Scripts/LCM.gd")
var config := preload("./Config.gd").instance
const Handling = preload("./Hooks/Handling.gd")
const WeaponRig = preload("./Hooks/WeaponRig.gd")
const Camera = preload("./Hooks/Camera.gd")
const Controller = preload("./Hooks/Controller.gd")
const _Noise = preload("./Hooks/Noise.gd") # Noise is already take by something in global scope
const Tilt = preload("./Hooks/Tilt.gd")
const HUD = preload("./Hooks/HUD.gd")
const Recoil = preload("./Hooks/Recoil.gd")
const Character = preload("./Hooks/Character.gd")
const Optic = preload("./Hooks/Optic.gd")
const Laser = preload("./Hooks/Laser.gd")
const Flashlight = preload("./Hooks/Flashlight.gd")
const NVG = preload("./Hooks/NVG.gd")
const ScopeCatalog = preload("./ScopeCatalog.gd")
const RigOpticPatches = preload("./RigOpticPatches.gd")
const WeaponPatches = preload("./WeaponPatches.gd")
const AttachmentMounts = preload("./AttachmentMounts.gd")
const Pickup = preload("./Hooks/Pickup.gd")
const LootContainer = preload("./Hooks/LootContainer.gd")
const Tooltip = preload("./Hooks/Tooltip.gd")
const Interactor = preload("./Hooks/Interactor.gd")
const UIPosition = preload("./Hooks/UIPosition.gd")
const Item = preload("./Hooks/Item.gd")
const KillCounter = preload("./Hooks/KillCounter.gd")
const SlotMeta = preload("./Hooks/SlotMeta.gd")
const BinocularsOverlay = preload("./Nodes/BinocularsOverlay.gd")
const InputBus = preload("./Nodes/InputBus.gd")
const FiberReticle = preload("./Nodes/FiberReticle.gd")


var _handling
var _weapon_rig
var _camera
var _controller
var _noise
var _tilt
var _hud
var _recoil
var _character
var _optic
var _laser
var _flashlight
var _nvg
var _tooltip
var _interactor
var _uiposition
var _binoculars
var _bus
var _item
var _kill_counter
var _pickup
var _loot_container
var _slot_meta


func setup(lib):

	# LCM reports only the values it loaded from its store, so Out is set up from the defaults here
	_on_config_applied()
	if is_instance_valid(LCM):
		LCM.register_config(mod_id, mod_name, config, _on_config_applied)

	ScopeCatalog.apply(lib)
	RigOpticPatches.apply(lib)
	WeaponPatches.apply(lib)
	AttachmentMounts.apply(lib)

	var preferences = Preferences.Load()

	_bus = InputBus.new()
	add_child(_bus)

	_weapon_rig = WeaponRig.new(lib)
	_handling = Handling.new(lib, _bus)
	_camera = Camera.new(lib)
	_controller = Controller.new(lib, _bus)
	_noise = _Noise.new(lib, _controller)
	_tilt = Tilt.new(lib)
	_hud = HUD.new(lib)
	_recoil = Recoil.new(lib)
	_character = Character.new(lib, _bus)
	_optic = Optic.new(lib, preferences)
	_laser = Laser.new(lib)
	_flashlight = Flashlight.new(lib)
	_nvg = NVG.new(lib)
	_tooltip = Tooltip.new(lib)
	_interactor = Interactor.new(lib)
	_uiposition = UIPosition.new(lib)
	_item = Item.new(lib)
	_kill_counter = KillCounter.new(lib)
	_pickup = Pickup.new(lib)
	_loot_container = LootContainer.new(lib)
	_slot_meta = SlotMeta.new(lib)

	register_hook("handling-weaponhandling", _handling.on_weapon_handling)
	# above the default priority 100, so it runs after other mods' post hooks
	register_hook("handling-weaponhandling-post", _handling.on_weapon_handling_post, 200)
	register_hook("handling-weaponposition", _handling.on_weapon_position)
	register_hook("rigmanager-updaterig-post", _handling.on_rig_update_post)
	register_hook("rigmanager-clearrig-post", _handling.on_clear_rig_post)
	register_hook("weaponrig-_ready-post", _weapon_rig.on_ready_post)
	register_hook("weaponrig-casingeject-post", _weapon_rig.on_casing_eject_post)
	register_hook("weaponrig-ads", _weapon_rig.on_ads)
	register_hook("weaponrig-_physics_process", noop)
	register_hook("weaponrig-_input", noop)
	register_hook("camera-dof", _camera.on_dof)
	register_hook("controller-movementstates", _controller.on_movement_states)
	register_hook("controller-_physics_process-post", _controller.on_physics_process_post)
	register_hook("controller-_input", _controller.on_input)
	register_hook("controller-crouch", _controller.on_crouch)
	register_hook("controller-headbob", _controller.on_headbob)
	register_hook("noise-_physics_process-post", _noise.on_physics_process_post)
	register_hook("tilt-_physics_process-pre", _tilt.on_physics_process_pre)
	register_hook("hud-_ready-post", _hud.on_ready_post)
	register_hook("hud-_physics_process-post", _hud.on_physics_process_post)
	register_hook("recoil-applyrecoil-post", _recoil.on_apply_recoil_post)
	register_hook("character-stamina", _character.on_stamina)
	register_hook("optic-_physics_process-pre", _optic.on_physics_process_pre)
	register_hook("laser-_input", _laser.on_input)
	register_hook("laser-_process-post", _laser.on_process_post)
	register_hook("flashlight-_physics_process", _flashlight.on_physics_process)
	register_hook("flashlight-activate-post", _flashlight.on_activate_post)
	register_hook("nvg-_physics_process", _nvg.on_physics_process)
	register_hook("tooltip-reset-post", _tooltip.on_reset_post)
	register_hook("tooltip-update-post", _tooltip.on_update_post)
	register_hook("interactor-_physics_process-pre", _interactor.on_physics_process_pre)
	register_hook("uiposition-_physics_process-post", _uiposition.on_physics_process_post)
	register_hook("item-updatedetails-post", _item.on_update_details_post)
	register_hook("ai-weapondamage-pre", _kill_counter.on_ai_weapon_damage)
	register_hook("ai-explosiondamage-pre", _kill_counter.on_ai_explosion_damage)
	register_hook("ai-death-pre", _kill_counter.on_ai_death)
	register_hook("loader-loadscene-pre", _kill_counter.on_load_scene_pre)
	register_hook("loader-loadscene-pre", _bus.on_load_scene_pre)
	register_hook("loader-savecharacter-pre", _slot_meta.on_save_character_pre)
	register_hook("interface-loadslotitem-post", _slot_meta.on_load_slot_item_post)
	register_hook("pickup-_ready-post", _pickup.on_ready_post)
	register_hook("lootcontainer-updatetooltip-post", _loot_container.on_update_tooltip_post)

	register_action("optic_zoom_in", "Optic Zoom In", create_mouse_input(MOUSE_BUTTON_WHEEL_UP))
	register_action("optic_zoom_out", "Optic Zoom Out", create_mouse_input(MOUSE_BUTTON_WHEEL_DOWN))
	register_action("binoculars", "Binoculars", create_key_input(KEY_B))
	register_action("hold_breath", "Hold Breath", "sprint")
	register_action("canted_standalone", "Canted Aim (quick)")
	remove_action("ammo_check")
	remove_action("insert")

	_binoculars = BinocularsOverlay.new(_bus)
	add_child(_binoculars)
	add_child(FiberReticle.new())


func _on_config_applied() -> void:
	Out.debug_enabled = config.debug_enabled
	Out.show_protips = config.show_protips
