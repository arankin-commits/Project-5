shader_type canvas_item;

// Reconstruct enlarged painted textures without the softness of bilinear
// filtering. Clamp to nearby colors to avoid bright sharpening halos.
uniform float detail_strength : hint_range(0.0, 0.3) = 0.15;
varying vec4 map_tint;

void vertex() {
	map_tint = COLOR;
}

vec4 cubic_weights(float t) {
	float t2 = t*t;
	float t3 = t2*t;
	return vec4(-0.5*t+t2-0.5*t3,
		1.0-2.5*t2+1.5*t3,
		0.5*t+2.0*t2-1.5*t3,
		-0.5*t2+0.5*t3);
}

void fragment() {
	vec2 source_pixel = UV / TEXTURE_PIXEL_SIZE;
	float footprint = max(length(dFdx(source_pixel)),length(dFdy(source_pixel)));
	float enlargement = 1.0-smoothstep(0.7,1.0,footprint);
	vec4 normal = texture(TEXTURE,UV);
	if (enlargement > 0.0) {
		vec2 base = floor(source_pixel-0.5);
		vec2 fraction = fract(source_pixel-0.5);
		vec4 wx = cubic_weights(fraction.x);
		vec4 wy = cubic_weights(fraction.y);
		vec4 reconstructed = vec4(0.0);
		vec3 neighborhood = vec3(0.0);
		vec3 low = vec3(1.0);
		vec3 high = vec3(0.0);
		for (int y=0; y<4; y++) {
			for (int x=0; x<4; x++) {
				vec2 sample_uv = (base+vec2(float(x)-0.5,float(y)-0.5))*TEXTURE_PIXEL_SIZE;
				vec4 sample_color = texture(TEXTURE,clamp(sample_uv,TEXTURE_PIXEL_SIZE*0.5,vec2(1.0)-TEXTURE_PIXEL_SIZE*0.5));
				reconstructed += sample_color*wx[x]*wy[y];
				neighborhood += sample_color.rgb/16.0;
				if (x>=1 && x<=2 && y>=1 && y<=2) {
					low = min(low,sample_color.rgb);
					high = max(high,sample_color.rgb);
				}
			}
		}
		reconstructed.rgb = clamp(reconstructed.rgb+detail_strength*(reconstructed.rgb-neighborhood),low,high);
		reconstructed.a = clamp(reconstructed.a,0.0,1.0);
		COLOR = mix(normal,reconstructed,enlargement)*map_tint;
	} else {
		COLOR = normal*map_tint;
	}
}
