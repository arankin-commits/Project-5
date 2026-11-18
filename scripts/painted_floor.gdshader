shader_type canvas_item;

uniform vec4 tile_region = vec4(53.0, 46.0, 423.0, 425.0);
uniform float tile_span = 448.0;
uniform vec4 surface_tint : source_color = vec4(1.0);
uniform bool liquid = false;

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 tile_uv = fract(UV * size / tile_span);
	if (liquid) {
		vec2 flow = UV * size / tile_span + vec2(TIME * 0.012, TIME * 0.008);
		flow += vec2(sin(flow.y * 8.0 + TIME * 0.3), cos(flow.x * 7.0 + TIME * 0.25)) * 0.015;
		tile_uv = abs(fract(flow * 0.5) * 2.0 - 1.0);
	}
	vec2 sample_uv = (tile_region.xy + vec2(1.0) + tile_uv * (tile_region.zw - vec2(2.0))) / size;
	vec4 painted = texture(TEXTURE, sample_uv);
	COLOR = vec4(painted.rgb * surface_tint.rgb, 1.0);
}
