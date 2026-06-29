shader_type canvas_item;
render_mode blend_add;

uniform float matrix_cell = 3.0;
uniform float matrix_dot : hint_range(0.0, 1.0) = 0.42;
uniform float matrix_soft = 0.12;
uniform float matrix_floor : hint_range(0.0, 1.0) = 0.22;


void fragment() {
	float a = texture(TEXTURE, UV).a;

	// pixel-locked grid -> discrete LED dots; the floor keeps lit areas (and the
	// outline halo) softly glowing instead of cutting to black between dots
	vec2 cell = fract(FRAGCOORD.xy / matrix_cell) - 0.5;
	float dotmask = 1.0 - smoothstep(matrix_dot, matrix_dot + matrix_soft, length(cell));
	float m = mix(matrix_floor, 1.0, dotmask);

	COLOR = vec4(COLOR.rgb, a * m * COLOR.a);
}
