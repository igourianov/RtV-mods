extends "../Lib/Main.gd"


func setup(lib) -> void:
	lib.patch(lib.Registry.ITEMS, "Key_Cellar", { "doctor": true, "value": 5000 })
	lib.patch(lib.Registry.ITEMS, "Key_Gymnasium", { "gunsmith": true, "value": 5000 })
	lib.patch(lib.Registry.ITEMS, "Key_Tunnel", { "generalist": true, "value": 5000 })
