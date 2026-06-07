shader_type canvas_item;
render_mode blend_mix;

uniform float radius = 0.6;
uniform float separation = 0.55;
uniform float center_y = 0.5;
uniform float feather = 0.006;
uniform float vignette : hint_range(0.0, 1.0) = 0.45;
uniform float grime_opacity : hint_range(0.0, 1.0) = 0.2;
uniform float ca_strength = 0.004;
uniform float blur_px = 5.0;
uniform vec4 grime_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 reticle_color : source_color = vec4(0.0, 0.0, 0.0, 0.9);
uniform sampler2D grime_tex : source_color, filter_linear, hint_default_white;
uniform sampler2D reticle_tex : source_color, filter_linear, hint_default_transparent;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

const vec2 KERNEL[5] = {
	vec2(0.0, 0.0),
	vec2(1.0, 1.0),
	vec2(-1.0, 1.0),
	vec2(1.0, -1.0),
	vec2(-1.0, -1.0)
};


void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 d = UV - vec2(0.5, center_y);
	d.x *= aspect;

	float off = separation * radius;
	vec2 cl = vec2(-off, 0.0);
	vec2 cr = vec2(off, 0.0);
	float dl = length(d - cl);
	float dr = length(d - cr);
	float dist = min(dl, dr);
	vec2 nc = dl < dr ? cl : cr;

	float inside = 1.0 - smoothstep(radius - feather, radius, dist);
	float exterior = 1.0 - inside;

	vec2 luv = d / (radius * 2.0) + vec2(0.5);
	float vig = smoothstep(radius * (1.0 - vignette), radius, dist);

	float r_norm = clamp(dist / radius, 0.0, 1.0);
	float edge = r_norm * r_norm;

	vec3 world = vec3(0.0);
	if (inside > 0.0) {
		vec2 ca_dir = normalize(vec2(d.x / aspect, d.y) + vec2(1e-5));
		float ca_norm = clamp(length(d) / (off + radius), 0.0, 1.0);
		vec2 ca = ca_dir * ca_strength * ca_norm * ca_norm;
		vec2 blur = SCREEN_PIXEL_SIZE * blur_px * edge;

		for (int i = 0; i < 5; i++) {
			vec2 o = KERNEL[i] * blur;
			world.r += texture(screen_tex, SCREEN_UV + o + ca).r;
			world.g += texture(screen_tex, SCREEN_UV + o).g;
			world.b += texture(screen_tex, SCREEN_UV + o - ca).b;
		}
		world /= 5.0;
	}

	float grime_mask = 1.0 - dot(texture(grime_tex, luv).rgb, vec3(0.3333));
	vec4 ret = texture(reticle_tex, luv);

	vec3 col = world;
	col = mix(col, grime_color.rgb, grime_mask * grime_opacity * grime_color.a);
	col = mix(col, reticle_color.rgb, ret.a * reticle_color.a);
	col = mix(col, vec3(0.0), vig * 0.85);
	col = mix(col, vec3(0.0), exterior);

	COLOR = vec4(col, 1.0);
}
