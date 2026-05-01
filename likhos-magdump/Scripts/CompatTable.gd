extends RefCounted

# Per-weapon list of additional magazines accepted at reload/combine time.
# Direction matters: declaring weapon A accepts mag B does NOT imply
# weapon B accepts mag A. For mutual compatibility, declare both directions.
#
# Vanilla `compatible` entries (own magazine, optics, etc.) are preserved.
# We append only, dedupe, and never reorder, so AI.gd's `compatible[0]`
# assumption stays valid.

const COMPAT := {
	# AK-12 and AKSU mutually accept each other's 5.45x39 magazines.
	"res://Items/Weapons/AK-12/AK-12.tres": [
		"res://Items/Weapons/AKS-74U/AKS-74U_Magazine.tres",
	],
	"res://Items/Weapons/AKS-74U/AKS-74U.tres": [
		"res://Items/Weapons/AK-12/AK-12_Magazine.tres",
	],

	# Future asymmetric example (commented; uncomment + adjust paths):
	# RK rifles accept AKM mags. AKM does NOT accept RK mags (no reverse entry).
	# "res://Items/Weapons/RK-62/RK-62.tres": [
	#     "res://Items/Weapons/AKM/AKM_Magazine.tres",
	# ],
	# "res://Items/Weapons/RK-95/RK-95.tres": [
	#     "res://Items/Weapons/AKM/AKM_Magazine.tres",
	# ],
}
