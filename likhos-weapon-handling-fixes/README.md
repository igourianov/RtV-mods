# Likho's Weapon Handling Fixes

A mod for Road to Vostok that smooths over a few quirks around ammo checking, canted aim and scope positioning.

## Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader/wiki) v3.0.1 or later (separate install, not bundled with the game)

## Install

Drop `likhos-weapon-handling-fixes.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically. The first time you install or update a mod, the loader does a one-shot restart to finish wiring the hooks. After that, no more restarts.

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
- Placeholder feedback sound: the auto-toggle currently hijacks the UI click effect at reduced volume. A dedicated laser tap sound is planned for a future release.

### PIP scope mode: more realistic, more consistent

Picture-in-picture mode renders the world through the scope as a subviewport rather than zooming the main camera. The intent is to feel like you're actually looking through the optic. Two tweaks push that further:

- **Weapon brought closer to your face when aiming through PIP.** The scope mesh sits closer to the camera, so the lens fills more of the view, like a proper cheek-weld to the eyepiece.
- **Variable scopes behave the same at every magnification.** Vanilla treats 1x on a variable optic as not-scoped: scope depth-of-field blur, the scoped sway profile and a few other "scoped" systems disengage at 1x but engage at 2x and 3x. Toggling magnification flips the entire visual treatment, which is jarring. The mod keeps "scoped" status on at all zoom levels so 1x, 2x and 3x feel consistent.

## Compatibility

This mod fully replaces two vanilla functions (`Handling.WeaponHandling` and `WeaponRig.AmmoCheck`). Other mods that also try to replace those functions will conflict. Pick one.

It also adds a non-replacing tweak after `WeaponRig.ADS` runs. That coexists with other mods cleanly.

## Uninstall

Delete `likhos-weapon-handling-fixes.vmz` from the `mods/` folder and relaunch the game.
