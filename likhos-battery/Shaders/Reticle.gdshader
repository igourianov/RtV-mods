shader_type spatial;
render_mode shadows_disabled;

// The reticle of a sight as a pass of its own, drawn with the lens material that vanilla or VosTac owns.

uniform bool scope = false;
uniform sampler2D reticle : repeat_disable;
uniform float opacity : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float size : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float intensity : hint_range(0.0, 10.0, 1.0) = 5.0;
// VosTac's factor from `size` to lens UV, copied from a lens material VosTac places that way. At 0 the placement is vanilla's.
uniform float lens_uv_scale = 0.0;
// OpticPower.Reticle: 0 nothing, 1 unlit, 2 lit as authored, 3 lit whole.
uniform int state = 2;

varying vec3 reticlePosition;

void vertex()
{
	reticlePosition = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment()
{
	// Placement ----------------------------------------

	// No eye relief mask. OpticPower orders this pass so the lens shadow hides it.
	vec2 reticleUV;
	if (lens_uv_scale > 0.0)
	{
		reticleUV = (UV - vec2(0.5)) / (size * lens_uv_scale);
	}
	else
	{
		vec3 reticleOffset = normalize(reticlePosition) + NORMAL;
		reticleUV = (reticleOffset.xy / size) * vec2(1.0, -1.0);
	}
	vec4 reticleSample = texture(reticle, reticleUV + vec2(0.5));
	float reticleAlpha = reticleSample.a;

	// Spherical lens ----------------------------------------

	// The lens shaders' normal. The glow is lit albedo, so it needs the same normal to match vanilla's strength.
	vec2 uv_center = (UV - vec2(0.5)) * (scope ? mix(1.0, 2.0, opacity) : 0.0);
	uv_center.y = -uv_center.y;
	float z = sqrt(max(1.0 - dot(uv_center, uv_center), 0.0));
	NORMAL_MAP = normalize(vec3(uv_center.x, uv_center.y, z)) * 0.5 + 0.5;

	// Output ----------------------------------------

	float glow = state == 3 ? 1.0 : (state == 2 ? reticleSample.r : 0.0);

	ALBEDO = vec3(glow * intensity, 0.0, 0.0) * reticleAlpha;
	// Both lens shaders fade the reticle with the aim.
	ALPHA = state == 0 ? 0.0 : reticleAlpha * opacity;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	BACKLIGHT = vec3(1.0);
}
