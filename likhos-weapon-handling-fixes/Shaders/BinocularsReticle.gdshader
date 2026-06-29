shader_type canvas_item;
render_mode blend_add;

// illuminated, procedurally generated rangefinder reticle drawn over the optical lens pass
uniform vec4 aim_dot_color : source_color = vec4(1.0, 0.5, 0.05, 1.0);
uniform float aim_dot_radius = 0.0005;
uniform float aim_dot_softness = 0.003;
uniform float aim_glow_scale = 3.0;
uniform float aim_glow_strength : hint_range(0.0, 1.0) = 0.15;
uniform float center_y = 0.5;


void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 d = UV - vec2(0.5, center_y);
	d.x *= aspect;
	float r = length(d);

	// bright core marks the exact sample point; soft bloom sells the emissive LED
	float core = 1.0 - smoothstep(aim_dot_radius, aim_dot_radius + aim_dot_softness, r);
	float glow = 1.0 - smoothstep(aim_dot_radius, aim_dot_radius + aim_dot_softness * aim_glow_scale, r);
	float mark = max(core, glow * aim_glow_strength);

	COLOR = vec4(aim_dot_color.rgb, mark * aim_dot_color.a);
}
