
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
* All guns now have `cocked` state - you will hear a click with attempting to fire empty, but cocked gun (vanilla does nothing)
* reworked ammo check and reload functionality to trigger of `fire` binding
* reworked ammo check and reload animations to block user actions much less aggressively (cut the block at the tail end)
* reworked PIP FOV calc - it was completely wrong for prism scopes and scaled poorly with eye relief
* changed ADS post hook into replace hook - should zoom smoother with less jitter
* brought back setting for `Rail movement` as a modifier for out-of-aim zoom
* dropped ammo obfuscation from the weapon icon - you can use another mod for this
* refactored PIP shader injection for compatibility with other scope shader mods
* added protips