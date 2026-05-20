shader_type spatial;
render_mode shadows_disabled;

uniform bool scope = false;
uniform sampler2D reticle : repeat_disable;
uniform float opacity : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float size : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float intensity : hint_range(0.0, 10.0, 1.0) = 5.0;
uniform float shadow_tightness : hint_range(0.0, 1.0, 0.001) = 0.025;

varying float occlusion;
varying float spherical;
varying float shadow;
varying vec3 shadowVertex;
varying vec3 shadowPosition;
varying vec3 reticlePosition;
global uniform sampler2D Specular : filter_linear_mipmap;

void vertex()
{
	shadowVertex = ((PROJECTION_MATRIX * MODELVIEW_MATRIX) * vec4(VERTEX, 1.0)).xyz;
	shadowPosition = (INV_PROJECTION_MATRIX * vec4(shadowVertex, 1.0)).xyz;
	reticlePosition = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment()
{
	// Reticle type ----------------------------------------

	if (scope)
	{
		occlusion = 0.5;
		shadow = shadow_tightness;
		spherical = mix(1.0, 2.0, opacity);
	}
	else
	{
		occlusion = 1.0;
		shadow = 1.0;
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

	vec3 shadowOffset = normalize(shadowPosition) + NORMAL;
	float shadowUV = length(shadowOffset.xy / shadow);
	float shadowMask = smoothstep(0.9, 1.0, shadowUV);

	// Reticle ----------------------------------------

	vec3 reticleOffset = normalize(reticlePosition) + NORMAL;
	vec2 reticleUV = (reticleOffset.xy / size) * vec2(1.0, -1.0);
	vec4 reticleSample = texture(reticle, reticleUV + vec2(0.5, 0.5));
	float reticleAlpha = reticleSample.a * (1.0 - shadowMask);
	vec3 reticleColor = reticleSample.rgb * vec3(intensity, 0.0, 0.0) * reticleAlpha;

	// Reflection ----------------------------------------

	float specular = texture(Specular, UV).r;
	float reflection = mix(0.5 * edge, specular * (1.0 - edge), opacity);

	// Output ----------------------------------------

	vec3 color = mix(vec3(0.0), reticleColor, opacity);
	float alpha = mix(1.0, shadowMask + reticleAlpha, opacity * edge);

	ALBEDO = color;
	ALPHA = alpha;
	ROUGHNESS = 0.1 + specular;
	SPECULAR = reflection;
	BACKLIGHT = vec3(1.0);
}
