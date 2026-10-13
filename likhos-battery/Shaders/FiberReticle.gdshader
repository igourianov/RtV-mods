shader_type spatial;

// The reticle of a fiber optic lit sight as a pass of its own, drawn over the lens material that vanilla or VosTac owns.
// Shadow reception is a render mode, fixed per shader. Reticle.gdshader disables it, this pass needs the world's shade to reach the fiber.

uniform bool scope = false;
uniform sampler2D reticle : repeat_disable;
uniform float opacity : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float size : hint_range(0.0, 1.0, 0.01) = 0.1;
// VosTac's factor from `size` to lens UV, copied from a lens material VosTac places that way. At 0 the placement is vanilla's.
uniform float lens_uv_scale = 0.0;

// Tunable: glow per unit of light on the lens. Starts at the vanilla `intensity` of the ACOG lens material.
const float GAIN = 5.0;
// Tunable: the tritium glow, as a share of the glow under one unit of light.
const float TRITIUM = 0.05;

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
	// Placement, as in Reticle.gdshader ----------------------------------------

	vec2 reticleUV;
	float shadowMask = 0.0;
	if (lens_uv_scale > 0.0)
	{
		reticleUV = (UV - vec2(0.5)) / (size * lens_uv_scale);
	}
	else
	{
		vec3 shadowOffset = normalize(shadowPosition) + NORMAL;
		shadowMask = smoothstep(0.9, 1.0, length(shadowOffset.xy / (scope ? 0.02 : 1.0)));

		vec3 reticleOffset = normalize(reticlePosition) + NORMAL;
		reticleUV = (reticleOffset.xy / size) * vec2(1.0, -1.0);
	}
	vec4 reticleSample = texture(reticle, reticleUV + vec2(0.5));
	float reticleAlpha = reticleSample.a * (1.0 - shadowMask);

	// Output ----------------------------------------

	float glow = reticleSample.r * GAIN * reticleAlpha;

	ALBEDO = vec3(glow, 0.0, 0.0);
	// Emission, so the floor holds in the dark, where lit albedo fades with the scene.
	EMISSION = vec3(glow * TRITIUM, 0.0, 0.0);
	ALPHA = reticleAlpha * opacity;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light()
{
	// A fiber gathers light from every side, so the angle between the light and the lens does not count. Shadows arrive in ATTENUATION.
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR / PI;
}
