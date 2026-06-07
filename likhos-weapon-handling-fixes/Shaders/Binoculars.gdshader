shader_type canvas_item;
render_mode blend_mix;

uniform float radius = 0.6;
uniform float separation = 0.55;
uniform float center_y = 0.5;
uniform float feather = 0.006;
uniform float vignette : hint_range(0.0, 1.0) = 0.45;
uniform float grime_opacity : hint_range(0.0, 1.0) = 0.2;
uniform vec4 grime_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 reticle_color : source_color = vec4(0.0, 0.0, 0.0, 0.9);
uniform sampler2D grime_tex : source_color, filter_linear, hint_default_white;
uniform sampler2D reticle_tex : source_color, filter_linear, hint_default_transparent;


void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 d = UV - vec2(0.5, center_y);
	d.x *= aspect;

	float off = separation * radius;
	float dl = length(vec2(d.x + off, d.y));
	float dr = length(vec2(d.x - off, d.y));
	float dist = min(dl, dr);

	float inside = 1.0 - smoothstep(radius - feather, radius, dist);
	float exterior = 1.0 - inside;

	vec2 luv = d / (radius * 2.0) + vec2(0.5);

	float vig = smoothstep(radius * (1.0 - vignette), radius, dist);

	float grime_mask = 1.0 - dot(texture(grime_tex, luv).rgb, vec3(0.3333));
	vec4 ret = texture(reticle_tex, luv);

	vec3 col = vec3(0.0);
	float a = 0.0;

	col = mix(col, grime_color.rgb, grime_mask);
	a = max(a, grime_mask * grime_opacity * grime_color.a);

	col = mix(col, reticle_color.rgb, ret.a);
	a = max(a, ret.a * reticle_color.a);

	a *= inside;

	a = max(a, max(vig * 0.85, exterior));
	col = mix(col, vec3(0.0), exterior);

	COLOR = vec4(col, a);
}
