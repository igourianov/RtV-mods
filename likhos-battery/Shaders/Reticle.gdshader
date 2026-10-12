shader_type spatial;
render_mode shadows_disabled;

// The reticle of a sight as a pass of its own, drawn over the lens material that vanilla or VosTac owns.

uniform bool scope = false;
uniform sampler2D reticle : repeat_disable;
uniform float opacity : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float size : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float intensity : hint_range(0.0, 10.0, 1.0) = 5.0;
// VosTac's factor from `size` to lens UV, copied from a lens material VosTac places that way. At 0 the placement is vanilla's.
uniform float lens_uv_scale = 0.0;
// OpticPower.Reticle: 0 nothing, 1 unlit, 2 lit as authored, 3 lit whole.
uniform int state = 2;
// A scope with its illumination running shows it on the rim of its lens while the reticle is faded out of view.
uniform bool rim_glow = false;

// Tunable: the rim glow. Width in lens UV, where the lens radius is 0.5.
const float GLOW_WIDTH = 0.05;
const float GLOW_STRENGTH = 0.05;

varying vec3 shadowVertex;
varying vec3 shadowPosition;
varying vec3 reticlePosition;

void vertex()
{
	shadowVertex = ((PROJECTION_MATRIX * MODELVIEW_MATRIX) * vec4(VERTEX, 1.0)).xyz;
	shadowPosition = (INV_PROJECTION_MATRIX * vec4(shadowVertex, 1.0)).xyz;
	reticlePosition = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment()
{
	// Placement ----------------------------------------

	vec2 reticleUV;
	float shadowMask = 0.0;
	if (lens_uv_scale > 0.0)
	{
		// VosTac draws the reticle in front of its eye shadow, so nothing masks it here.
		reticleUV = (UV - vec2(0.5)) / (size * lens_uv_scale);
	}
	else
	{
		// The vanilla lens shader hides the reticle under its own shadow. Same math, so the two shadows line up.
		vec3 shadowOffset = normalize(shadowPosition) + NORMAL;
		shadowMask = smoothstep(0.9, 1.0, length(shadowOffset.xy / (scope ? 0.02 : 1.0)));

		vec3 reticleOffset = normalize(reticlePosition) + NORMAL;
		reticleUV = (reticleOffset.xy / size) * vec2(1.0, -1.0);
	}
	vec4 reticleSample = texture(reticle, reticleUV + vec2(0.5));
	float reticleAlpha = reticleSample.a * (1.0 - shadowMask);

	// Spherical lens ----------------------------------------

	// The lens shaders' normal. The glow is lit albedo, so it needs the same normal to match vanilla's strength.
	vec2 uv_center = (UV - vec2(0.5)) * (scope ? mix(1.0, 2.0, opacity) : 0.0);
	uv_center.y = -uv_center.y;
	float z = sqrt(max(1.0 - dot(uv_center, uv_center), 0.0));
	NORMAL_MAP = normalize(vec3(uv_center.x, uv_center.y, z)) * 0.5 + 0.5;

	// Output ----------------------------------------

	float glow = state == 3 ? 1.0 : (state == 2 ? reticleSample.r : 0.0);
	float rim = rim_glow ? smoothstep(0.5 - GLOW_WIDTH, 0.5, length(UV - vec2(0.5))) * (1.0 - opacity) : 0.0;

	ALBEDO = vec3(glow * intensity, 0.0, 0.0) * reticleAlpha;
	// Emission, so the rim reads the same in the dark, where lit albedo would fade with the scene.
	EMISSION = vec3(rim, 0.0, 0.0);
	// Both lens shaders fade the reticle with the aim and leave it unmasked on the rim.
	ALPHA = state == 0 ? 0.0 : max(reticleAlpha * opacity, rim * GLOW_STRENGTH);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = vec3(1.0);
}
