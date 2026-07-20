extends RefCounted

const RadioRegistry = preload("../RadioRegistry.gd")
const RadioPlayer = preload("../Nodes/RadioPlayer.gd")
const RadioStation = preload("../RadioStation.gd")
const ModConfig = preload("../ModConfig.gd")
const META_PLAYER := "radio_player"
const META_AUTOROLL := "radio_autoroll"

var _lib


func _init(lib) -> void:
	_lib = lib


func on_interact() -> void:
	var radio = _lib._caller
	var stations := RadioRegistry.STATIONS
	if stations.is_empty():
		return

	var player := _player(radio)

	# OFF -> Vanilla: let vanilla turn itself on.
	if !radio.active && !player.station:
		return

	# Vanilla -> first station: turn the broadcast off ourselves so vanilla's
	# Interact() does not stop our tuning clip.
	if radio.active:
		_lib.skip_super()
		radio.active = false
		radio.audio.stop()
		_tune_to(radio, stations[0])
		return

	# On a station (playing or mid-tune): advance, or stop after the last.
	# Keep vanilla off.
	_lib.skip_super()
	var i := stations.find(player.station)
	if i + 1 < stations.size():
		_tune_to(radio, stations[i + 1])
		return

	player.stop()
	radio.tuning.stop()
	radio.InteractAudio()


func on_physics_process_pre(_delta: float) -> void:
	var radio = _lib._caller
	_tick_tuning(radio)

	if radio.has_meta(META_AUTOROLL):
		return
	radio.set_meta(META_AUTOROLL, true)

	if randf() * 100.0 >= ModConfig.on_chance:
		return

	var stations := RadioRegistry.STATIONS
	var pick := randi() % (stations.size() + 1)
	if pick == 0:
		radio.active = true
		return

	_player(radio).start(stations[pick - 1])


func on_update_tooltip_post() -> void:
	if RadioRegistry.STATIONS.is_empty():
		return
	var radio = _lib._caller
	var state := "Off"
	if radio.tuning.is_playing():
		state = "Tuning..."
	elif radio.active:
		state = "Area05 broadcast"
	elif radio.has_meta(META_PLAYER):
		var player: RadioPlayer = radio.get_meta(META_PLAYER)
		state = player.station.name if player.station else "Off"

	radio.gameData.tooltip = "Radio [%s]" % state


func _tune_to(radio, to_station: RadioStation) -> void:
	var player := _player(radio)
	if player.playing:
		player.stop()
	player.station = to_station
	# Reuse the in-progress sweep when flipping stations mid-tune.
	if !radio.tuning.is_playing():
		_play_tuning(radio)


# Hold until the tuning clip stops, then start at the live position.
func _tick_tuning(radio) -> void:
	if !radio.has_meta(META_PLAYER):
		return
	var player = radio.get_meta(META_PLAYER)
	if !player.station || player.playing || radio.tuning.is_playing():
		return
	player.start()


func _play_tuning(radio) -> void:
	if radio.tuningClips.is_empty():
		return
	radio.tuning.stream = radio.GetRandomTuningClip()
	radio.tuning.play()


func _player(radio) -> RadioPlayer:
	if radio.has_meta(META_PLAYER):
		return radio.get_meta(META_PLAYER)
	var p = RadioPlayer.new()
	p.name = "RadioPlayer"
	radio.add_child(p)
	radio.set_meta(META_PLAYER, p)
	return p
