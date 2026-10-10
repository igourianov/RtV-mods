extends Resource

enum CrosshairStyle { OFF, DOT, SEGMENTED_CROSS }
# DEFAULT follows the game's Aim Mode
enum CantMode { DEFAULT, HOLD, TOGGLE }
enum ChamberCardMode { ENABLED, MANUAL_GUNS_ONLY, DISABLED }
# RAIL_MOVEMENT requires the Rail Movement binding held as a modifier
enum ZoomOutOfAim { ENABLED, DISABLED, RAIL_MOVEMENT }
# an optic that lacks the chosen schema falls back to SHORT
enum MagnificationSchema { DISCRETE, NORMALIZED, SHORT }

const BASE_WEAPON_WEIGHT := 4.0
# a key released later than this after its press was held, not tapped
const BUTTON_HOLD_MS := 250

static var instance := new()

# dynamic state vars
var current_scope_mag: float = 1.0
var current_weapon_weight: float = 0.0
var current_weapon_action: String = ""
var ammo_check_view := false
var hold_breath_state: float = 0.0
var optic_shiner: bool = false
var binoculars_active: bool = false
var binoculars_mag: float = 6.0
var kills: PackedByteArray = PackedByteArray([0, 0, 0, 1, 2, 3, 0, 4, 0, 1, 0, 0, 0])
var gameData := preload("res://Resources/GameData.tres")

# config vars
@export var debug_enabled: bool = false
@export var show_protips: bool = true

@export_group("Crosshair")
@export var crosshair_style: CrosshairStyle = CrosshairStyle.SEGMENTED_CROSS
@export var crosshair_color: Color = Color(0, 1, 0.04, 0.55)
@export var crosshair_while_running: bool = false
@export var crosshair_while_canted: bool = false
@export var crosshair_while_raised: bool = false

@export_group("Canted mode")
@export var cant_mode: CantMode = CantMode.DEFAULT
@export var laser_auto_on: bool = true

@export_group("Weapon Cards")
@export var firemode_card: bool = true
@export var attachment_cards: bool = true
@export var ammo_icons: bool = false
@export var ammo_cards_check: bool = true
@export var ammo_cards_inspect: bool = true
@export var ammo_cards_manual_reload: bool = true
@export var chamber_card_mode: ChamberCardMode = ChamberCardMode.ENABLED
@export var kill_counter_card: bool = true

@export_group("Aim tweaks")
@export var free_look: bool = true
@export var patrol_position: bool = true
@export var negligent_discharge: bool = true
@export var zoom_out_of_aim: ZoomOutOfAim = ZoomOutOfAim.RAIL_MOVEMENT
@export var magnification_schema: MagnificationSchema = MagnificationSchema.NORMALIZED
@export var nvg_pip_blur: bool = true
@export var pip_anti_aliasing: bool = true
@export var zoom_dof: bool = true

@export_group("Movement speeds")
@export var override_movement_speeds: bool = true
@export_range(0.0, 20.0, 0.1) var crouch_speed: float = 0.7
@export_range(0.0, 20.0, 0.1) var walk_speed: float = 3.0
@export_range(0.0, 20.0, 0.1) var sprint_speed: float = 7.0
@export_range(0.1, 1.5, 0.05) var walk_aim_mult: float = 0.6
@export_range(0.1, 1.5, 0.05) var walk_cant_mult: float = 0.75
@export_range(0.1, 1.5, 0.05) var walk_scope_mult: float = 0.3

@export_group("Stamina")
@export var custom_stamina: bool = true


# tier 1 - weapon handling concern does not run at all
func gated() -> bool:
	return gameData.menu || gameData.freeze || gameData.isDead || gameData.isTransitioning || gameData.isCaching


# tier 2 - modal weapon actions that own the hands until they complete
# vanilla flags a manual bolt cycle as a reload, but it's a single motion that must not drop the aim
func locked() -> bool:
	return ((gameData.isReloading && current_weapon_action != "Manual") || gameData.isInspecting || gameData.isChecking
		|| gameData.isInserting || gameData.isPlacing || gameData.isDrawing
		|| gameData.isClearing)
