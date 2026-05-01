extends RefCounted

# weapon_path -> { mag_path -> tweaks }. Empty `{}` = use defaults.
# Tweaks (all optional) modify the foreign-mag overlay sprite's transform on
# the host weapon's inventory icon, relative to the native mag sprite:
#   offset:          Vector2 added to position     (default Vector2.ZERO)
#   rotation_offset: float radians added           (default 0.0)
#   scale_mult:      Vector2 multiplied with scale (default Vector2.ONE)
# Direction matters: A accepting B's mag does not imply B accepts A's mag.

const COMPAT := {
	"res://Items/Weapons/AK-12/AK-12.tres": {
		"res://Items/Weapons/AKS-74U/AKS-74U_Magazine.tres": {},
	},
	"res://Items/Weapons/AKS-74U/AKS-74U.tres": {
		"res://Items/Weapons/AK-12/AK-12_Magazine.tres": {},
	},
}
