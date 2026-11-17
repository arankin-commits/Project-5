shader_type canvas_item;

uniform bool clean_walk = false;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (clean_walk) {
		c.a = smoothstep(0.80, 0.96, c.a);
	}
	COLOR = c * tint;
}
