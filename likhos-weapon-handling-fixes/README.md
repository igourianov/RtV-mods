# Likho's Weapon Handling Fixes

A mod for Road to Vostok that fixes several weapon handling bugs and adds realism features.

Now with MCM support!

## New Features
* Major rework of the PIP scope mode for realism
* Canted aim is now independent with optional laser auto-activation in hold mode
* Mouse sensitivity scales with zoom and stance (canted uses Aim, LPVO 1× uses Aim, mid/high use Scope/Scope×0.5)
* Movement speeds rescaled and added new breakpoints
* Default weapon position changed to patrol mode (rifle rests across chest)
* LPVO zoom accessible without aiming - conflicts with lower/raise weapon - **REBIND**
* Crosshair in idle mode for interactions (auto-disabled when aiming/canted/raised)
* Ability to toggle secondary optic out of aim with visual que of the toggle
* Rework of the inspect mode and associated bindings

## Vanilla Fixes
* Ammo check no longer forces weapon into raised position (prior stance preserved)
* Canted aim toggle no longer blocked by interactables
* Manual reload (Mosin, 870) clipping issues fixed (weapon moves to default low position)
* Number of HAMR fixes
* Interactable tooltip no longer blocks vision when aiming around doorways

## PIP scope mode: realism

Picture-in-picture mode renders the world through the scope as a subviewport rather than zooming the main camera. The intent is to feel like you're actually looking through the optic. Two tweaks push that further:

- **Realistic eye relief.** Real magnified optics have a narrow eye-relief window. The mod parks the camera at the proper distance behind the rear lens automatically, so the sight picture stays clean regardless of scope positioning. Eye relief: LPVOs 5cm, fixed scopes 3.5cm.
- **Main camera FOV no longer narrows when scoped.** Vanilla zooms your overall screen FOV in on top of the PIP magnification, a leftover from the pre-PIP zoom era. The result is that the world *around* the scope ring also shrinks toward the center, which never happens looking through real glass. The mod keeps the main camera at your base FOV so only the inside of the optic magnifies, the way a real scope works.
- **LPVOs stay "scoped" at 1x.** Vanilla flips DOF blur, scope sway and other scoped systems off at 1x and back on at higher zoom, so dialing magnification toggles between two different visual modes. A real LPVO is glass in front of your eye at every setting; the mod keeps scoped status on across all zoom levels so all three feel like the same optic at different magnifications.
- **Magnification dialed to real-world values.** Prism sights (HAMR, ACOG) sit at a fixed 4x. LPVOs (Leupold, VUDU) step through 1.1x, 3x and 6x across their low/mid/high settings, in line with the variable optics they're modeled on.
- **Scope depth-of-field reworked.** Vanilla applies a single fixed blur to far distances only, regardless of magnification, leaving anything close to the camera (scope body, receiver, foreground cover) razor-sharp. The mod scales DOF intensity with magnification (1× LPVO setting gets none, higher zoom gets progressively more) and enables near-DOF too, so the foreground softens alongside the background. The result feels closer to how a real magnified optic locks focus at the target distance and lets everything else fall off.

## Movement speed rework

Rescaled movement speeds and added new break points.

**Vanilla:** crouch/walk/sprint = 1 / 2.5 / 5

**Updated:** crouch/walk/sprint = 0.7 / 3 / 6

**New:** walk-canted/walk-aiming-1x/walk-scoped = 2.25 / 1.8 / 0.7

## Inspect mode rework

* Fixed and rewrote several overlapping and dangling key bindings and states.
* Rail movement now works only in inspect mode. Rail movement binding is now unused.
* Weapon rotation in inspect mode is now done with the Canted aim binding.
* Stamina drain removed
* Added ammo check visuals to the inspect mode (disable via MCM menu)

## HAMR love

HAMR in vanilla is bugged to hell and back. This mod introduces fixes and usability changes for secondary optic mode:
* HAMR's secondary can now be activated from outside aim mode, and it gives user visual que as to current state
* Fixed HAMR's secondary optic switch permanently killing PIP plane on other scopes (state wasn't being properly reset)
* Fixed HAMR's secondary optic vertical offset on all AK rifles (not RK), SVD and Vintorez (missing rotation calc)
* Fixed HAMR causing major flickering when toggling secondary on M4A1 (bug with foldable iron sights)

# Why this is one mod and not several

These changes started out as separate mods. The catch is that Road to Vostok's scripts have a handful of "god" methods that fold a lot of unrelated behavior into a single function and mix state mutation with rendering side effects in the same call. Hooking a method through the mod loader is all-or-nothing, you can't override only part of a function. So as soon as one fix needed to touch, say, `Handling.WeaponHandling`, every other tweak that also lives in that method had to ship in the same mod or get clobbered by it. That's how the ammo-check, canted, laser and PIP changes ended up bundled together.

# Known issues

- **Laser beam doesn't line up with the dot at very close range.** On targets right in front of you the visible beam diverges from the projected dot. This is a vanilla bug, not something the mod introduces. Vanilla simply hid it by having the gun model block the close portion of the beam; this mod's tweaked weapon pose moves the gun out of that path, exposing the misalignment.

# Requirements

- Road to Vostok 0.1.1.3 (Godot 4.6.2)
- [Metro Mod Loader](https://github.com/ametrocavich/vostok-mod-loader/wiki) v3.0.1 or later (separate install, not bundled with the game)

# Compatibility

This mod hooks multiple vanilla methods through Metro Mod Loader:

**Replace hooks** (other mods that also replace these will conflict, pick one):

- `Handling.WeaponHandling`
- `WeaponRig._input`

**Pre + Post hooks** (additive, run before/after vanilla, coexist with other mods cleanly):

- `WeaponRig.AmmoCheck` (pre and post)
- `WeaponRig.ADS` (post)
- `WeaponRig._physics_process` (pre)
- `WeaponRig._ready` (post)
- `Camera.ScopeDOF` (post)
- `Controller.MovementStates` (pre and post)
- `Noise._physics_process` (post)
- `Tilt._physics_process` (pre)
- `HUD._ready` (post)
- `HUD._physics_process` (post)
- `Recoil.ApplyRecoil` (post)

**Other hooks:**

- `Character.Stamina`

# Install / Uninstall

Drop `likhos-weapon-handling-fixes.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically. The first time you install or update a mod, the loader does a one-shot restart to finish wiring the hooks. After that, no more restarts.

To uninstall simply delete `likhos-weapon-handling-fixes.vmz` from the `mods/` folder and relaunch the game.
