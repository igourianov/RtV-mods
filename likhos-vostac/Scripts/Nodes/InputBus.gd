extends Node

# Reads the stance input and resolves its conflicts. Stances live on two axes, each holding one state at a time.
# A toggle is a latch on its axis and is cleared for good when something takes over. A held key is followed live.
# The bus knows nothing about domain constraints: each consumer validates its own resolved state before acting on it.

const ModConfig := preload("../ModConfig.gd")

enum Arms { NONE, AIM, CANTED, BINOCULARS }
enum Pose { NONE, SPRINT, CROUCH }

var gameData := preload("res://Resources/GameData.tres")

var _arms_latch := Arms.NONE
var _pose_latch := Pose.NONE

# hold mode keys whose state has started, and their press order: the higher value was pressed later
var _aim_held := false
var _cant_held := false
var _sprint_held := false
# an optic strike ended the aim, and the key has to come up before it can aim again
var _aim_withdrawn := false
var _presses: int = 0
var _aim_press: int = 0
var _cant_press: int = 0
var _sprint_press: int = 0

var _binoculars_raised_ms: int = 0

# the arms state in effect, resolved once per tick and around every input event
var _arms := Arms.NONE


func _init() -> void:
	# a key that comes up while the tree is paused must still end its held state
	process_mode = Node.PROCESS_MODE_ALWAYS


# a lock that starts or ends changes what is in effect without any input event
func _physics_process(_delta: float) -> void:
	_settle()


func _input(evt: InputEvent) -> void:
	if evt is InputEventMouseMotion:
		return

	# everything must be current before a toggle press is judged against it
	_settle()
	_record_toggle(evt)
	_settle()


func aim() -> bool:
	return _arms == Arms.AIM


func canted() -> bool:
	return _arms == Arms.CANTED


func binoculars() -> bool:
	return _arms == Arms.BINOCULARS


func sprint() -> bool:
	return (_sprint_held || _pose_latch == Pose.SPRINT) && _arms == Arms.NONE


func crouch() -> bool:
	return _pose_latch == Pose.CROUCH && !sprint()


func hold_breath() -> bool:
	return _arms == Arms.AIM && Input.is_action_pressed("hold_breath")


# for a domain that has to end its own state without the user asking, e.g. an optic strike
func withdraw_aim() -> void:
	_aim_held = false
	_aim_withdrawn = true
	if _arms_latch == Arms.AIM:
		_arms_latch = Arms.NONE
	_settle()


func withdraw_binoculars() -> void:
	if _arms_latch == Arms.BINOCULARS:
		_arms_latch = Arms.NONE
	_settle()


# the rig is gone and a latched aim or canted goes with it. Held keys stay live.
func withdraw_weapon() -> void:
	if _arms_latch == Arms.AIM || _arms_latch == Arms.CANTED:
		_arms_latch = Arms.NONE
	_settle()


# The bus outlives every scene, and vanilla starts each one with fresh aim and sprint toggles.
# Keys that are still down start their state again on the next tick.
func on_load_scene_pre(_scene: String = "") -> void:
	_arms_latch = Arms.NONE
	_pose_latch = Pose.NONE
	_aim_held = false
	_cant_held = false
	_sprint_held = false
	_arms = Arms.NONE


# Toggle mode presses, judged against what a held key would do to them.
# A press is dropped when a held key would override the latch at once.
func _record_toggle(evt: InputEvent) -> void:
	var open := !ModConfig.gated()
	# during a lock the keys belong to the modal action, e.g. canted rotates the weapon while inspecting
	var unlocked: bool = open && !ModConfig.locked()
	var armed: bool = unlocked && (gameData.primary || gameData.secondary)

	# a held binoculars key lowers them on release, a tapped one leaves them up
	if evt.is_action_released("binoculars") && _arms_latch == Arms.BINOCULARS && Time.get_ticks_msec() - _binoculars_raised_ms > ModConfig.BUTTON_HOLD_MS:
		_arms_latch = Arms.NONE
	elif evt.is_action_pressed("aim") && armed && _aim_toggle() && !_cant_held:
		_arms_latch = Arms.NONE if _arms_latch == Arms.AIM else Arms.AIM
	# a held sprint counts even while aim keeps it suspended, because canted would end that aim
	elif evt.is_action_pressed("canted") && armed && _cant_toggle() && !_aim_held && !_sprint_held:
		_arms_latch = Arms.NONE if _arms_latch == Arms.CANTED else Arms.CANTED
	# the binoculars key never counts as held, so an aim or canted press always replaces them
	elif evt.is_action_pressed("binoculars") && unlocked && _arms_latch != Arms.BINOCULARS && !_aim_held && !_cant_held && !_sprint_held:
		_arms_latch = Arms.BINOCULARS
		_binoculars_raised_ms = Time.get_ticks_msec()
	# sprint and hold breath share a key by default, and a press that holds breath leaves the latch alone
	elif evt.is_action_pressed("sprint") && open && _sprint_toggle() && !hold_breath() && !(_cant_held && _weapon_ready()):
		_pose_latch = Pose.NONE if _pose_latch == Pose.SPRINT else Pose.SPRINT
		# this also ends an aim that a lock has suspended
		if _pose_latch == Pose.SPRINT:
			_arms_latch = Arms.NONE
	# a held sprint does not count while aim keeps it suspended
	elif evt.is_action_pressed("crouch") && open && (!_sprint_held || _arms == Arms.AIM):
		_pose_latch = Pose.NONE if _pose_latch == Pose.CROUCH else Pose.CROUCH


# Brings the held keys, the resolved arms state and the latches up to date.
func _settle() -> void:
	_follow_held_keys()
	_arms = _resolve_arms()

	# a latch that something in effect has taken over from is cleared, so nothing comes back when that ends
	if (_arms == Arms.AIM && _aim_held) || (_arms == Arms.CANTED && _cant_held):
		_arms_latch = Arms.NONE

	if _arms != Arms.NONE && _pose_latch == Pose.SPRINT:
		_pose_latch = Pose.NONE
	elif _arms == Arms.NONE && _sprint_held:
		_pose_latch = Pose.NONE
		_arms_latch = Arms.NONE


# Hold mode states follow the live key state instead of press and release events.
# So a key pressed during a gate or a lock starts its state once that ends, and a release that never arrived as an event still ends it.
func _follow_held_keys() -> void:
	var open := !ModConfig.gated()
	var armed: bool = open && _weapon_ready()
	var aimDown := Input.is_action_pressed("aim")
	var cantDown := Input.is_action_pressed("canted")
	var sprintDown := Input.is_action_pressed("sprint")

	_aim_withdrawn = _aim_withdrawn && aimDown

	if !aimDown:
		_aim_held = false
	elif !_aim_held && armed && !_aim_toggle() && !_aim_withdrawn:
		_aim_held = true
		_presses += 1
		_aim_press = _presses

	if !cantDown:
		_cant_held = false
	elif !_cant_held && armed && !_cant_toggle():
		_cant_held = true
		_presses += 1
		_cant_press = _presses

	if !sprintDown:
		_sprint_held = false
	# sprint and hold breath share a key by default, and a key that holds breath starts no sprint
	elif !_sprint_held && open && !_sprint_toggle() && !(Input.is_action_pressed("hold_breath") && _resolve_arms() == Arms.AIM):
		_sprint_held = true
		_presses += 1
		_sprint_press = _presses
		# a latch has no press order to lose by, so a sprint that starts under a latched aim ends it here
		if _arms_latch == Arms.AIM:
			_arms_latch = Arms.NONE


func _resolve_arms() -> Arms:
	var ready := _weapon_ready()
	# among held keys the last pressed wins
	var aimHeld: bool = _aim_held && ready && !(_sprint_held && _sprint_press > _aim_press)
	var cantHeld: bool = _cant_held && ready && !(_sprint_held && _sprint_press > _cant_press)

	if aimHeld && cantHeld:
		return Arms.CANTED if _cant_press > _aim_press else Arms.AIM
	if cantHeld:
		return Arms.CANTED
	if aimHeld:
		return Arms.AIM
	if _arms_latch == Arms.AIM:
		return Arms.AIM if ready else Arms.NONE
	# an aim latch never yields to a sprint key held from before it, the other arms latches do
	if _sprint_held:
		return Arms.NONE
	if _arms_latch == Arms.CANTED:
		return Arms.CANTED if ready else Arms.NONE
	return _arms_latch


# during a lock a latched aim or canted is kept but not in effect, and so is a held one with no firearm in hand
func _weapon_ready() -> bool:
	return (gameData.primary || gameData.secondary) && !ModConfig.locked()


func _aim_toggle() -> bool:
	return gameData.aimMode == 2


func _cant_toggle() -> bool:
	if ModConfig.cant_mode == &"default":
		return gameData.aimMode == 2
	return ModConfig.cant_mode == &"toggle"


func _sprint_toggle() -> bool:
	return gameData.sprintMode != 1
