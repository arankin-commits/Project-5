shader_type canvas_item;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float alpha = 1.0;
	if (UV.y < 0.236) {
		float du = (UV.x - 0.50) / 0.408;
		float dv = (UV.y - 0.236) / 0.224;
		float dist = sqrt(du * du + dv * dv);
		if (dist > 1.0) {
			alpha = clamp(1.0 - (dist - 1.0) / 0.03, 0.0, 1.0);
		}
	}
	if (UV.x < 0.108) {
		alpha = min(alpha, clamp((UV.x - 0.095) / 0.013, 0.0, 1.0));
	}
	if (UV.x > 0.931) {
		alpha = min(alpha, clamp((0.944 - UV.x) / 0.013, 0.0, 1.0));
	}
	if (UV.y > 0.965) {
		alpha = min(alpha, clamp((0.985 - UV.y) / 0.020, 0.0, 1.0));
	}
	c.a *= alpha;
	COLOR = c;
}
