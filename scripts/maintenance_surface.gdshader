shader_type canvas_item;

// Preserve the measured silhouette, seams and lighting from the authored PNG.
// Use the painted floor reference for surface variation instead of flat gray.
uniform sampler2D painted_reference : source_color, filter_linear;
uniform vec2 canvas_size = vec2(1280.0, 720.0);

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float high = max(original.r, max(original.g, original.b));
	float low = min(original.r, min(original.g, original.b));
	float surface = (1.0 - smoothstep(0.035, 0.12, high-low)) * smoothstep(0.15, 0.28, high);
	vec2 tile = fract(UV * canvas_size / vec2(96.0, 64.0));
	// Sample only bare floor, never the reference sheet's miniature props.
	vec3 painted = texture(painted_reference, (vec2(897.0,688.0) + tile * vec2(24.0,12.0)) / vec2(1536.0,1024.0)).rgb;
	vec3 steel = mix(vec3(0.42,0.44,0.44), painted, 0.12);
	vec3 shaded = steel * (0.45 + high);
	COLOR = vec4(mix(original.rgb,shaded,surface*0.8),original.a);
}
