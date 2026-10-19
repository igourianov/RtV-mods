# Likho's Debug

## Intent

A new mod, Likho's Debug (`likhos-debug`), that hosts tools for debugging the other mods. It is a developer tool, not a gameplay mod.

Its first feature is a free camera. One key combo freezes the player and the world in place and hands the view to a camera that flies freely. The weapon rig stays exactly where the player's camera left it, so its positioning (idle pose, aim, collision, free look holds) can be inspected from a third person view. The same combo returns to normal play with nothing changed.

## Constraints and assumptions

* The weapon rig `Core/Camera/Manager` is a child of the rendering camera `Core/Camera` (vanilla `Camera.gd`), which follows the player's chain camera under `Controller/Pelvis/Riser/Head/...`. Moving the rendering camera would carry the rig with it, so the free view comes from a separate `Camera3D`.
* The game itself freezes the world with `get_tree().paused = true` while the settings menu is open (`UIManager.ToggleSettings`). A paused tree stops the controller, the rendering camera follow, the rig, AI, physics, animation, audio and the `Simulation` time of day, and blocks all game input handlers. The free camera uses the same freeze.
* Shader `TIME` keeps running under a paused tree, so wind on foliage and similar shader motion continues. Accepted.
* Weapon materials use plain world space shaders (`Standard.gdshader`, no viewmodel projection), so the rig renders correctly from any camera that sees its render layers. The rig may sit on its own render layer (the separate `Flash/FPS` light hints at it), so the free camera takes the rendering camera's cull mask. Unverified: the build confirms the rig is visible from the free camera.
* The `Input` singleton and nodes with `PROCESS_MODE_ALWAYS` keep working under a paused tree, so the mod reads its toggle and the free camera controls while everything else is frozen.
* Assumption, unverified: an autoload only mod with no `[hooks]`, `[script_extend]` or `[registry]` still has its autoload instantiated by the mod loader. The build confirms it from `godot.log`.
* The toggle is a hardcoded Alt+F7, hard to press by accident and free of system wide Windows shortcuts. A function key is used because vanilla actions match key presses regardless of modifiers, so a combo on a letter bound to a game action (e.g. F for flashlight) would also trigger that action on entry.
* Alt alone is bound by default to Secondary Optic and Fast Equip, so pressing Alt before F7 can switch the secondary optic just before the freeze. Accepted.
* The free camera enters only in game: a map with `Core/Camera` loaded, no settings menu or inventory open, not dead, transitioning or caching. Exit is always allowed.
* Ruled out: `Engine.time_scale = 0`. Input driven code keeps running with it, so mouse look would still turn the player and move the rig.
* Ruled out: `gameData.freeze`. It stops only the player, while AI and time of day keep going.
* Ruled out: the game keybind menu for the toggle. The vanilla rebind UI captures single keys, so a rebind would drop the modifier protection, and it needs `Inputs.gd` hooks.
* Ruled out: hiding the HUD while the free camera is active. The UI stays as it is.
* Ruled out: settings. The mod has no config and no LCM or MCM integration.
* Ruled out: `README.md`, `INSTRUCTIONS.md` and a changelog. The mod is not distributed.

## Scope

Owned:

* `likhos-debug/mod.txt`: mod identity and the autoload. No hooks.
* `likhos-debug/Scripts/Main.gd`: the autoload, extending mod-lib `Main.gd`. Owns the toggle, the freeze and the free camera lifecycle.
* `likhos-debug/Scripts/FreeCam.gd`: the free camera node and its flight controls.

Context only:

* `mod-lib/Main.gd`, `mod-lib/Out.gd`: base class and logging, shipped as `Lib/` by `build.ps1`.
* Vanilla `src/Scripts/Camera.gd`, `Controller.gd`, `RigManager.gd`: the camera chain and the rig parenting.
* Vanilla `src/Scripts/UIManager.gd`: the settings menu tree pause the freeze follows.
* Vanilla `src/Scripts/GameData.gd` (the `res://Resources/GameData.tres` resource): the `settings`, `interface`, `isDead`, `isTransitioning`, `isCaching`, `lookSensitivity` and `mouseMode` state read by the mod.

## Solution

### Mod

`likhos-debug` follows the layout of the other mods: `mod.txt` with name "Likho's Debug", id `likhos-debug`, prefix `[likho-debug]` and an autoload `LikhosDebug` pointing at `Scripts/Main.gd`. It declares no hooks and no registry use. It is not published, so it has no `[updates]` section. Further debug tools land as more scripts under `Scripts/`, owned by `Main`.

### Main: toggle and freeze

`Main` runs with `PROCESS_MODE_ALWAYS` and watches for Alt+F7 in its input handler, consuming the event.

Entering, when the in game conditions hold:

* It pauses the tree.
* It creates a `FreeCam` under the current scene, placed at the rendering camera's global transform, and makes it the current camera.

Exiting:

* It frees the `FreeCam`, which returns the view to the rendering camera.
* It unpauses the tree.

The player, the rig and the world resume from exactly the frame they froze on. `Main` also exits cleanly if the scene unloads while the free camera is active, so a stale pause never survives a map change.

### FreeCam

`FreeCam` is a `Camera3D` with `PROCESS_MODE_ALWAYS`. On creation it takes the rendering camera's field of view, near and far planes, cull mask and environment, so the rig and world render as the player saw them. It takes no camera attributes, so there is no depth of field blur in the free view.

Controls while active, with the mouse kept captured:

* Mouse look turns the camera, yaw around world up and pitch clamped short of straight up and down, at the game's `lookSensitivity` and following its mouse inversion setting (`mouseMode`).
* The game's `forward`, `backward`, `left` and `right` actions fly the camera along its view, `jump` and `crouch` move it straight up and down, and `sprint` flies faster. Reading the game's actions keeps the user's rebinds.
* Flight speed is slow enough at base to position the camera within centimeters of the rig.

Movement uses real frame time, since the paused tree still delivers `_process` delta to always processing nodes.

## Tradeoffs

* Tree pause over a selective freeze: one call freezes everything, matching the game's own settings pause, at the cost of shader time still running and no way to let selected systems keep animating.
* A separate camera over moving the rendering camera: the rig stays in place without touching vanilla scripts or hooks, at the cost of copying the rendering camera's projection, cull mask and environment and losing its camera attributes.
* Hardcoded key over a bindable action: safe from accidental presses and no hooks, at the cost of no rebinding.
