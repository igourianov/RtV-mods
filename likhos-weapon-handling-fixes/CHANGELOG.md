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