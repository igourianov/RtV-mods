# Likho's Battery Powered

Removable batteries. Powered lasers and sights. Flicker at low charge.

## Features

* Batteries show their own charge. A device takes exactly the charge of the battery you put in.
* Right-click a charged device and pick `Remove (Batteries)` to get a battery with the device's charge. The device drops to 0%.
* Dropping a battery on a charged device swaps their charge. A device at 0% consumes the battery, same as vanilla.
* Prices are adjusted by charge. A battery is worth its charge and a device loses the price of the charge it is missing. Narva: 180€ at 100%, 80€ at 0%.
* Looted flashlights, lasers and sights spawn with 20-75% charge instead of 25-100% to balance out increased supply.

## Lasers

* Lasers now run on batteries at medium power (drains 1% every 10 sec).
* Drop a battery on a detached laser or straight on the weapon that carries it.
* The `Remove (Batteries)` menu item is offered on a detached laser only.
* The weapon tooltip shows the charge of the attached laser.

## Sights

* Red dot and holographic sights now run on batteries. The dot is on whenever the weapon is in your hands and draws very little: a full battery lasts about 5.5 hours. At 0% there is no dot.
* Vudu, Leopard, HAMR and POSP have switchable reticle illumination on the `Reticle Illumination` binding (default `Y`). Scopes start unlit with a black reticle. A lit reticle empties a battery in about 83 minutes. At 0% the reticle stays black and usable.
* The HAMR's top dot runs off the same battery as its reticle. Unlit, the HAMR drains like a red dot. Lit, a battery lasts about 67 minutes.
* The ACOG is fiber optic lit and the PU has no illumination. Neither needs a battery.
* Drop a battery on a detached sight or straight on the weapon that carries it. On a weapon with a laser and a sight the emptier one takes the battery.
* The `Remove (Batteries)` menu item is offered on a detached sight only.
* The weapon tooltip shows the charge of the attached sight.
* The `Reticle Power Draw` setting in LCM picks the mode:
	- *Vanilla:* no sight draws power. Every reticle looks and works as the game ships it.
	- *Manual:* the binding switches scope illumination per weapon.
	- *Light Sensor:* scope reticles light up on their own from sunset to sunrise and stay black in daylight and in shelters.
* Reticle illumination used to be part of VosTac. If you run both mods, update VosTac to the latest version, otherwise both mods handle the binding.

## Low charge flicker

* A flashlight dims briefly when its charge drops to 5% and again at every percent below that. In the last percent it flickers continuously until it goes out.
* A laser does the same, but its beam and dot blink off instead of dimming.
* A sight does the same: its dot blinks off and a lit reticle blinks to black.
* The flashlight flicker used to be part of VosTac. If you run both mods, update VosTac to 3.5.2048 or later, otherwise the flashlight dims twice.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.2 or later
- [Likho's Config Manager](https://vostokmods.net/mod/likhos-config-manager) (LCM). Optional, the mod runs on its default settings without it.
