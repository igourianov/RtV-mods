# Likho's Radiola

This mod reworks in-game radio, adding several authentic new stations to listen to and other improvements.

* Created plugin system to distribute new stations later (can be used by other modders)
* Station playback is driven by the wall clock (doesn't reset on activation), as real radio should 
* Realistic static and sound quality for old FM radio
* Radio now plays by default when you find it (adjust chance in MCM)
* Reworked radio interaction to show current state instead of the next action (it was confusing)

## Plugins

This mod is only a shell, it does not contain new stations - grab those separately in the [Downloads](https://modworkshop.net/mod/57722?tab=downloads) section:

* **Doomer Nation** melancholic post-punk, authentic 90s feel - [source](https://www.youtube.com/watch?v=F-9ZOtkWhj0)
* **HardBOSS Radio** hardbass, simple-as - [source](https://www.youtube.com/watch?v=IRcQ70mLz6A)
* **Kolkhoz Punk** gopnik and Russian traditional vibes by Sektor Gaza - [source](https://www.youtube.com/watch?v=GxJeEHkHAnc)

*I do not own the rights to any of this music and make no money from it. All credit to the original artists; please support them directly.*

These packs need to be downloaded separately because they're relatively large and static compared to the shell mod.

## Why not stream directly from youtube?

I wish. Unfortunately Youtube is extremely queer about letting people use their servers as CDN. So the music has to be packaged and distributed.

## [Check out my other mods](https://modworkshop.net/search/mods?query=%22Likho%27s%22&sort=likes)

*Feedback and likes are welcome!*

!!! Creating new station packs

A pack is a standalone mod that appends one station to the Radiola at startup (no hooks, no config). Copy the structure of one of the existing packs and swap the contents:

1. **Audio/** - one mp3 (or ogg) per track. You'll need each track's exact duration in seconds for the next step.
2. **`<name>.tres`** - the station resource.
	* Set `label` to be the station name displayed in game
	* One `[sub_resource]` per track with
		- `source` (path relative to the `.tres`)
		- `title` track title (unused atm)
		- `duration` in seconds **(must be accurate, it drives wall-clock sync)**
	* List every sub-resource in the `tracks` array
	* Set `load_steps` in the header to the total entry count: the 2 scripts + every track + the `[resource]` block
3. **`Main.gd`** - change the `STATION_DATA` path to your `.tres`.
4. **`mod.txt`** - unique `id` matching the folder name, and an `[autoload]` pointing at `Main.gd`.

Zip the folder into a `.vmz` and drop it in `mods/`. The station drops into the radio's tuning cycle after the vanilla one; the core mod is untouched.
!!!