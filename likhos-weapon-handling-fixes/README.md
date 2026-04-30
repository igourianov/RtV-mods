# Likho's VosTac

Road to Vostok mod that adds tactical realism features and fixes a whole host of vanilla bugs related to weapon handling.

Formerly `Likho's Weapon Handling Fixes`. It grew into a major game overhaul.

*Feedback and likes are welcome!*

## New Features
* Major rework of the PIP scope mode for realism
* Canted aim is now independent with optional laser auto-activation in hold mode (disable in MCM)
* Mouse sensitivity scales with zoom and stance (canted uses Aim, LPVO 1× uses Aim, mid/high use Scope/Scope×0.5)
* Movement speeds rescaled and added new breakpoints (see MCM settings)
* Default weapon position changed to patrol mode (rifle rests across chest)
* LPVO zoom accessible without aiming - conflicts with lower/raise weapon - **REBIND**
* Crosshair in idle mode for interactions - auto-disabled when aiming/canted/raised (configure in MCM)
* Ability to toggle secondary optic out of aim with visual cue of the toggle
* Rework of the inspect mode and associated bindings

## Vanilla Fixes
* Ammo check no longer forces weapon into raised position (prior stance preserved)
* Canted aim toggle no longer blocked by interactables
* Manual reload (Mosin, 870) clipping issues fixed (weapon moves to default low position)
* Number of HAMR fixes
* Interactable tooltip no longer blocks vision when aiming around doorways

## PIP scope mode: realism

Vanilla PIP is completely unusable - every scope feels like a "scout" scope. This mod addresses that:
- **Realistic eye relief:** camera parked at proper distance behind rear lens (LPVOs 5cm, fixed scopes 3.5cm)
- **Main camera FOV no longer narrows when scoped** — only the inside of the optic magnifies
- **LPVOs stay "scoped" at 1x** — realistic lens distortion and DOF even at 1x
- **Magnification dialed to real-world values:** prism sights 4x, LPVOs 1.1x/3x/6x
- **Scope DOF reworked:** scales with magnification, near-DOF enabled for foreground/background softening

## Movement speed rework

Rescaled movement speeds and added new break points. You can edit all these values in MCM.
- **Vanilla:** crouch/walk/sprint = 1 / 2.5 / 5
- **Updated:** crouch/walk/sprint = 0.7 / 3 / 6
- **New:** walk-canted/walk-aiming-1x/walk-scoped = 2.25 / 1.8 / 0.9 (defined in MCM as multipliers of walk speed)

## Inspect mode rework

* Fixed and rewrote several overlapping and dangling key bindings and states.
* Rail movement now works only in inspect mode. Rail movement binding is now unused.
* Weapon rotation in inspect mode is now done with the Canted aim binding.
* Stamina drain removed
* Added ammo and attachment cards to the inspect mode (disable via MCM menu)

## HAMR love

HAMR in vanilla is bugged to hell and back. This mod introduces fixes and usability changes for secondary optic mode:
* HAMR's secondary can now be activated from outside aim mode, and it gives the user a visual cue as to current state
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
- `Character.Stamina`

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

# Install / Uninstall

Drop `likhos-weapon-handling-fixes.vmz` into your game's `mods/` folder. On a default Steam install:

```
<Steam>\steamapps\common\Road to Vostok\mods\
```

Launch the game. The mod loader picks it up automatically. The first time you install or update a mod, the loader does a one-shot restart to finish wiring the hooks. After that, no more restarts.

To uninstall simply delete `likhos-weapon-handling-fixes.vmz` from the `mods/` folder and relaunch the game.
