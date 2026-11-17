shader_type canvas_item;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.a *= smoothstep(0.005, 0.035, max(c.r, max(c.g, c.b)));
	COLOR = c;
}
