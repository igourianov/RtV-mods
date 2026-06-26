extends "RadioStation.gd"

const PATH := "res://mods/likhos-radiola/Audio/doomer_01.mp3" # https://www.youtube.com/watch?v=cO1o37Dyc8A

func get_tracks() -> Dictionary:
	if !FileAccess.file_exists(PATH):
		return {}
	return {
		AudioStreamMP3.load_from_file(PATH): [
			0.0, # 0:00
			139.0, # 2:19
			340.0, # 5:40
			499.0, # 8:19
			720.0, # 12:00
			864.0, # 14:24
			1093.0, # 18:13
			1266.0, # 21:06
			1430.0, # 23:50
			1612.0, # 26:52
		],
	}


func get_label() -> String:
	return "Doomer Station"
