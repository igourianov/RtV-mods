extends "../Lib/Main.gd"

const Patches = preload("./Patches.gd")
const Item = preload("./Item.gd")

var _item


func setup(lib) -> void:
	Patches.apply(lib)

	_item = Item.new(lib)
	register_hook("item-updatesprite-pre", _item.on_update_sprite_pre)
	register_hook("item-updatesprite-post", _item.on_update_sprite_post)