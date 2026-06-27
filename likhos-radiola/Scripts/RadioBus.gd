const BUS := &"ModRadio"
const SEND := &"Master"
const HIGH_PASS_HZ := 400.0
const LOW_PASS_HZ := 3200.0
const DISTORTION_PRE_GAIN := -6.0


static func apply() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return

	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, BUS)
	AudioServer.set_bus_send(idx, SEND)

	var high_pass := AudioEffectHighPassFilter.new()
	high_pass.cutoff_hz = HIGH_PASS_HZ
	AudioServer.add_bus_effect(idx, high_pass)

	var low_pass := AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = LOW_PASS_HZ
	AudioServer.add_bus_effect(idx, low_pass)

	var distortion := AudioEffectDistortion.new()
	distortion.mode = AudioEffectDistortion.MODE_LOFI
	distortion.pre_gain = DISTORTION_PRE_GAIN
	AudioServer.add_bus_effect(idx, distortion)
