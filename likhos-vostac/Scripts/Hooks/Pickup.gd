extends RefCounted

const AttachmentMounts := preload("../AttachmentMounts.gd")

var _lib


func _init(lib) -> void:
	_lib = lib


func on_ready_post() -> void:
	var pickup: Node = _lib._caller
	if !pickup || !pickup.slotData || !pickup.slotData.itemData:
		return
	AttachmentMounts.mount(pickup.get_node_or_null("Attachments"), pickup.slotData.itemData.file, "pickup")
