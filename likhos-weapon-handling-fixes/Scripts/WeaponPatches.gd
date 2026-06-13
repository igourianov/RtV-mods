const Out = preload("../Lib/Out.gd")
const ModConfig = preload("./ModConfig.gd")


static func apply(lib) -> void:
	lib.patch(lib.Registry.ITEMS, "AK_12", {
		"inspectPosition": Vector3(-0.05, -0.15, -0.03), # BUGFIX: inspect position too far - showing eds of the arms
		"inspectRotation": Vector3(-6, -10, 5),
	})
	lib.patch(lib.Registry.ITEMS, "AKM", {
		"inspectPosition": Vector3(-0.05, -0.15, 0.0), # BUGFIX: inspect position too far - showing eds of the arms
		"inspectRotation": Vector3(-6, -10, -5),
	})