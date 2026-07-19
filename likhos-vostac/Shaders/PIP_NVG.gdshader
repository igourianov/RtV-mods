shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport : source_color, filter_linear;
uniform bool active = true;
uniform float blur_radius = 0.0;
const float brightness = 0.8;
const float contrast = 0.99;

// Taps per axis from center. Kernel is (2*STEPS+1)^2 samples.
// Raise for a smoother blur at larger blur_radius (higher GPU cost).
const int STEPS = 5;

void fragment() {
	vec3 color;
	if (blur_radius > 0.0) {
		vec2 step_uv = (blur_radius / float(STEPS)) / vec2(textureSize(viewport, 0));
		float sigma = float(STEPS) * 0.5;
		float two_sigma_sq = 2.0 * sigma * sigma;
		color = vec3(0.0);
		float total = 0.0;
		for (int x = -STEPS; x <= STEPS; x++) {
			for (int y = -STEPS; y <= STEPS; y++) {
				float w = exp(-float(x * x + y * y) / two_sigma_sq);
				color += texture(viewport, UV + vec2(float(x), float(y)) * step_uv).rgb * w;
				total += w;
			}
		}
		color /= total;
	} else {
		color = texture(viewport, UV).rgb;
	}

	color *= brightness;
	color = (color - 0.5) * contrast + 0.5;

	if (active) {
		ALBEDO = color;
	} else {
		ALBEDO = vec3(0.0);
	}
}
