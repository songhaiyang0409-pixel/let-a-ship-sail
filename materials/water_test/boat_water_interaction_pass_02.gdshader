shader_type spatial;

// BOAT WATER VISUAL INTEGRATION PASS 02
// The geometry remains a bounded world-space history. This material hides the
// implementation quads with low-cost, seeded breakup so disturbed water is
// visible through the effect.

render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

void fragment() {
	vec2 uv = UV;
	float seed = UV2.x;
	float age = clamp(UV2.y, 0.0, 1.0);
	vec2 centered = uv * 2.0 - 1.0;
	vec2 elongated = vec2(centered.x * 1.38, centered.y * 0.72);
	float radial_edge = 1.0 - smoothstep(0.52, 1.08, length(elongated));

	// Two broad, seeded fields create holes and eroded edges. The first field
	// breaks the silhouette; the second prevents identical internal coverage.
	float broad_breakup = value_noise(uv * 3.4 + vec2(seed * 7.1 + TIME * 0.08, seed * 11.3 - TIME * 0.05));
	float fine_breakup = value_noise(uv * 7.0 + vec2(seed * 19.7 - TIME * 0.14, seed * 5.3 + TIME * 0.10));
	float edge_mask = smoothstep(0.24, 0.62, broad_breakup);
	float hole_mask = smoothstep(0.20, 0.54, fine_breakup);
	float mask = radial_edge * edge_mask * mix(0.16, 1.0, hole_mask);

	// Farther historical samples are intentionally more fragmented and
	// transparent. The alpha value still comes from the distance/lifetime
	// logic in GDScript, while this layer adds additional visual gaps.
	float far_fragment = smoothstep(0.50, 0.86, age);
	mask *= mix(1.0, smoothstep(0.30, 0.70, fine_breakup), far_fragment * 0.65);

	float alpha = COLOR.a * mask;
	if (alpha < 0.012) {
		discard;
	}
	ALBEDO = COLOR.rgb;
	ALPHA = alpha;
	ROUGHNESS = 0.98;
	SPECULAR = 0.035;
}
