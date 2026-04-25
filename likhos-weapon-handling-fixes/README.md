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
- **Realistic eye relief regardless of how the scope is mounted.** Real magnified optics have a narrow eye-relief window: mount the scope too far forward or back on the rail and you'd get scope shadow that vignettes the sight picture down to an unusable speck. Rather than restrict where you can position the scope along the rail, the mod parks the camera at the proper distance behind the rear lens automatically, so the picture through the optic stays clean wherever you've slid the scope.
- **Main camera FOV no longer narrows when scoped.** Vanilla zooms your overall screen FOV in on top of the PIP magnification, a leftover from the pre-PIP zoom era. The result is that the world *around* the scope ring also shrinks toward the center, which never happens looking through real glass. The mod keeps the main camera at your base FOV so only the inside of the optic magnifies, the way a real scope works.
- **LPVOs no longer act like red dot at 1x (realism).** A real variable optic at 1x is still glass in front of your eye, with the same eye relief, the same depth-of-field characteristics and the same hold-still demands as 2x or 3x. Vanilla pretends 1x = no scope: depth-of-field blur, the scoped sway profile and other "scoped" systems disengage at 1x but engage at 2x and 3x, so dialing magnification flips between two completely different visual modes. The mod keeps "scoped" status on at all zoom levels so 1x, 2x and 3x feel like the same optic at different magnifications, the way they would in real life.
- **Magnification range tweaked for usability.** Scope magnification values were nudged down a touch so every setting lands in a comfortable, usable range.
- **Dynamic depth-of-field tied to magnification.** Vanilla applies a single fixed scope DOF blur regardless of magnification level. Now the blur scales with the optic's magnification: low-power optics get little to no DOF (matching how a 1× sight feels), while higher-magnification scopes get progressively more blur to convey the shallower depth of field a real magnified optic produces. LPVOs at the low end (1× setting) get no scope DOF at all, since they're effectively a red dot at that zoom.
- **Scope DOF also blurs close objects, not just distant ones.** Vanilla's scope DOF only softens far distances, leaving anything near the camera (the scope body, the weapon receiver, foreground cover) razor-sharp while the background goes soft. Real magnified optics lock focus at the target distance and let *everything* outside that plane fall off, including the foreground. The mod enables near-DOF during PIP scope use so the framing around the optic gently softens too, matching how a magnified optic actually pulls your focus to the target.

### Mouse sensitivity scales with zoom

Vanilla picks mouse speed from your **Look / Aim / Scope** sensitivity sliders based on whether you're aiming and scoped. A few cases get the wrong slider; the mod fixes them:

- **Canted aim now uses your Aim sensitivity.** Vanilla flags canted as "not aiming" internally and ends up running the (much faster) Look slider during canted, which makes the pose hard to control. While canted, the mod mirrors your Look slider to your Aim slider; restored on canted exit.
- **Variable-scope sensitivity scales with magnification.** Tunable optics ran a single Scope slider value across all zoom levels, so a low-power and high-power setting had the same mouse feel even though the apparent angular rate is very different. Now:
   - LPVO at the 1× setting uses the **Aim** slider, since it's effectively a red-dot stance.
   - LPVO at the middle setting uses the **Scope** slider, your baseline.
   - LPVO at the high setting uses **Scope × 0.5**, halved so the high-zoom pose stays controllable.

Fixed scopes (prism sights, fixed-magnification optics) are untouched, they keep using your Scope slider directly as in vanilla.

Net effect: tune Look / Aim / Scope once and the mod picks the right slider per situation.

## Why this is one mod and not several

These changes started out as separate mods. The catch is that Road to Vostok's scripts have a handful of "god" methods that fold a lot of unrelated behavior into a single function and mix state mutation with rendering side effects in the same call. Hooking a method through the mod loader is all-or-nothing, you can't override only part of a function. So as soon as one fix needed to touch, say, `Handling.WeaponHandling`, every other tweak that also lives in that method had to ship in the same mod or get clobbered by it. That's how the ammo-check, canted, laser and PIP changes ended up bundled together.

## Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader/wiki) v3.0.1 or later (separate install, not bundled with the game)

## Compatibility

This mod hooks four vanilla methods through Metro Mod Loader:

**Full replacements** (other mods that also replace these will conflict, pick one):

- `Handling.WeaponHandling`
- `WeaponRig.AmmoCheck`

**Post hooks** (additive, run after vanilla, coexist with other mods cleanly):

- `WeaponRig.ADS`
- `Camera.ScopeDOF`

## Known issues

- **Laser beam doesn't line up with the dot at very close range.** On targets right in front of you the visible beam diverges from the projected dot. This is a vanilla bug, not something the mod introduces. Vanilla simply hid it by having the gun model block the close portion of the beam; this mod's tweaked weapon pose moves the gun out of that path, exposing the misalignment.

## Install

Drop `likhos-weapon-handling-fixes.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically. The first time you install or update a mod, the loader does a one-shot restart to finish wiring the hooks. After that, no more restarts.

## Uninstall

Delete `likhos-weapon-handling-fixes.vmz` from the `mods/` folder and relaunch the game.
