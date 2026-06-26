# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- Metro Mod Loader v3.2.1 or later (separate install, not bundled with the game)

# Adding music

Place an **OGG Vorbis** file (mono recommended) at `Audio/doomer_01.ogg`, then set the track data in `Scripts/Nodes/DoomerStation.gd`:

```
func get_tracks() -> Dictionary:
	return {
		"res://mods/likhos-radiola/Audio/doomer_01.ogg": [0.0, 187.0, 402.0],
	}
```

Each number is a track's start offset, in seconds, within the file. The last track runs to the end of the file. Add more keys for more files. Files are loaded at runtime via `AudioStreamOggVorbis.load_from_file`, so they do not need a Godot `.import` sidecar to ship inside the mod.

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
