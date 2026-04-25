# Likho's Weapon Handling Fixes

A mod for Road to Vostok that smooths over a few quirks around ammo checking, canted aim and scope positioning.

## What it changes

### Ammo check no longer forces weapon into raised position (bug fix)

Vanilla bug: after an ammo check, the weapon snaps to the raised position regardless of whether you were carrying it raised or lowered before the check.
Fix: the weapon's prior raised/lowered state is captured before the check and restored after, so you stay in whichever stance you were in.

### Canted no longer blocked while looking at an interactable (bug fix)

Vanilla bug: pointing at an interactable (door, item, container) silently disables the canted toggle until you look away. Nothing in the UI hints at this and it's easy to think the keybind is broken.
Fix: the interaction gate on canted is removed, so canted toggles regardless of what you're looking at.

### Canted aim is its own action

Vanilla treats canted as a sub-action of aiming: you have to be aiming first, and releasing aim drops you out of canted.

This mod makes canted independent:

- Press/hold canted from any weapon-ready state. You don't have to enter aim mode first.
- Canted respects your aim-mode setting (hold vs toggle), separately from the aim button.
- Sprinting, reloading or doing an ammo check cancels canted, mirroring how those cancel aim-toggle.
- The canted weapon pose is nudged slightly down so the gun obscures less of the upper screen.

### Canted-hold auto-activates the laser

In **hold aim mode**, holding canted now also turns the equipped laser sight on; releasing canted turns it off. Convenient for quick low-light snap shots without juggling the laser key.

- Only fires in hold mode. Toggle-aim users keep manual laser control as in vanilla.
- If your laser was already on before you entered canted, the mod leaves it alone, no flicker on release.
- The attachment click sound is split into press (in) and release (out) halves, so holding canted feels like holding a physical button: you hear it click in when you engage and click out when you let go.

### PIP scope mode: more realistic, more consistent

Picture-in-picture mode renders the world through the scope as a subviewport rather than zooming the main camera. The intent is to feel like you're actually looking through the optic. Two tweaks push that further:

- **Weapon brought a bit closer to your face when aiming through PIP.** The scope mesh sits closer to the camera, so the lens fills more of the view, like a proper cheek-weld to the eyepiece.
- **Variable scopes behave the same at every magnification (realism).** A real variable optic at 1x is still glass in front of your eye, with the same eye relief, the same depth-of-field characteristics and the same hold-still demands as 2x or 3x. Vanilla pretends 1x = no scope: depth-of-field blur, the scoped sway profile and other "scoped" systems disengage at 1x but engage at 2x and 3x, so dialing magnification flips between two completely different visual modes. The mod keeps "scoped" status on at all zoom levels so 1x, 2x and 3x feel like the same optic at different magnifications, the way they would in real life.
- **Magnification dialed back to usable values across the board.** Vanilla pushes way too much zoom on every level: an LPVO ran ~4× / 7× / 23× across its three settings, and prism sights ran at the same ~23×. That's far beyond what you'd field on these optics in real life and it makes them effectively unusable, the slightest hand wobble swings the reticle off-target. The mod tones the LPVO down at all three settings (now roughly 3× / 5× / 14×) and brings prism sights down to a fixed ~7× so they actually function as the intermediate-range optics they're supposed to be.

> **Mount your scope realistically.** The PIP tweaks are balanced around the scope being mounted at a real-world position: ocular (rear) lens roughly in line with the end of the receiver, as you'd run it on an actual rifle. Sliding the scope too far forward gives you a weird minification effect (the lens shows the world shrunk to a small island in the middle); sliding it too far back puts the camera inside the scope body and you end up looking at the eyepiece interior instead of through it.

### Mouse sensitivity follows the situation

Vanilla picks mouse speed from your **Look / Aim / Scope** sensitivity sliders based on whether you're aiming and scoped. A few cases get the wrong slider; the mod fixes them:

- **Canted aim now uses your Aim sensitivity.** Vanilla flags canted as "not aiming" internally and ends up running the (much faster) Look slider during canted, which makes the pose hard to control. While canted, the mod mirrors your Look slider to your Aim slider; restored on canted exit.
- **Variable-scope sensitivity scales with magnification.** Tunable optics ran a single Scope slider value across all zoom levels, so 1× and 3× had the same mouse feel even though the apparent angular rate differs by ~5×. Now:
   - At 1× (~3× magnification): uses the **Aim** slider, since 1× on an LPVO is effectively a red-dot stance.
   - At 2× (~5× magnification): uses the **Scope** slider, your baseline.
   - At 3× (~14× magnification): uses **Scope × 0.5**, halved so the high-zoom pose stays controllable.

Fixed scopes (prism sights, fixed-magnification optics) are untouched, they keep using your Scope slider directly as in vanilla.

Net effect: tune Look / Aim / Scope once and the mod picks the right slider per situation.

## Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader/wiki) v3.0.1 or later (separate install, not bundled with the game)

## Compatibility

This mod fully replaces two vanilla functions (`Handling.WeaponHandling` and `WeaponRig.AmmoCheck`). Other mods that also try to replace those functions will conflict. Pick one.

It also adds a non-replacing tweak after `WeaponRig.ADS` runs. That coexists with other mods cleanly.

## Install

Drop `likhos-weapon-handling-fixes.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically. The first time you install or update a mod, the loader does a one-shot restart to finish wiring the hooks. After that, no more restarts.

## Uninstall

Delete `likhos-weapon-handling-fixes.vmz` from the `mods/` folder and relaunch the game.
