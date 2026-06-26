extends "RadioStation.gd"

# The doomer station: melancholic background music. All behavior lives in the
# RadioStation base; this only supplies the track data and the display label.


func get_tracks() -> Dictionary:
	return {
		# https://www.youtube.com/watch?v=cO1o37Dyc8A
		"res://mods/likhos-radiola/Audio/doomer_01.mp3": [
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
