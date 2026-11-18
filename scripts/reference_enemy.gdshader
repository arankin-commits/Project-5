shader_type canvas_item;
render_mode unshaded;

uniform vec4 frame_uv = vec4(0.0, 0.0, 0.125, 0.125);
uniform float foot_line = 0.88;
uniform float pose_time = 0.0;
uniform float pose = 0.0; // idle, locomotion, windup, strike, recovery, death
uniform float progress = 0.0;
uniform float gait = 0.0; // 0 legs, 1 floating, 2 wheels/segments, 3 swarm
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 p = (UV - frame_uv.xy) / frame_uv.zw;
	vec2 sample_point = p;
	float cycle = sin(pose_time * 12.0);
	if (pose > 0.5 && pose < 1.5) {
		float lower = smoothstep(0.48, 0.90, p.y);
		if (gait < 0.5) {
			// Alternate the lower left/right limb motion while the torso stays stable.
			float side = smoothstep(0.44, 0.56, p.x) * 2.0 - 1.0;
			sample_point.y += cycle * side * lower * 0.026;
			sample_point.x += cos(pose_time * 12.0) * side * lower * 0.010;
		} else if (gait > 1.5) {
			sample_point.x += sin(pose_time * 12.0 + p.y * 15.0) * lower * 0.012;
		}
	} else if (pose > 1.5 && pose < 2.5) {
		sample_point.y = foot_line + (p.y - foot_line) / (1.0 - progress * 0.055);
	} else if (pose > 2.5 && pose < 3.5) {
		float limbs = smoothstep(0.12, 0.40, abs(p.x - 0.5));
		sample_point.x = 0.5 + (p.x - 0.5) / (1.0 + sin(progress * 3.14159) * limbs * 0.10);
	} else if (pose > 3.5 && pose < 4.5) {
		sample_point.x += sin(pose_time * 18.0) * (1.0 - progress) * 0.008;
	} else if (pose > 4.5) {
		sample_point.y = foot_line + (p.y - foot_line) / max(0.12, 1.0 - progress * 0.80);
		sample_point.x += (p.y - foot_line) * progress * 0.16;
	}
	vec2 sample_uv = clamp(sample_point, vec2(0.002), vec2(0.998)) * frame_uv.zw + frame_uv.xy;
	vec4 pixel = texture(TEXTURE, sample_uv);
	// Generated alpha includes a faint matte; reject that fringe in the renderer.
	pixel.a = smoothstep(0.18, 0.92, pixel.a);
	if (sample_point.x < 0.0 || sample_point.x > 1.0 || sample_point.y < 0.0 || sample_point.y > 1.0) {
		pixel.a = 0.0;
	}
	COLOR = pixel * tint;
}
