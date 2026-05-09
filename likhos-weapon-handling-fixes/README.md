# Likho's VosTac

Road to Vostok mod that adds tactical realism features and fixes a whole host of vanilla bugs related to weapon handling.

Formerly `Likho's Weapon Handling Fixes`. It grew into a major game overhaul.

### New Features
* Major rework of the PIP scope mode for realism
* Reworked arm and leg stamina mechanics
* Canted aim is now independent with optional laser auto-activation in hold mode (disable in MCM)
* Mouse sensitivity scales with zoom and stance (canted uses Aim, LPVO 1× uses Aim, mid/high use Scope/Scope×0.5)
* Movement speeds rescaled and added new breakpoints (see MCM settings)
* Default weapon position changed to patrol mode (rifle rests across chest)
* LPVO zoom accessible without aiming - conflicts with lower/raise weapon - **REBIND** or change setting in MCM
* Crosshair in idle mode for interactions - auto-disabled when aiming/canted/raised (configure in MCM)
* Ability to toggle secondary optic out of aim with visual cue of the toggle
* Rework of the inspect mode and associated bindings
* Weapon handling speed now scales with weight and aim stance (disable in MCM)
* Added explicit bindings to the base game settings for optic zoom in/out (it was hardcoded to mouse wheel)

### Vanilla Fixes
* Ammo check no longer forces weapon into raised position (prior stance preserved)
* Canted aim activation no longer blocked by interactables
* Interactable tooltip no longer blocks vision when aiming around doorways
* Manual reload (Mosin, 870) clipping issues fixed (weapon moves to default low position)
* Number of HAMR fixes
* Fixed Mosin ending up in weird state (mag + 0) after closing the bolt. Now both live round and spent casing are always ejected when opening bolt.
* Fixed laser ray misaligned with collision dot. You may notice that bullet holes are now very slightly offset from the laser dot - that's how real lasers work.

### PIP scope mode: realism

Vanilla PIP is completely unusable - every scope feels like a "scout" scope. This mod addresses that:
- **Realistic eye relief:** camera parked at proper distance behind rear lens (LPVOs 5cm, fixed scopes 3.5cm)
- **Main camera FOV no longer narrows when scoped** — only the inside of the optic magnifies
- **LPVOs stay "scoped" at 1x** — realistic lens distortion and DOF even at 1x
- **Magnification dialed to real-world values:** prism sights 4x, LPVOs 1.1x/3x/6x
- **Scope DOF reworked:** scales with magnification, near-DOF enabled for foreground/background softening
- **PIP MSAA matches main viewport:** the optic's SubViewport now mirrors the antialiasing settings used by the rest of the game - vanilla left it disabled (disable in MCM if it causes performance issues)
- **NVG-aware PIP blur:** when night vision is active and you aim a magnified optic, the PIP image will now blur. Real scopes cannot work under NVG because of eye relief differences (disable in MCM)

### Stamina and movement

Both stamina bars are now dynamic and much more realistic. There is also now a dynamic delay for beginning recovery after use.

* Arm stamina drain scales with the weight of the gun held and position it is held in (canted=slower; aim zoomed=faster)
* Arm stamina recovery and recovery delay scales with the Energy stat
* Crouch halves aim stamina drain
* Leg stamina drain scales with the inventory weight
* Leg stamina recovery and recovery delay scales with the Hydration stat
* Overweight, Fracture and Leg Stamina=0 now block sprinting completely
* Sprint now overrides crouch, so you can panic GTFO when discovered sneaking about

### Handling speed 

This mod changes weapon handling speed (how fast you transition into desired state) based on stance and optic equipped:

* Default = 100% (vanilla)
* Aim into a red dot = 115%
* Canted aim = 130%
* LPVO at 1x = 105%
* Magnified scope = 80%

### Movement speed rework

Rescaled movement speeds and added new break points. You can edit all these values in MCM.
- **Vanilla:** crouch/walk/sprint = 1 / 2.5 / 5
- **Updated:** crouch/walk/sprint = 0.7 / 3 / 7
- **New:** walk-canted/walk-aiming-1x/walk-scoped = 2.25 / 1.8 / 0.9 (defined in MCM as multipliers of walk speed)

### Inspect mode rework

* Fixed and rewrote several overlapping and dangling key bindings and states.
* Rail movement now works only in inspect mode. Rail movement binding is now unused.
* Weapon rotation in inspect mode is now done with the Canted aim binding.
* Stamina drain removed
* Added ammo and attachment cards to the inspect mode (disable via MCM menu)

### HAMR love

HAMR in vanilla is bugged to hell and back. This mod introduces fixes and usability changes for secondary optic mode:
* HAMR's secondary can now be activated from outside aim mode, and it gives the user a visual cue as to current state
* Fixed HAMR's secondary optic switch permanently killing PIP plane on other scopes (state wasn't being properly reset)
* Fixed HAMR's secondary optic vertical offset on all AK rifles (not RK), SVD and Vintorez (missing rotation calc)
* Fixed HAMR causing major flickering when toggling secondary on M4A1 (bug with foldable iron sights)

## Why this is one mod and not several

These changes started out as separate mods. The catch is that Road to Vostok's scripts have a handful of "god" methods that fold a lot of unrelated behavior into a single function and mix state mutation with rendering side effects in the same call. Hooking a method through the mod loader is all-or-nothing, you can't override only part of a function. So as soon as one fix needed to touch, say, `Handling.WeaponHandling`, every other tweak that also lives in that method had to ship in the same mod or get clobbered by it. That's how the ammo-check, canted, laser and PIP changes ended up bundled together.

## [Check out my other mods](https://modworkshop.net/search/mods?query=%22Likho%27s%22&sort=likes)

*Feedback and likes are welcome!*
