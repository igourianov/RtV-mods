shader_type spatial;
render_mode shadows_disabled;

uniform bool scope = false;
uniform sampler2D reticle : repeat_disable;
uniform float opacity : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float size : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float intensity : hint_range(0.0, 10.0, 1.0) = 5.0;
// Rescales `size` onto lens UV. Set per material, where Likho's Battery Powered reads it to place its own reticle pass the same way.
uniform float lens_uv_scale = 1.0;

// Width of the lens rim that fades the image out, in lens UV. The lens radius is 0.5.
const float RIM_WIDTH = 0.05;

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

	float r = length(UV - 0.5);
	float edge = smoothstep(occlusion - 0.15, occlusion, r);
	edge = 1.0 - edge;
	// This surface is lit black, so whatever it covers turns pure black once no skylight reflects off it.
	// Vanilla covers the image with the full edge ring, which at night blacks out the outer 30% of the lens radius.
	float rim = 1.0 - smoothstep(occlusion - RIM_WIDTH, occlusion, r);

	// Reticle ----------------------------------------

	// Deliberately lens UV, not view space. Vanilla's view-space derivation made the sight
	// parallax-free, which held the point of aim still while the uncompensated laser dot moved.
	vec2 reticleUV = (UV - vec2(0.5)) / (size * lens_uv_scale);
	vec4 reticleSample = texture(reticle, reticleUV + vec2(0.5, 0.5));
	float reticleAlpha = reticleSample.a;
	vec3 reticleColor = vec3(reticleSample.r * intensity, 0.0, 0.0) * reticleAlpha;

	// Reflection ----------------------------------------

	float specular = texture(Specular, UV).r;
	float reflection = mix(0.5 * edge, specular * (1.0 - edge), opacity);

	// Output ----------------------------------------

	vec3 color = mix(vec3(0.0), reticleColor, opacity);
	float alpha = mix(1.0, reticleAlpha, opacity * rim);

	ALBEDO = color;
	ALPHA = alpha;
	ROUGHNESS = 0.1 + specular;
	SPECULAR = reflection;
	BACKLIGHT = vec3(1.0);
}
