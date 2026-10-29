# POSP whole lit reticle

## Intent

The POSP's reticle illumination in Likho's Battery Powered (BP) lights its whole reticle. Its vanilla texture is fully black, so the lens shaders, which glow only the red channel, light nothing on it.

## Constraints and assumptions

* The vanilla lens shader, BodyCam's patch of it and VosTac's own lens shader all glow `r * intensity` of the `reticle` texture. A texel with no red is a black line at any intensity.
* BP drives illumination only through the lens material's `reticle` and `intensity` uniforms and its rim glow `next_pass`. The lens shader owns placement, shadow and aim fade.
* A lens material is shared by every instance of its sight, so the weapon in hands pushes its state each frame.
* Ruled out: a shipped replacement texture. The red copy is built from the texture on the lens, so a game update or another mod's replacement carries over.
* Ruled out: `Image.compress` on the copy. Export builds ship no BC compressor and the call logs `Parameter "_image_compress_bc_func" is null`.

## Design

`likhos-battery/Scripts/OpticPower.gd`:

* `SIGHTS` lists the POSP as `Sight.SCOPE_WHOLE`.
* `class Authored` caches per lens material its authored `reticle` and `intensity`, plus `whole`, `whole_image` and `whole_task` for the red copy.
* `_whole(lens)`:
	* On the first call it reads `get_image()` on the main thread and queues `_fill_red` on `WorkerThreadPool`.
	* Once the task completes, it waits on the task and runs `ImageTexture.create_from_image`.
	* It returns null until the copy is ready.
* `_fill_red(image)`, a static function run on the worker: `decompress`, `clear_mipmaps`, `convert(RGBA8)`, set every 4th byte (red) to 255, `set_data`, `generate_mipmaps`. Alpha is kept, so only the reticle lines glow.
* States pushed by `_push_state`:

	| State | When | `reticle` | `intensity` |
	|---|---|---|---|
	| `LIT_WHOLE` | lit and powered, copy ready | red copy | authored |
	| `LIT` | lit and powered, copy not ready yet | authored | authored |
	| `UNLIT` | on battery, not lit or not powered | authored | 0, a black reticle |
	| `LIT` | `Scope Power Draw` set to Disabled | authored | authored, black as vanilla ships it |

* The copy stays uncompressed RGBA8. For a 1024² texture that is about 5.6 MB of VRAM with mipmaps. The POSP texture's real size was not checked.

Related, in VosTac: `ScopeCatalog.apply` patches the POSP into a 2-6x variable optic with equal reticle sizes. The FFP rule in `WeaponRig_Optic._update_reticle` (`att.variable && reticleSize.x != reticleSize.z`) therefore treats it as SFP. A lit POSP reticle stays visible over the swing shadow, as intended.

## History

On branch `battery-lens-uniforms`:

* `4a580d6`: BP drives the lens's `reticle` and `intensity` uniforms instead of drawing its own reticle pass.
* `08a0004`: the whole lit reticle is built at runtime on a worker thread from the texture on the lens, instead of a shipped copy.
* `c15549d`: `Image.compress` removed, the copy stays uncompressed.

## Open

* Not yet confirmed in game that the copy displays correctly: lines fully red, no artifacts at the edges.
* `Image.decompress` raised no error at runtime, but its output was not inspected.
