# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- Metro Mod Loader v3.2.1 or later (separate install, not bundled with the game)

# Adding music

Place an audio file (mono recommended) under `Audio/`, then set the track data in `Scripts/Nodes/DoomerStation.gd`. `get_tracks()` returns a `Dictionary` keyed by the loaded `AudioStream` itself, so the station decides which loader to use:

```
func get_tracks() -> Dictionary:
	var stream := _load_mp3("res://mods/likhos-radiola/Audio/doomer_01.mp3")
	if !stream:
		return {}
	return {
		stream: [0.0, 187.0, 402.0],
	}
```

Each number is a track's start offset, in seconds, within the stream. The last track runs to the end of the stream. Add more keys for more streams. Streams are loaded at runtime via the format's `load_from_file` (e.g. `AudioStreamMP3.load_from_file`, `AudioStreamOggVorbis.load_from_file`), so the files do not need a Godot `.import` sidecar to ship inside the mod.

# Adding a station

Stations are interchangeable playback components. To add one:

1. Create a script under `Scripts/Nodes/` that `extends "RadioStation.gd"` and overrides `get_tracks()` and `get_label()`.
2. Append its `preload(...)` to the `STATIONS` list in `Scripts/Hooks/Radio.gd`.

The interaction cycle extends to `Off -> Vanilla -> Station 0 -> Station 1 -> ... -> Off` automatically. All stations share the `ModRadio` bus.

# Compatibility

Hooks vanilla methods through Metro Mod Loader (declared in `[hooks]`):

- `Radio.gd :: Interact` (replace) - turns the on/off toggle into an Off -> Vanilla -> [custom stations] -> Off cycle. The vanilla station's behavior, clips and play order are left untouched, and it stays on its own audio bus.
- `Radio.gd :: UpdateTooltip` (post) - relabels the interaction prompt with the next station.

Creates a runtime audio bus `ModRadio` (high-pass + low-pass + lo-fi distortion) shared by all custom stations.

Ships the shared mod-lib as `Lib/`, including `AudioChunkPlayer3D.gd` used for playback.

# Configuration

`user://MCM/likhos-radiola/config.ini`:

```
[audio]
static_enabled=true
```

# Install / Uninstall

Drop `likhos-radiola.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically. To uninstall, delete `likhos-radiola.vmz` and relaunch.
