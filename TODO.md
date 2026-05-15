# TODO
- food and sleep rework
- redo mod control flow: pipe all input through InputBus.gd, create comain specific handlers, called from the bus, relegate existing scripts to be hooks/overrides only
- play click when attempting to shoot on empty chamber (add cocked status to rig)

# Closed
- MP7 clipping in canted mode - will not fix (missing texture on the gun)
- integrate with Rig and Belt Storage mod - pass; too difficult
- check pip scope being very dark at night - confirmed default game behavior
- integrate with xp and skills mod - wont work; it doesn't publish maxHP var
- AFAK recipe conflict with Crafting Expansion mod - fixed
- rework hand stamina (base on weapon weight) - done
- rework leg stamina (base on inventory weight) - done
- laser dot-ray misaligned - fixed
- split canted rotation on with/without optic - done
- implement canted/aim overriding each other - done
- holding R key to check ammo - done
- show ammo count after ammo check or reload; hide again on firing - pass; offloaded to another mod

