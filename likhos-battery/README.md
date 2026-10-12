# Likho's Battery

Batteries keep their charge and can be taken out of any device that accepts them.

## Features

* Batteries show their own charge. A device takes exactly the charge of the battery you put in.
* Right click a charged device and pick `Remove (Batteries)` to get a battery with the device's charge. The device drops to 0%.
* Dropping a battery on a charged device swaps their charge. A device at 0% consumes the battery, same as vanilla.
* Prices follow charge. A battery is worth its charge and a device loses the price of the charge it is missing. Narva: 180€ at 100%, 80€ at 0%.
* Looted flashlights spawn with 20-75% charge instead of 25-100% to balance out increased supply.
* Lasers run on batteries. A laser drains 1% every 10 seconds while its beam is on, twice as fast in winter, and goes dark at 0%.
* Drop a battery on a detached laser or straight on the weapon that carries one. `Remove (Batteries)` is offered on a detached laser only.
* A laser keeps its charge when you attach and detach it. The weapon tooltip shows the charge of the attached laser.
* Looted lasers spawn with 20-75% charge. A laser found attached to a weapon gets a charge in the same range.
* Flashlights and lasers flicker briefly when their charge drops to 5% and again at every percent below that. In the last percent they flicker continuously.

## Requirements

- Road to Vostok 0.2.0.0 (Godot 4.6.3)
- [Metro Mod Loader (MML)](https://vostokmods.net/mod/metro-mod-loader) v3.4.2 or later
