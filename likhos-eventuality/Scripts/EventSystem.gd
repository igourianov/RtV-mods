extends RefCounted

var _lib
var _config
var _rollBonus: Dictionary = {}
var _jetCounter: int = 0

const _AUDIO_LIBRARY := preload("res://Resources/AudioLibrary.tres")

const blockers := {
	"BTR": "Police",
	"Police": "BTR",
	"Airdrop": "CrashSite",
	"CrashSite": "Airdrop"
}


func _init(lib, config) -> void:
	_lib = lib
	_config = config


func on_activate_dynamic_event() -> void:
	var es = _lib._caller
	_lib.skip_super()
	if es == null:
		return
	_activate_dynamic_event(es)


func _activate_dynamic_event(es) -> void:

	print("[likho] available events: %s" % [es.dynamicEvents.map(func(el): return el.function)])
	print("[likho] pending roll bonuses: %s" % [_rollBonus])

	if es.dynamicEvents.size() == 0:
		return

	_jetCounter = int(randi_range(3, 10))
	var activated: Dictionary = {}
	var events = es.dynamicEvents.duplicate()
	events.shuffle()

	for e in events:
		var blocker: String = blockers.get(e.function, null)
		var bonus: float = _rollBonus.get(e.function, 0.0)
		var basePossibility: float = _config.get_probability(e.function, e.possibility)

		if blocker != null && activated.has(blocker):
			bonus += basePossibility
			_rollBonus.set(e.function, bonus)
			print("[likho] event skipped: %s | Blocked by: %s | Next roll bonus: +%s" % [e.function, blocker, bonus])
			continue

		var threshold: float = basePossibility + bonus
		var roll: float = randi_range(1, 100)
		_rollBonus.set(e.function, 0.0)

		if roll > threshold:
			print("[likho] event missed: %s | Roll: %s/%s" % [e.function, roll, threshold])
			continue

		activated[e.function] = true

		if e.instant:
			print("[likho] event activated: %s | Roll: %s/%s" % [e.function, roll, threshold])
			Callable(es, e.function).call()
		else:
			var delay = randi_range(30, 300)
			print("[likho] event activated: %s | Roll: %s/%s | Delay: %02d:%02d" % [e.function, roll, threshold, int(floor(delay / 60.0)), delay % 60])
			_activate_delayed_event(es, delay, e.function) # no await on purpose

func _activate_delayed_event(es, delay, name):
	await es.get_tree().create_timer(delay, false).timeout
	Callable(es, name).call()

func on_fighter_jet_post() -> void:
	var es = _lib._caller
	_jetCounter -= 1
	if es == null || _jetCounter <= 0:
		return
	_schedule_fighter_jet(es)


func _schedule_fighter_jet(es) -> void:
	var delay = randi_range(60, 300)
	print("[likho] FighterJet triggered | Nex one in: %02d:%02d" % [int(floor(delay / 60.0)), delay % 60])
	await es.get_tree().create_timer(delay, false).timeout
	if !is_instance_valid(es):
		return
	Callable(es, "FighterJet").call()


func on_crash_site() -> void:
	var es = _lib._caller
	_lib.skip_super()
	if es == null:
		return
	var crashesRoot = es.crashes
	if crashesRoot == null || crashesRoot.get_child_count() == 0:
		return
	var spawn = crashesRoot.get_child(randi_range(0, crashesRoot.get_child_count() - 1))
	var crashSite = es.crash.instantiate()
	spawn.add_child(crashSite)
	crashSite.global_transform = spawn.global_transform

	var delay = randi_range(5, 20)
	print("[likho] CrashSite triggered | Boom in: %ss at %s" % [delay, spawn.global_position])
	_play_delayed_explosion(es, spawn.global_position, delay)


func _play_delayed_explosion(es, pos: Vector3, initialDelay: float) -> void:
	await es.get_tree().create_timer(initialDelay, false).timeout
	if !is_instance_valid(es):
		return
	var audioEvent = _AUDIO_LIBRARY.grenadeExplosionOutdoorClose
	if audioEvent == null || audioEvent.audioClips.is_empty():
		return
	var count := randi_range(2, 4)
	for i in count:
		if i > 0:
			var gap := randf_range(0.2, 1.0)
			await es.get_tree().create_timer(gap, false).timeout
			if !is_instance_valid(es):
				return
		_spawn_explosion(es, pos, audioEvent)


func _spawn_explosion(es, pos: Vector3, audioEvent) -> void:
	var player := AudioStreamPlayer3D.new()
	player.bus = &"SFX"
	player.stream = audioEvent.audioClips.pick_random()
	player.unit_size = 100.0
	player.max_distance = 2000.0
	player.volume_db = audioEvent.volume
	es.get_tree().get_root().add_child(player)
	player.global_position = pos
	player.play()
	player.finished.connect(player.queue_free)
