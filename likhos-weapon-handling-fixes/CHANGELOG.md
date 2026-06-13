* fire selector card in inspect mode
* replaced number on ammo and chamber cards with icons 
* fixed state transition jittery due to free look attachment
* unshift interaction tooltip if crosshair is disabled
* fixed hook registration batching
* fixed semi guns firing on reload from ammo check when there is no valid mag to use
* simplified stamina drain logic, added MCM toggle
* lots of refactoring

# 2.15.1730
* rig stow timing tweaks
* added MCM toggle to disable negligent discharges (for all the butterfingers out there)
* click sound refactoring - hopefully fixed missing clicks this time
* other refactorings to simplify and improve performance

# 2.15.1701
* decoupled patrol mode rig position from the free look setting
* modified patrol mode positions + separate branch for pistols
* fixed camera shake sticking on entering binos while firing
* fixed vertical aim smoothing erroneously introduced by the adaptive free look mode
* fixed left arm missing in the raised weapon mode (who even uses that?!) while free look is enabled
* refactored binos state machine
* refactored ammo check and reload state machine
* refactored rig stow state code

# 2.13.1672
* added zoom acceleration and click sound to the binos
* compressed binos grime image to reduce mod size
* fixed reloading while looking down missing left arm
* PEQ-15 laser is now red instead of green

# 2.13.1667
* Binoculars!!! (hold B)

# 2.12.1599
* adjustments for **Adaptive Free Look** to be more fluid / less jumpy
* fixed aim toggling on right click from inventory

# 2.12.1548
* adjusted position of ammo/attachment cards in inspect mode
* hide crosshair on the zone transition prompt (so it doesn't overlap)
* disable weapon stow on transition prompt
* fixed zone transition prompt showing up while in inspect mode

# 2.12.1534
* tweaks for free look mode for smoother, more fluid interactions
* mouse sensitivity transition now lerp() gracefully instead of snapping
* fixed scope shadow in non-PIP mode

# 2.12.1524
* fixed Mosin missing animation for ejecting live round on reload
* fixed Mosin missing animation for ejection of both casing and live round on opening bolt for insertion
* added self damage when trying to aim with optic mounted too close
* reworked handling speed to apply both in and out of the state, added slowed admin speed for Inspecting/Ammo Check/Insert
* tooltip code refactoring

# 2.11.1481
* fixed mag showing empty on reload
* fixed aiming camera position for a number of guns (in PIP mode only)
* POSP can now move on the dovetail rail same way other scopes move on the picatinny rail
* fixed PU position on Mosin (it was way too far forward)
* fixed several vanilla bugs with optic positioning outside of declared min/max rail ranges (HAMR and ACOG on M78 and T2 on M4A1)
* fixed vanilla bug with floating point math when checking rail movement constraints allowing scopes sometimes to move further/less than was intended

# 2.10.1407
* made tooltip override code less aggressive to improve compat with other mods

# 2.10.1405
* scoped sensitivity now scales progressively with magnification level instead of fixed multiplier

# 2.9.1403
* reworked patrol mode into adaptive free look mode
* removed dead MCM toggle for "real scope magnifications"
* fixed deadlock on opening inventory while checking ammo

# 2.8.1288
* moved all the attachment renaming and weight changes into [Likho's tag](https://modworkshop.net/mod/56993) mod

# 2.8.1286
* redone eye relief logic - rail position now works again for altering how close the scope is to the camera
* MCM setting that faked eye relief removed
* all scopes now have realistic eye relief ranges instead of being hardcoded
* scope shadow no longer wobbles as you move, but works as penalty outside declared eye relief (ACOG users beware!)
* scope tooltip now shows actual scope magnification and eye relief values
* moved reticle in front of the scope shadow (as it should be)

# 2.7.1214
* fixed walk speed MCM override not applying correctly

# 2.7.1213
* DOF lerp() for smooth transition on zoom
* reworked magnification ranges + MCM setting (Short, Normalized, Discrete)
* magnification acceleration
* increased scope sway when out of arm stamina
* fixed 870 losing chambered shell on insert preparation
* changed insert preparation for Mosin and 870 to a hold action instead of toggle
* protips for checking mag and inserting more ammo

# 2.5.1191
* reworked scopes magnification, naming and weight
* flashlight now shines on your weapon in inspect mode

# 2.3.1160
* toned down scope noise speed

# 2.3.1158
* hotfix for mag disappearing on reload from ammo check

# 2.3.1156
* Hold breath function! (hold sprint while aiming)
* crosshair is now dynamic + new MCM options
* reworked sprint and crouch to override each other based on last user input
* aim/canted now override sprint
* further WeaponRig refactoring, sound system refactoring
* fixed mag not rendering on reload from no-mag

# 2.0.1109
* major refactoring of the WeaponRig code
* Mosin and 870 can now work the bolt like real guns do, both when empty and full
* All guns now have `cocked` state - you will hear a click when attempting to fire empty, but cocked gun (vanilla does nothing)
* reworked ammo check and reload functionality to trigger off `fire` binding
* reworked ammo check and reload animations to block user actions much less aggressively (cut the block at the tail end)
* reworked PIP FOV calc - it was completely wrong for prism scopes and scaled poorly with eye relief
* changed ADS post hook into replace hook - should zoom more smoothly with less jitter
* brought back setting for `Rail movement` as a modifier for out-of-aim zoom
* dropped ammo obfuscation from the weapon icon - you can use another mod for this
* refactored PIP shader injection for compatibility with other scope shader mods
* added protips