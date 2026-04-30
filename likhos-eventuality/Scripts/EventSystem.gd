extends RefCounted

var _lib

var rollBonuses: Dictionary = {}
const blockers := {
	"BTR": "Police",
	"Police": "BTR",
	"Airdrop": "CrashSite",
	"CrashSite": "Airdrop"
}


func _init(lib) -> void:
	_lib = lib


func on_activate_dynamic_event() -> void:
	var es = _lib._caller
	_lib.skip_super()
	if es == null:
		return
	_activate_dynamic_event(es)


func _activate_dynamic_event(es) -> void:

	print("[likho] available events: %s" % [es.dynamicEvents.map(func(el): return el.function)])

	if es.dynamicEvents.size() == 0:
		return

	var activated: Dictionary = {}
	var events = es.dynamicEvents.duplicate()
	events.shuffle()

	for e in events:
		var blocker: String = blockers.get(e.function, null)
		var bonus: float = rollBonuses.get(e.function, 0.0)

		if blocker != null && activated.has(blocker):
			bonus += e.possibility
			rollBonuses.set(e.function, bonus)
			print("[likho] event skipped: %s | Blocked by: %s | Next roll bonus: +%s" % [e.name, blocker, bonus])
			continue

		var threshold: float = e.possibility + bonus
		var roll = randi_range(1, 100)
		rollBonuses.set(e.function, 0.0)

		if roll > threshold:
			print("[likho] event missed: %s | Roll: %s/%s" % [e.name, roll, threshold])
			continue

		activated[e.function] = true

		if e.instant:
			print("[likho] event activated: %s | Roll: %s/%s" % [e.name, roll, threshold])
			Callable(es, e.function).call()
		else:
			var delay = randi_range(30, 300)
			print("[likho] event activated: %s | Roll: %s/%s | Delay: %02d:%02d" % [e.name, roll, threshold, int(floor(delay / 60.0)), delay % 60])
			_activate_delayed_event(es, delay, e.function) # no await on purpose

func _activate_delayed_event(es, delay, name):
	await es.get_tree().create_timer(delay, false).timeout
	Callable(es, name).call()

func on_fighter_jet_post() -> void:
	var es = _lib._caller
	if es == null:
		return
	_schedule_fighter_jet(es)


func _schedule_fighter_jet(es) -> void:
	var delay = randi_range(60, 300)
	print("[likho] FighterJet triggered | Nex one in: %02d:%02d" % [int(floor(delay / 60.0)), delay % 60])
	await es.get_tree().create_timer(delay, false).timeout
	if !is_instance_valid(es):
		return
	Callable(es, "FighterJet").call()
