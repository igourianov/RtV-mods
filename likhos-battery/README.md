# Likho's Battery Powered

Removable batteries. Powered lasers and sights. Flicker at low charge.

## Features

* Batteries show their own charge. A device takes exactly the charge of the battery you put in.
* Lasers and sights now run on batteries, like flashlights.
* Right-click a charged device and pick `Remove (Batteries)` to get a battery with the device's charge. The device drops to 0%. A laser or sight has to be detached from the weapon first.
* Dropping a battery on a charged device swaps their charge. A device at 0% consumes the battery, same as vanilla.
* A battery can also be dropped straight on a weapon that carries a laser or sight. On a weapon with both, the emptier one takes it.
* The weapon tooltip shows the charge of every attached laser and sight.
* Prices are adjusted by charge. A battery is worth its charge and a device loses the price of the charge it is missing. Narva: 180€ at 100%, 80€ at 0%.
* Looted flashlights, lasers and sights spawn with 20-75% charge instead of 25-100% to balance out increased supply.

## Lasers

* Lasers run at medium power (drains 1% every 10 sec while the beam is on).
* The `Laser Power Draw` setting in LCM:
	- *Disabled:* lasers draw no power and work at any charge, as the game ships them.
	- *Enabled:* a laser needs charge and drains it while the beam is on.

## Sights

* On red dot and holographic sights the dot is on whenever the weapon is in your hands and draws very little: a full battery lasts about 5.5 hours. At 0% there is no dot.
* Vudu, Leopard, HAMR and POSP have switchable reticle illumination on the `Reticle Illumination` binding (default `Y`). Scopes start unlit with a black reticle. A lit reticle empties a battery in about 83 minutes. At 0% the reticle stays black and usable.
* The HAMR's top dot runs off the same battery as its reticle. Unlit, the HAMR drains like a red dot. Lit, a battery lasts about 67 minutes.
* The ACOG is fiber optic lit and needs no battery. Its reticle is as bright as the light around you: full in open daylight, dimmer under cloud, at dusk and in shade, and down to a faint tritium glow in the dark.
* The PU has no illumination and needs no battery.
* The `Red Dot Power Draw` setting in LCM:
	- *Disabled:* dots draw no power and always show, as the game ships them.
	- *Always On:* a dot needs charge and drains it while the weapon is in your hands.
* The `Scope Power Draw` setting in LCM:
	- *Disabled:* scope reticles draw no power and look as the game ships them.
	- *Manual:* the binding switches scope illumination per weapon.
	- *Light Sensor:* scope reticles light up on their own from sunset to sunrise and stay black in daylight and in shelters.
* Reticle illumination used to be part of VosTac. If you run both mods, update VosTac to the latest version, otherwise both mods handle the binding.

## Low charge flicker

* QoL feature to let the user know visually when charge is running out.
* Flashlights, lasers and sights flicker briefly at 5% charge and every % point below that.
* In the last percent they flicker continuously until they go out.
* The flashlight flicker used to be part of VosTac. If you run both mods, update VosTac to 3.5.2048 or later, otherwise the flashlight dims twice.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.2 or later
- [Likho's Config Manager](https://vostokmods.net/mod/likhos-config-manager) (LCM). Optional, the mod runs on its default settings without it.
