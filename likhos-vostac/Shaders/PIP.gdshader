shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport : source_color, filter_linear;
uniform bool active = true;
// World tonemap exposure, already applied in the PIP render and divided out so the main pass doesn't apply it twice.
uniform float exposure = 1.0;
const float brightness = 0.8;
const float contrast = 0.99;

void fragment() {
	vec3 color = texture(viewport, UV).rgb;

	color *= brightness / exposure;
	color = (color - 0.5) * contrast + 0.5;

	if (active) {
		ALBEDO = color;
	} else {
		ALBEDO = vec3(0.0);
	}
}
