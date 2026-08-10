shader_type spatial;
render_mode shadows_disabled;

uniform bool scope = false;
uniform sampler2D reticle : repeat_disable;
uniform float opacity : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float size : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float intensity : hint_range(0.0, 10.0, 1.0) = 5.0;
uniform float shadow : hint_range(0.0, 1.0, 0.001) = 0.0;

// Per-optic `size` values are authored against vanilla's view-direction UV; this rescales them onto lens UV.
const float RETICLE_SCALE = 3.0;

varying float occlusion;
varying float spherical;
global uniform sampler2D Specular : filter_linear_mipmap;

void fragment()
{
	// Reticle type ----------------------------------------

	if (scope)
	{
		occlusion = 0.5;
		spherical = mix(1.0, 2.0, opacity);
	}
	else
	{
		occlusion = 1.0;
		spherical = 0.0;
	}

	// Spherical lens ----------------------------------------

	vec2 uv_center = UV - vec2(0.5);
	uv_center *= spherical;
	uv_center.y = -uv_center.y;
	float r2 = dot(uv_center, uv_center);
	float z = sqrt(1.0 - r2);
	vec3 normal = normalize(vec3(uv_center.x, uv_center.y, z));
	NORMAL_MAP = normal * 0.5 + 0.5;

	// Occlusion ----------------------------------------

	float edge = smoothstep(occlusion - 0.15, occlusion, length(UV - 0.5));
	edge = 1.0 - edge;

	// Shadow ----------------------------------------

	float r = length(UV - 0.5);
	float aperture_outer = mix(0.58, 0.0, shadow);
	float aperture_inner = aperture_outer - 0.08;
	float shadowMask = scope ? smoothstep(aperture_inner, aperture_outer, r) : 0.0;

	// Reticle ----------------------------------------

	// Deliberately lens UV, not view space. Vanilla's view-space derivation made the sight
	// parallax-free, which held the point of aim still while the uncompensated laser dot moved.
	vec2 reticleUV = (UV - vec2(0.5)) / (size * RETICLE_SCALE);
	vec4 reticleSample = texture(reticle, reticleUV + vec2(0.5, 0.5));
	float reticleAlpha = reticleSample.a;
	vec3 reticleColor = reticleSample.rgb * vec3(intensity, 0.0, 0.0) * reticleAlpha;

	// Reflection ----------------------------------------

	float specular = texture(Specular, UV).r;
	float reflection = mix(0.5 * edge, specular * (1.0 - edge), opacity);

	// Output ----------------------------------------

	vec3 color = mix(vec3(0.0), reticleColor, opacity);
	float alpha = mix(1.0, max(shadowMask, reticleAlpha), opacity * edge);

	ALBEDO = color;
	ALPHA = alpha;
	ROUGHNESS = 0.1 + specular;
	SPECULAR = reflection;
	BACKLIGHT = vec3(1.0);
}
