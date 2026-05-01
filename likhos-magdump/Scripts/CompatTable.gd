extends RefCounted

# weapon_path -> { mag_path -> tweaks }. Empty `{}` = use defaults.
# Tweaks (all optional) modify the foreign-mag overlay sprite's transform on
# the host weapon's inventory icon, relative to the native mag sprite:
#   offset:          Vector2 added to position     (default Vector2.ZERO)
#   rotation_offset: float radians added           (default 0.0)
#   scale_mult:      Vector2 multiplied with scale (default Vector2.ONE)
# Direction matters: A accepting B's mag does not imply B accepts A's mag.

const COMPAT := {
	"AK_12": ["AKS_74U_Magazine"],
	"AKS_74U": ["AK_12_Magazine"],
	"RK_62": ["AKM_Magazine"],
	"RK_62M": ["AKM_Magazine"],
	"RK_95": ["AKM_Magazine"],
	"AKM": ["RK_Magazine"],
	"HK416": ["KAR_21_223_Magazine"],
	"M4A1": ["KAR_21_223_Magazine"],
	"MK18": ["KAR_21_223_Magazine"],
	"KAR_21_223": ["STANAG_Magazine"],
}
