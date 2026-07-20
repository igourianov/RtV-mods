extends RefCounted

const Out := preload("../Lib/Out.gd")

# Corrects optic node property values that ship wrong in vanilla rig scenes
# (e.g. defaultPosition outside the [minPosition, maxPosition] rail range).
#
# Applied via the loader's SCENE_NODES registry: patches land on live rig
# instances when they enter the tree. The PackedScene is never mutated and
# every patch is reversible.
#
# Key format:   "<rig_scene_path>#<node_path_to_optic>"
# Value format: { "<property>": <corrected_value>, ... }
const PATCHES := {
	"res://Items/Weapons/SVD/SVD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/SVD/Armature/Skeleton3D/Attachments/POSP": {
		"defaultPosition": 0.09,
		"minPosition": 0.07,
		"maxPosition": 0.12,
		"railMovement": true,
	},
	"res://Items/Weapons/VSS/VSS_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/VSS/Armature/Skeleton3D/Attachments/POSP": {
		"defaultPosition": 0.06,
		"minPosition": 0.04,
		"maxPosition": 0.08,
		"railMovement": true,
	},
	"res://Items/Weapons/Mosin/Mosin_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/Mosin/Armature/Skeleton3D/Attachments/PU": {
		"defaultPosition": -0.07,
	},
	"res://Items/Weapons/M78/M78_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M78/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.08,
		"minPosition": 0.06,
		"maxPosition": 0.12,
	},
	"res://Items/Weapons/M78/M78_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M78/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.08,
		"maxPosition": 0.13,
	},
	"res://Items/Weapons/M4A1/M4A1_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M4A1/Armature/Skeleton3D/Attachments/Micro": {
		"defaultPosition": 0.08,
		"minPosition": 0.06,
		"maxPosition": 0.1,
	},
}


static func apply(lib) -> void:
	if !lib:
		return

	for id in PATCHES:
		if !lib.patch(lib.Registry.SCENE_NODES, id, PATCHES[id]):
			Out.warning("rig optic patch failed: %s" % id)

