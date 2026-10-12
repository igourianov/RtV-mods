# Likho's Battery Powered

Removable batteries. Powered lasers. Flicker at low charge.

## Features

* Batteries show their own charge. A device takes exactly the charge of the battery you put in.
* Right-click a charged device and pick `Remove (Batteries)` to get a battery with the device's charge. The device drops to 0%.
* Dropping a battery on a charged device swaps their charge. A device at 0% consumes the battery, same as vanilla.
* Prices are adjusted by charge. A battery is worth its charge and a device loses the price of the charge it is missing. Narva: 180€ at 100%, 80€ at 0%.
* Looted flashlights and lasers spawn with 20-75% charge instead of 25-100% to balance out increased supply.

## Lasers

* Lasers now run on batteries at medium power (drains 1% every 10 sec).
* Drop a battery on a detached laser or straight on the weapon that carries it.
* The `Remove (Batteries)` menu item is offered on a detached laser only.
* The weapon tooltip shows the charge of the attached laser.

## Low charge flicker

* A flashlight dims briefly when its charge drops to 5% and again at every percent below that. In the last percent it flickers continuously until it goes out.
* A laser does the same, but its beam and dot blink off instead of dimming.
* The flashlight flicker used to be part of VosTac. If you run both mods, update VosTac to 3.5.2048 or later, otherwise the flashlight dims twice.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.2 or later
