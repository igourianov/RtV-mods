extends RefCounted

# Item.gd's UpdateSprite has two places where bare guns ignore the
# WeaponData *Scale fields:
#   1. Inventory grid: hardcodes `sprite.scale = Vector2(0.5, 0.5)` when
#      `!equipped && !suppressor && !magazine && !optic`.
#   2. Equipment slot: the auto-fit block uses `scalePercentage =
#      currentScale / 0.5`, and `currentScale` is only re-assigned from a
#      *Scale field when one of the attachment combos matches. With no
#      attachments `currentScale` keeps its 0.5 default and
#      `scalePercentage` collapses to 1.0, so the gun renders at the
#      vanilla auto-fit size in both primary and secondary slots, missing
#      the linear shrink that we apply to the magazineScale path.
# To shrink both, we bracket UpdateSprite with pre + post hooks: pre flips
# `item.magazine` to true so vanilla takes the magazine branch (using our
# factor-scaled `magazineScale` and `magazineOffset`), post flips it back.
# The flip is contained inside a single UpdateSprite call, so no stale
# flag state leaks into other Item.gd code paths or into UpdateSprite
# calls made directly (e.g. from Interface.gd) without a preceding
# UpdateAttachments.

const Patches = preload("res://mods/likhos-second-hand/Scripts/Patches.gd")

const _META_KEY := "_likho_second_hand_tricked_magazine"

var _lib


func _init(lib) -> void:
	_lib = lib


func on_update_sprite_pre() -> void:
	var item = _lib._caller
	if item == null:
		return
	if item.slotData == null || item.slotData.itemData == null:
		return
	if !Patches.RESIZE.has(item.slotData.itemData.file):
		return
	if item.magazine || item.optic || item.suppressor:
		return
	item.magazine = true
	# Stash on the item so post knows to undo. Per-item meta is
	# re-entrancy-safe even if two items' UpdateSprite ever interleaved
	# (currently they don't, UpdateSprite is synchronous), and survives
	# foreign pre/post hooks running between ours.
	item.set_meta(_META_KEY, true)


func on_update_sprite_post() -> void:
	var item = _lib._caller
	if item == null:
		return
	if !item.has_meta(_META_KEY):
		return
	item.magazine = false
	item.remove_meta(_META_KEY)
