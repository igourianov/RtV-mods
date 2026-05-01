shader_type spatial;
render_mode unshaded;

uniform sampler2D viewport : source_color, filter_linear;
uniform bool active = true;
uniform float blur_radius = 0.0;
const float brightness = 0.8;
const float contrast = 0.99;

void fragment() {
	vec3 color;
	if (blur_radius > 0.0) {
		vec2 texel = blur_radius / vec2(textureSize(viewport, 0));
		color = vec3(0.0);
		color += texture(viewport, UV + vec2(-texel.x, -texel.y)).rgb;
		color += texture(viewport, UV + vec2( 0.0,    -texel.y)).rgb;
		color += texture(viewport, UV + vec2( texel.x, -texel.y)).rgb;
		color += texture(viewport, UV + vec2(-texel.x,  0.0   )).rgb;
		color += texture(viewport, UV).rgb;
		color += texture(viewport, UV + vec2( texel.x,  0.0   )).rgb;
		color += texture(viewport, UV + vec2(-texel.x,  texel.y)).rgb;
		color += texture(viewport, UV + vec2( 0.0,     texel.y)).rgb;
		color += texture(viewport, UV + vec2( texel.x,  texel.y)).rgb;
		color /= 9.0;
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
