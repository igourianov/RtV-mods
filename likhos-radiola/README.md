# Likho's Radiola

This mod reworks in-game radio, adding several authentic new stations to listen to and other improvements.

[Immersive implementation](https://www.youtube.com/watch?v=lP3qr8lhHIU). No custom items or UI. Hooks directly into existing radio item. 

* Created plugin system to distribute new stations later (can be used by other modders)
* Station playback is driven by the wall clock (doesn't reset on activation), as real radio should 
* Realistic static and sound quality for old FM radio
* Radio now plays by default when you find it (adjust chance in MCM)
* Reworked radio interaction to show current state instead of the next action (it was confusing)

## Plugins

This mod is only a shell, it does not contain new stations - grab those separately in the Files section:

* **Doomer Nation** melancholic post-punk, authentic 90s feel - [source](https://www.youtube.com/watch?v=F-9ZOtkWhj0)
* **HardBOSS Radio** hardbass, simple-as - [source](https://www.youtube.com/watch?v=IRcQ70mLz6A)
* **Kolkhoz Punk** gopnik and Russian traditional vibes by Sektor Gaza - [source](https://www.youtube.com/watch?v=GxJeEHkHAnc)
* **Sovietwave FM** synth retro-futurism - [source](https://www.youtube.com/watch?v=DMoCM_FgLP8)

*I do not own the rights to any of this music and make no money from it. All credit to the original artists; please support them directly.*

These packs need to be downloaded separately because they're relatively large and static compared to the shell mod.

## Why not stream directly from youtube?

I wish. Unfortunately Youtube is extremely queer about letting people use their servers as CDN. So the music has to be packaged and distributed.

## Custom station pack

Station packs are very easy to create. Just need a bunch of mp3/ogg files and a small loader script. Zip it up and you're done. Load order shouldn't matter.

Mod structure:
```
my-station-root/
├── mod.txt
├── Main.gd
└── Audio/
    └── multiple mp3/ogg files
```

### mod.txt
```
[mod]
name="My Mod name"
id="my-station-mod"
version="1.0.1"

[autoload]
MyStationLoader="res://mods/my-station-root/Main.gd"
```

### Main.gd
```
extends Node

func _ready() -> void:
	var RadioRegistry = load("res://mods/likhos-radiola/Scripts/RadioRegistry.gd")
	if !RadioRegistry:
		push_warning("Likho's Radiola not installed; station skipped")
		return
	var audio_dir: String = get_script().resource_path.get_base_dir().path_join("Audio")
	RadioRegistry.register_dir("My Station Name", audio_dir)
```
