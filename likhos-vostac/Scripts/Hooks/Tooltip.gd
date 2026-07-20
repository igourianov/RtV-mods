extends "../../Lib/Tooltip.gd"

const ScopeCatalog = preload("../ScopeCatalog.gd")

const ROW_MAG := "likho_mag_row"
const ROW_EYE := "likho_eye_row"


func on_reset_post():
	var tooltip = _lib._caller
	_hide_row(tooltip, ROW_MAG)
	_hide_row(tooltip, ROW_EYE)


func on_update_post(item) -> void:
	var tooltip = _lib._caller
	if !tooltip:
		return

	if !item || !item.slotData || !item.slotData.itemData:
		return

	var entry: Dictionary = ScopeCatalog.DATA.get(item.slotData.itemData.file, {})
	if entry.is_empty():
		return

	if entry.has("mag_range"):
		var mag: Array = entry["mag_range"]
		var text := ""
		if mag.size() == 1:
			text = "%sx" % _fmt_num(mag[0])
		elif mag.size() > 1:
			text = "%s-%sx" % [_fmt_num(mag[0]), _fmt_num(mag[-1])]
		if text != "":
			_show_row(tooltip, ROW_MAG, "Magnification:", text)

	if entry.has("eye_relief"):
		var er: Variant = entry["eye_relief"]
		if er is Vector2:
			_show_row(tooltip, ROW_EYE, "Eye Relief:", "%s-%s cm" % [_fmt_num(er.x), _fmt_num(er.y)])


func _fmt_num(v: float) -> String:
	if absf(v - roundf(v)) < 0.05:
		return str(int(roundf(v)))
	return "%.1f" % v
