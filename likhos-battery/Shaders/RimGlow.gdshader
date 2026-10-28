shader_type spatial;
render_mode shadows_disabled;

// A scope with its illumination running shows it on the rim of its lens while the reticle is faded out of view.
// Kept apart from the reticle pass, which draws under a vanilla lens. The lens is opaque out of aim.

uniform float opacity : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform bool rim_glow = false;

// Tunable: the rim glow. Width in lens UV, where the lens radius is 0.5.
const float GLOW_WIDTH = 0.05;
const float GLOW_STRENGTH = 0.07;

void fragment()
{
	float rim = rim_glow ? smoothstep(0.5 - GLOW_WIDTH, 0.5, length(UV - vec2(0.5))) * (1.0 - opacity) : 0.0;

	ALBEDO = vec3(0.0);
	// Emission, so the rim reads the same in the dark, where lit albedo would fade with the scene.
	EMISSION = vec3(rim, 0.0, 0.0);
	ALPHA = rim * GLOW_STRENGTH;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
