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
	},
	"res://Items/Weapons/SVD/SVD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/SVD/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.08,
		"railMovement": false,
	},
	"res://Items/Weapons/SVD/SVD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/SVD/Armature/Skeleton3D/Attachments/HMR": {
		"railMovement": false,
	},
	"res://Items/Weapons/SVD/SVD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/SVD/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.14,
		"railMovement": false,
	},
	"res://Items/Weapons/SVD/SVD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/SVD/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.1,
		"railMovement": false,
	},
	"res://Items/Weapons/VSS/VSS_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/VSS/Armature/Skeleton3D/Attachments/POSP": {
		"defaultPosition": 0.06,
	},
	"res://Items/Weapons/VSS/VSS_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/VSS/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.07,
		"maxPosition": 0.12,
	},
	"res://Items/Weapons/VSS/VSS_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/VSS/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.08,
		"maxPosition": 0.1,
	},
	"res://Items/Weapons/VSS/VSS_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/VSS/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.15,
		"maxPosition": 0.17,
	},
	"res://Items/Weapons/VSS/VSS_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/VSS/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.11,
		"maxPosition": 0.14,
	},
	"res://Items/Weapons/MP5SD/MP5SD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5SD/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.04,
		"maxPosition": 0.09,
	},
	"res://Items/Weapons/MP5SD/MP5SD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5SD/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.05,
	},
	"res://Items/Weapons/MP5SD/MP5SD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5SD/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.14,
	},
	"res://Items/Weapons/MP5SD/MP5SD_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5SD/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.09,
		"maxPosition": 0.11,
	},
	"res://Items/Weapons/MP5/MP5_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.04,
		"maxPosition": 0.09,
	},
	"res://Items/Weapons/MP5/MP5_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.14,
	},
	"res://Items/Weapons/MP5/MP5_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.09,
		"maxPosition": 0.11,
	},
	"res://Items/Weapons/MP5K/MP5K_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5K/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.04,
		"maxPosition": 0.09,
	},
	"res://Items/Weapons/MP5K/MP5K_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5K/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.05,
		"maxPosition": 0.07,
	},
	"res://Items/Weapons/MP5K/MP5K_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5K/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.14,
	},
	"res://Items/Weapons/MP5K/MP5K_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP5K/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.09,
	},
	"res://Items/Weapons/KAR-21/KAR-21_223_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/KAR-21/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.02,
		"minPosition": -0.01,
		"maxPosition": 0.08,
	},
	"res://Items/Weapons/KAR-21/KAR-21_308_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/KAR-21/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.02,
		"minPosition": -0.01,
		"maxPosition": 0.08,
	},
	"res://Items/Weapons/KAR-21/KAR-21_223_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/KAR-21/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.02,
		"maxPosition": 0.06,
	},
	"res://Items/Weapons/KAR-21/KAR-21_308_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/KAR-21/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.02,
		"maxPosition": 0.06,
	},
	"res://Items/Weapons/KAR-21/KAR-21_223_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/KAR-21/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.1,
		"maxPosition": 0.13,
	},
	"res://Items/Weapons/KAR-21/KAR-21_308_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/KAR-21/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.1,
		"maxPosition": 0.13,
	},
	"res://Items/Weapons/KAR-21/KAR-21_223_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/KAR-21/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.14,
		"minPosition": 0.05,
		"maxPosition": 0.18,
	},
	"res://Items/Weapons/KAR-21/KAR-21_308_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/KAR-21/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.14,
		"minPosition": 0.05,
		"maxPosition": 0.18,
	},
	"res://Items/Weapons/RK-95/RK-95_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-95/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.1,
		"minPosition": 0.09,
		"maxPosition": 0.16,
	},
	"res://Items/Weapons/RK-95/RK-95_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-95/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.18,
		"maxPosition": 0.22,
	},
	"res://Items/Weapons/RK-95/RK-95_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-95/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.14,
		"maxPosition": 0.18,
	},
	"res://Items/Weapons/RK-62/RK-62_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-62/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.1,
		"minPosition": 0.09,
		"maxPosition": 0.16,
	},
	"res://Items/Weapons/RK-62/RK-62_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-62/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.18,
		"maxPosition": 0.22,
	},
	"res://Items/Weapons/RK-62/RK-62_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-62/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.14,
		"maxPosition": 0.18,
	},
	"res://Items/Weapons/RK-62/RK-62M_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-62M/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.1,
		"minPosition": 0.09,
		"maxPosition": 0.16,
	},
	"res://Items/Weapons/RK-62/RK-62M_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-62M/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.18,
		"maxPosition": 0.22,
	},
	"res://Items/Weapons/RK-62/RK-62M_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/RK-62M/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.14,
		"maxPosition": 0.18,
	},
	"res://Items/Weapons/M4A1/M4A1_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M4A1/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.07,
		"maxPosition": 0.09,
	},
	"res://Items/Weapons/M4A1/M4A1_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M4A1/Armature/Skeleton3D/Attachments/HMR": {
		"maxPosition": 0.07,
	},
	"res://Items/Weapons/M4A1/M4A1_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M4A1/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.15,
		"maxPosition": 0.16,
	},
	"res://Items/Weapons/M4A1/M4A1_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M4A1/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.1,
		"maxPosition": 0.11,
	},
	"res://Items/Weapons/MK18/MK18_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MK18/Armature/Skeleton3D/Attachments/ACOG": {
		"maxPosition": 0.1,
	},
	"res://Items/Weapons/MK18/MK18_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MK18/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.16,
		"minPosition": 0.14,
		"maxPosition": 0.16,
	},
	"res://Items/Weapons/MK18/MK18_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MK18/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.12,
		"maxPosition": 0.12,
	},
	"res://Items/Weapons/HK416/HK416_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/HK416/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.07,
		"maxPosition": 0.1,
	},
	"res://Items/Weapons/HK416/HK416_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/HK416/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.06,
		"maxPosition": 0.07,
	},
	"res://Items/Weapons/HK416/HK416_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/HK416/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.11,
		"maxPosition": 0.12,
	},
	"res://Items/Weapons/HK416/HK416_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/HK416/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.15,
		"maxPosition": 0.16,
	},
	"res://Items/Weapons/MP7/MP7_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP7/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.01,
		"maxPosition": 0.08,
	},
	"res://Items/Weapons/MP7/MP7_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/MP7/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": -0.01,
		"maxPosition": 0.06,
	},
	"res://Items/Weapons/Mosin/Mosin_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/Mosin/Armature/Skeleton3D/Attachments/PU": {
		"defaultPosition": -0.07,
	},
	"res://Items/Weapons/M78/M78_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M78/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.07,
		"minPosition": 0.05,
		"maxPosition": 0.11,
	},
	"res://Items/Weapons/M78/M78_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M78/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.07,
	},
	"res://Items/Weapons/M78/M78_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M78/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.16,
		"maxPosition": 0.19,
	},
	"res://Items/Weapons/M78/M78_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M78/Armature/Skeleton3D/Attachments/Vudu": {
		"minPosition": 0.09,
	},
	"res://Items/Weapons/AKM/AKM_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AKM/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.08,
		"railMovement": false,
	},
	"res://Items/Weapons/AKM/AKM_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AKM/Armature/Skeleton3D/Attachments/HMR": {
		"railMovement": false,
	},
	"res://Items/Weapons/AKM/AKM_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AKM/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.14,
	},
	"res://Items/Weapons/AKM/AKM_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AKM/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.1,
	},
	"res://Items/Weapons/AKS-74U/AKS-74U_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AKS-74U/Armature/Skeleton3D/Attachments/ACOG": {
		"defaultPosition": 0.03,
		"railMovement": false,
	},
	"res://Items/Weapons/AKS-74U/AKS-74U_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AKS-74U/Armature/Skeleton3D/Attachments/HMR": {
		"railMovement": false,
	},
	"res://Items/Weapons/AKS-74U/AKS-74U_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AKS-74U/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.11,
		"minPosition": 0.09,
	},
	"res://Items/Weapons/AKS-74U/AKS-74U_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AKS-74U/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.06,
		"minPosition": 0.05,
		"maxPosition": 0.06,
	},
	"res://Items/Weapons/M4A1/M4A1_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/M4A1/Armature/Skeleton3D/Attachments/Micro": {
		"defaultPosition": 0.08,
		"minPosition": 0.06,
		"maxPosition": 0.1,
	},
	"res://Items/Weapons/AK-12/AK-12_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AK-12/Armature/Skeleton3D/Attachments/ACOG": {
		"maxPosition": 0.12,
	},
	"res://Items/Weapons/AK-12/AK-12_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AK-12/Armature/Skeleton3D/Attachments/HMR": {
		"defaultPosition": 0.09,
		"maxPosition": 0.1,
	},
	"res://Items/Weapons/AK-12/AK-12_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AK-12/Armature/Skeleton3D/Attachments/Leopard": {
		"defaultPosition": 0.18,
		"maxPosition": 0.18,
	},
	"res://Items/Weapons/AK-12/AK-12_Rig.tscn#Handling/Sway/Noise/Tilt/Impulse/Recoil/Holder/AK-12/Armature/Skeleton3D/Attachments/Vudu": {
		"defaultPosition": 0.14,
		"maxPosition": 0.14,
	},
}


static func apply(lib) -> void:
	if !lib:
		return

	for id in PATCHES:
		if !lib.patch(lib.Registry.SCENE_NODES, id, PATCHES[id]):
			Out.warning("rig optic patch failed: %s" % id)

