# VSS laser mount

## Intent

The VSS accepts the green laser (`OZ5`). Vanilla gives the VSS no laser attachment point: the item is not in the weapon's compatibility list and none of the VSS scenes carries a node for it. The laser sits under the barrel, sunk into the suppressor far enough that the missing clamp is not obvious.

## Constraints and assumptions

* The green laser is the item with `file = "OZ5"`. The other laser, `ANPEQ`, is recolored red by VosTac and is not part of this.
* Vanilla resolves an attachment by node name. Every surface that shows a weapon looks under it for a child named after the attachment's `file` and shows or hides it:

	| Surface | Lookup | Missing node |
	|---|---|---|
	| First person rig | `RigManager.UpdateRig`, under `rig.attachments` | Engine error on `get_node`, no laser |
	| World pickup | `Pickup.UpdateAttachments`, under `Attachments` | Silent, no laser model |
	| AI weapon | `AI.gd` weapon setup, under the weapon's `Attachments` | Logs `AI: Attachment not found` and returns, which skips the rest of the weapon setup |
	| Inventory sprite | `Item.UpdateAttachments`, under the tetris sprite | Silent, no laser on the icon |

* An AI picks a random entry of its weapon's `compatible` list as an attachment, at a 5% chance or always for variants with `forceAttachment`, and needs `LOD0` and `LOD1` children on the node it finds. No AI carries the VSS, so this lookup does not apply to this mount. A weapon that AIs do carry needs its pickup node in place before it gains a compatible attachment.
* `compatible[0]` of a weapon is read as its magazine by `AI.gd`. The laser goes after the existing entries.
* Vanilla ships two 3D scenes for the laser. `OZ5_Active.tscn` is the rig version: the mesh, the beam, the point and the `Laser.gd` script. `OZ5_Static.tscn` is the pickup version: `LOD0` and `LOD1` only. Hosts such as the AK-12 instance them under `Attachments` with a transform and nothing else.
* The VSS rig and the VSS pickup share one local frame under `Attachments`. Every vanilla optic has the same transform in `VSS_Rig.tscn` and `VSS.tscn`. One placement serves both scenes.
* `Laser.gd` and VosTac's `Hooks/Laser.gd` both reach the rig through the laser node's `owner`. A node added at runtime has no owner unless it is set, so the rig laser's owner is the rig.
* `Hooks/Laser.gd` converges the beam on the weapon's fire line from wherever the emitter sits, so a placement under the barrel needs no aiming correction.
* `RigManager` adds a rig to the tree and only then calls `UpdateRig`, so a node added in the `weaponrig-_ready-post` hook is found by the first update.
* Every vanilla caller of `Pickup.UpdateAttachments` (dropping, placing and loading shelter items) adds the pickup to the tree first, so a node added in the `pickup-_ready-post` hook is in place.
* A vanilla method is hookable only when the mod's `mod.txt` lists it under `[hooks]`.
* Vanilla shows a laser on the inventory icon of the weapons that host it. A weapon's `tetris` scene is its icon sprite with one hidden child sprite per attachment, named after the attachment's `file`. The attachment's own `tetris` scene, `OZ5_2x1.tscn` for the laser, is the sprite instanced there.
* An item's `tetris` is a `PackedScene` shared by every inventory instance of the item, so a sprite that vanilla should find has to be in the scene itself. The scene is not edited in place: a copy with the extra sprite is packed and set as the item's `tetris` through the `ITEMS` registry. Only nodes owned by the scene root survive packing.
* The VSS icon and the laser icon are both drawn side on with the muzzle to the right. On the VSS icon the suppressor is the right hand quarter, 24 px thick.
* `likhos-second-hand` shrinks the VSS icon through scale and offset fields that apply to the weapon sprite, so child sprites follow.
* Ruled out: a clamp or rail model. The laser clips into the suppressor instead.
* Ruled out: the `ANPEQ` and any weapon other than the VSS.
* Ruled out: an LCM setting for the mount. It is always on.
* Ruled out: replacing or cloning `VSS_Rig.tscn` or `VSS.tscn`. The nodes are added to live instances.

## Scope

Owned:

* `likhos-vostac/Scripts/AttachmentMounts.gd`: which weapon gains which attachment, where it sits, the compatibility, the nodes on a rig and on a pickup and the sprite on the inventory icon.
* `likhos-vostac/Scripts/Hooks/WeaponRig.gd`: only the call that mounts the attachments on a rig when it becomes ready.
* `likhos-vostac/Scripts/Hooks/Pickup.gd`: the pickup hook, which mounts the attachments on a pickup when it becomes ready.
* `likhos-vostac/Scripts/Main.gd`: applying the compatibility on setup and registering the pickup hook.
* `likhos-vostac/mod.txt`: only the `[hooks]` line that opts into `Pickup._ready`.
* `likhos-vostac/README.md` and `likhos-vostac/CHANGELOG.md`: the lines about the VSS laser and the new hook.

Context only:

* `likhos-vostac/Scripts/RigOpticPatches.gd` and `WeaponPatches.gd`: the form a VosTac data table takes. A static module at the `Scripts/` root with a constant table and an `apply(lib)` called from `Main.setup`.
* `likhos-vostac/Scripts/Hooks/WeaponRig.gd` beyond that one call: the handler nodes it injects into a rig.
* `likhos-vostac/Scripts/Hooks/Laser.gd`: toggling, auto on and convergence of every `Laser.gd` instance, including this one.
* `likhos-magdump/Scripts/CompatTable.gd`, `RigVisual.gd` and `Pickup.gd`: the pattern followed here. A compatibility table, a sprite baked into a repacked copy of the weapon's `tetris` scene, nodes added to the live rig in `weaponrig-_ready-post` and to the live pickup in `pickup-_ready-post`.
* `likhos-tag/Scripts/Catalog.gd` and `likhos-second-hand/Scripts/Patches.gd`: patch other fields of the `VSS` and `OZ5` items through the same registry.
* `mod-lib/Main.gd`: `register_hook`.
* Vanilla `src/Scripts/RigManager.gd`, `Pickup.gd`, `AI.gd`, `Item.gd`, `Laser.gd` and the scenes under `src/Items/Weapons/VSS/` and `src/Items/Attachments/OZ5/`.

## Solution

### Mount table

`AttachmentMounts.gd` is a static module like `RigOpticPatches.gd`. It holds a table keyed by weapon `file`, then by attachment `file`. An entry names the attachment's rig scene, its pickup scene and its placement, a transform in the weapon's `Attachments` frame. It also names the attachment's icon scene and its placement on the weapon's icon, a 2D transform in the frame of the weapon sprite. The table has one entry: `VSS` with `OZ5`, using `OZ5_Active.tscn`, `OZ5_Static.tscn` and `OZ5_2x1.tscn`.

The placement puts the laser under the suppressor ahead of the handguard, with its mounting face turned up into the suppressor and sunk into it, so the body reads as clamped on and the gap a rail would fill is hidden. The emitter stays clear of the suppressor. The icon placement mirrors it: the laser sprite is flipped upside down under the suppressor, at the scale that matches the weapon icon. The values are tuned in game.

### Compatibility

`Main.setup` applies `AttachmentMounts` next to the other patch tables. It extends each table weapon's `compatible` list with its table attachments through the `ITEMS` registry, after the existing entries. From there vanilla handles everything about the item: dragging the laser onto the VSS, removing it, one laser per weapon, the compatibility list in the tooltip and the value of the nested item.

### Rig

`Hooks/WeaponRig.gd` already handles `weaponrig-_ready-post`. There it hands the rig to `AttachmentMounts`. For a rig whose weapon is in the table, `AttachmentMounts` adds an instance of each attachment's rig scene under `rig.attachments`, named after the attachment's `file`, hidden, at the table placement and owned by the rig. `RigManager.UpdateRig` then shows it when the laser is nested in the weapon and hides it otherwise, as for any vanilla host. `Hooks/Laser.gd` treats it as any other laser.

### Pickup

`Hooks/Pickup.gd` handles `pickup-_ready-post` and hands the pickup to `AttachmentMounts`. For a pickup whose item is in the table, `AttachmentMounts` adds an instance of each attachment's pickup scene under the pickup's `Attachments`, named after the attachment's `file`, hidden, at the table placement. `Pickup.UpdateAttachments` shows it on a dropped or placed weapon that has the laser nested.

### Inventory icon

On setup, together with the compatibility, `AttachmentMounts` gives each table weapon a `tetris` scene that carries a sprite for each table attachment: an instance of the attachment's icon scene, named after the attachment's `file`, hidden, at the table's icon placement and drawn behind the weapon sprite. Drawing it behind hides the part of the laser that overlaps the suppressor, the way the 3D placement sinks the clamp. `Item.UpdateAttachments` then shows it on a weapon that has the laser nested. The compatibility and the `tetris` scene reach the registry as one patch of the weapon, so a weapon never gains the attachment without its icon sprite.

A weapon scene that already carries a node of that name keeps its own, on the rig, on the pickup and on the icon alike.

### Release notes

* The README lists the VSS laser mount under Weapons & Handling and `Pickup._ready` (post) with the other hooks under Compatibility.
* The changelog entry says the VSS accepts the OZ5 laser, mounted under the barrel.

### Observable result

* The laser can be dragged onto a VSS in the inventory and removed again. The VSS tooltip lists it as compatible.
* With the VSS in hands the laser body shows under the suppressor, partly sunk into it. The laser key switches the green beam and dot on and off.
* The dot converges on the point of aim and canted aim switches the laser on, as on any other weapon.
* A VSS dropped with the laser attached shows it on the world model.
* A VSS without the laser looks as in vanilla everywhere.
* The inventory icon of a VSS with the laser attached shows it under the suppressor, in the inventory grid and in the weapon slot.

## Tradeoffs

* Nodes added to live instances through `_ready` hooks over a replaced rig or pickup scene. The cost is a dependency on vanilla adding the instance to the tree before it updates the attachments, and a hook that runs for every pickup in the world. It avoids shipping a copy of a 5 MB vanilla scene that breaks on every game update.
* The vanilla laser models with no clamp over new mount geometry. The cost is a laser that visibly intersects the suppressor on close inspection.
* A sprite baked into a repacked copy of the `tetris` scene over a hook that adds it to every inventory item instance. The cost is that the weapon's `tetris` is replaced as a whole, so another mod that sets the VSS `tetris` without building on the current value drops the laser sprite or loses its own.
* A table with one entry over VSS and OZ5 written into the code. The cost is a little indirection now. It matches how VosTac states per weapon data and takes a second mount without new code.
* VosTac as the owner over a standalone mod. The cost is that the mount is not available without the rest of VosTac.
