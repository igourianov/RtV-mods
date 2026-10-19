extends "../../Lib/Tooltip.gd"

const ScopeCatalog = preload("../ScopeCatalog.gd")

const ROW_MAG := "likho_mag_row"
const ROW_EYE := "likho_eye_row"
const ROW_OBJ := "likho_obj_row"


func on_reset_post():
	var tooltip: Node = _lib._caller
	_hide_row(tooltip, ROW_MAG)
	_hide_row(tooltip, ROW_OBJ)
	_hide_row(tooltip, ROW_EYE)


func on_update_post(item: Item) -> void:
	var tooltip: Node = _lib._caller
	if !tooltip:
		return

	if !item || !item.slotData:
		return

	# the catalog covers magnified optics only, with fallback values for the ones it does not list
	var att := item.slotData.itemData as AttachmentData
	if !att || !(att.scope || att.variable):
		return

	var mag := ScopeCatalog.get_mag_range(att)
	var mag_text := "%sx" % _fmt_num(mag[0]) if mag.size() == 1 else "%s-%sx" % [_fmt_num(mag[0]), _fmt_num(mag[-1])]
	_show_row(tooltip, ROW_MAG, "Magnification:", mag_text)

	_show_row(tooltip, ROW_OBJ, "Objective:", "%s mm" % _fmt_num(ScopeCatalog.get_objective(att)))

	var er := ScopeCatalog.get_eye_relief(att)
	var er_text := "%s cm" % _fmt_num(er.x) if er.x == er.y else "%s-%s cm" % [_fmt_num(er.x), _fmt_num(er.y)]
	_show_row(tooltip, ROW_EYE, "Eye Relief:", er_text)


func _fmt_num(v: float) -> String:
	if absf(v - roundf(v)) < 0.05:
		return str(int(roundf(v)))
	return "%.1f" % v
