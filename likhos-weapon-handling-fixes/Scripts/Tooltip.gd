extends RefCounted

const ScopeCatalog = preload("./ScopeCatalog.gd")

const _META_MAG_ROW := "likho_mag_row"
const _META_EYE_ROW := "likho_eye_row"


var _lib


func _init(lib) -> void:
	_lib = lib


func on_update_post(item) -> void:
	var tooltip = _lib._caller
	if !tooltip:
		return

	var mag_row: Control = _ensure_row(tooltip, _META_MAG_ROW, "Magnification:")
	var eye_row: Control = _ensure_row(tooltip, _META_EYE_ROW, "Eye Relief:")

	mag_row.hide()
	eye_row.hide()

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
			mag_row.get_child(1).text = text
			mag_row.show()

	if entry.has("eye_relief"):
		var er = entry["eye_relief"]
		if er is Vector2:
			eye_row.get_child(1).text = "%s-%s cm" % [_fmt_num(er.x), _fmt_num(er.y)]
			eye_row.show()


func _ensure_row(tooltip, meta_key: String, title_text: String) -> Control:
	if tooltip.has_meta(meta_key):
		return tooltip.get_meta(meta_key)

	var sibling: Label = tooltip.weight
	var parent: Node = sibling.get_parent()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var title := Label.new()
	title.theme = sibling.theme
	title.add_theme_font_size_override("font_size", 12)
	title.text = title_text
	title.vertical_alignment = VERTICAL_ALIGNMENT_FILL
	row.add_child(title)

	var value := Label.new()
	value.add_theme_color_override("font_color", Color.GREEN)
	value.add_theme_font_size_override("font_size", 12)
	value.vertical_alignment = VERTICAL_ALIGNMENT_FILL
	row.add_child(value)

	parent.add_child(row)
	tooltip.set_meta(meta_key, row)
	return row


func _fmt_num(v: float) -> String:
	if absf(v - roundf(v)) < 0.05:
		return str(int(roundf(v)))
	return "%.1f" % v
