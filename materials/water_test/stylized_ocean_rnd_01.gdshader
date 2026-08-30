shader_type spatial;

// STYLIZED OCEAN RND 01
//
// Isolated R&D shader. The base Gerstner surface is shared with the visual
// blockout, while variant_mode selects deliberately different visual paths:
// 1=A layered directional bands, 2=B faceted geometric read, 3=C restrained
// directional ribbons, and 11/12/13=Hybrid V1/V2/V3.
// No textures, refraction, caustics, foam system, or screen-space effects.

render_mode unshaded, cull_disabled, depth_draw_opaque;

group_uniforms Waves;
uniform vec4 wave_1 = vec4(0.34, 3.60, 0.18, 0.86);
uniform vec4 wave_5 = vec4(1.42, 0.28, 0.12, 2.18);
uniform vec4 wave_7 = vec4(-1.05, 2.90, 0.08, 1.30);
uniform vec4 wave_8 = vec4(-0.58, -1.22, 0.10, 1.82);
uniform float wave_time = 0.0;
uniform float time_factor = 2.7;
uniform float wave_amplitude_scale = 0.70;
uniform float wave_length_scale = 3.8;

group_uniforms Color;
uniform vec3 trough_color : source_color = vec3(0.018, 0.105, 0.19);
uniform vec3 water_color : source_color = vec3(0.045, 0.235, 0.34);
uniform vec3 crest_color : source_color = vec3(0.16, 0.38, 0.43);
uniform vec3 atmospheric_color : source_color = vec3(0.20, 0.32, 0.38);
uniform vec3 sky_tint : source_color = vec3(0.48, 0.64, 0.69);
uniform vec3 camera_position_world = vec3(0.0);
uniform vec3 directional_light_direction_world = vec3(0.35, 0.82, 0.22);
uniform float variant_mode = 0.0;

varying float wave_height;
varying vec3 wave_normal;
varying vec3 surface_world_position;

struct WaveResult {
	vec3 displacement;
	vec3 tangent;
	vec3 binormal;
	vec3 normal;
};

float dynamic_amplitude(vec2 pos, float time) {
	return 1.0 + 0.5 * sin(time + length(pos) * 0.1);
}

WaveResult gerstner_wave(vec4 params, vec2 pos, float time) {
	float steepness = params.z * dynamic_amplitude(pos, time) * wave_amplitude_scale;
	float wavelength = params.w * wave_length_scale;
	float k = 2.0 * PI / wavelength;
	float speed = sqrt(9.81 / k);
	vec2 direction = normalize(params.xy);
	float phase = k * (dot(direction, pos) - speed * time);
	float amplitude = steepness / k;
	vec3 displacement = vec3(
		direction.x * amplitude * cos(phase),
		amplitude * sin(phase),
		direction.y * amplitude * cos(phase)
	);
	vec3 tangent = vec3(
		1.0 - direction.x * direction.x * steepness * sin(phase),
		steepness * cos(phase),
		-direction.x * direction.y * steepness * sin(phase)
	);
	vec3 binormal = vec3(
		-direction.x * direction.y * steepness * sin(phase),
		steepness * cos(phase),
		1.0 - direction.y * direction.y * steepness * sin(phase)
	);
	return WaveResult(displacement, tangent, binormal, normalize(cross(binormal, tangent)));
}

WaveResult base_wave(vec2 pos, float time) {
	WaveResult result;
	result.displacement = vec3(0.0);
	result.tangent = vec3(1.0, 0.0, 0.0);
	result.binormal = vec3(0.0, 0.0, 1.0);
	result.normal = vec3(0.0, 1.0, 0.0);
	WaveResult current;
	current = gerstner_wave(wave_1, pos, time);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_5, pos, time);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_7, pos, time);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_8, pos, time);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	result.normal = normalize(result.normal);
	return result;
}

float triangle_wave(float value) {
	return abs(fract(value) * 2.0 - 1.0);
}

float directional_band(vec2 pos, vec2 direction, float scale, float speed, float phase) {
	vec2 dir = normalize(direction);
	float along = dot(pos, dir) * scale - wave_time * speed + phase;
	float cross_flow = dot(pos, vec2(-dir.y, dir.x)) * 0.015;
	return sin(along + sin(cross_flow + phase) * 0.45);
}

float broad_swell_band(vec2 pos, float scale, float speed, float phase) {
	float a = directional_band(pos, vec2(0.96, 0.28), scale, speed, phase);
	float b = directional_band(pos, vec2(0.62, -0.78), scale * 0.63, speed * 0.71, phase + 1.7);
	return a * 0.68 + b * 0.32;
}

void vertex() {
	vec2 pos = VERTEX.xz;
	WaveResult base = base_wave(pos, wave_time / time_factor);
	vec3 displacement = base.displacement;
	float mode = variant_mode;

	// B and Hybrid add only a small broad triangular displacement. This is an
	// intentional geometric read experiment, not a second physics/wave system.
	if (mode == 2.0 || mode >= 11.0) {
		float facet_a = triangle_wave(dot(pos, normalize(vec2(0.92, 0.38))) * 0.105 - wave_time * 0.055);
		float facet_b = triangle_wave(dot(pos, normalize(vec2(-0.28, 0.96))) * 0.072 + wave_time * 0.035 + 0.7);
		float facet_shape = (facet_a * 0.62 + facet_b * 0.38) - 0.50;
		float facet_strength = mode == 2.0 ? 0.12 : (mode == 11.0 ? 0.065 : 0.085);
		displacement.y += facet_shape * facet_strength;
	}
	if (mode == 13.0) {
		// V3 adds a very broad cross-current shift so the surface does not read
		// as a set of perfectly camera-aligned strips.
		float current = sin(dot(pos, normalize(vec2(0.76, -0.65))) * 0.09 + wave_time * 0.045);
		displacement.xz += normalize(vec2(0.76, -0.65)) * current * 0.035;
	}

	VERTEX += displacement;
	wave_height = displacement.y;
	wave_normal = base.normal;
	surface_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float mode = variant_mode;
	float crest_mix = smoothstep(0.10, 0.34, wave_height) * 0.22;
	float water_mix = smoothstep(-0.34, 0.06, wave_height);
	vec3 color = mix(trough_color, water_color, water_mix);
	color = mix(color, crest_color, crest_mix);

	float distance_to_camera = distance(camera_position_world, surface_world_position);
	float far_mix = smoothstep(28.0, 92.0, distance_to_camera);
	color = mix(color, atmospheric_color, far_mix * 0.20);
	vec3 light_dir = normalize(directional_light_direction_world);
	float ndotl = clamp(dot(normalize(wave_normal), light_dir), 0.0, 1.0);
	color *= 0.94 + ndotl * 0.12;

	float band_a = 0.0;
	float band_b = 0.0;
	float band_strength = 0.0;
	if (mode == 1.0) {
		// Variant A: deliberately visible, layered repeated bands at two scales.
		band_a = directional_band(surface_world_position.xz, vec2(0.98, 0.20), 0.19, 0.20, 0.0);
		band_b = directional_band(surface_world_position.xz, vec2(0.66, -0.75), 0.095, 0.12, 2.3);
		band_strength = 0.28 * (1.0 - far_mix * 0.55);
		color = mix(color * 0.94, color * 1.10, smoothstep(0.18, 0.82, band_a * 0.5 + 0.5) * 0.65);
	} else if (mode == 2.0) {
		// Variant B: faceted, broad value regions; little surface striping.
		float facet = triangle_wave(dot(surface_world_position.xz, vec2(0.92, 0.38)) * 0.105 - wave_time * 0.055);
		float facet2 = triangle_wave(dot(surface_world_position.xz, vec2(-0.28, 0.96)) * 0.072 + wave_time * 0.035);
		float region = smoothstep(0.22, 0.80, facet * 0.68 + facet2 * 0.32);
		color = mix(color * 0.84, color * 1.14, region * 0.84);
		band_strength = 0.015;
	} else if (mode == 3.0) {
		// Variant C: quiet directional ribbons with a large phase offset.
		band_a = broad_swell_band(surface_world_position.xz, 0.115, 0.16, 1.2);
		band_b = directional_band(surface_world_position.xz, vec2(0.36, -0.93), 0.055, 0.085, 3.1);
		band_strength = 0.18 * (1.0 - far_mix * 0.78);
		color = mix(color * 0.97, color * 1.08, smoothstep(0.12, 0.88, band_a * 0.5 + 0.5) * 0.52);
	} else if (mode >= 11.0) {
		// Hybrid passes are intentionally different structural treatments.
		float pass_id = mode - 10.0;
		if (pass_id == 1.0) {
			// V1 starts with the readable A bands and a restrained B facet.
			band_a = broad_swell_band(surface_world_position.xz, 0.135, 0.18, 0.4);
			band_b = directional_band(surface_world_position.xz, vec2(0.48, -0.87), 0.065, 0.10, 2.0);
			band_strength = 0.16 * (1.0 - far_mix * 0.65);
			color = mix(color * 0.91, color * 1.08, smoothstep(0.18, 0.82, band_a * 0.5 + 0.5) * 0.55);
		} else if (pass_id == 2.0) {
			// V2 separates the bands and uses a low-frequency value envelope to
			// stop all highlights from moving in synchronized rows.
			band_a = directional_band(surface_world_position.xz, vec2(0.98, 0.20), 0.14, 0.19, 0.8);
			band_b = directional_band(surface_world_position.xz, vec2(-0.42, 0.91), 0.071, 0.095, 3.7);
			float envelope = broad_swell_band(surface_world_position.xz * 0.78, 0.052, 0.06, 4.4);
			color *= 0.96 + envelope * 0.075;
			band_strength = 0.12 * (1.0 - far_mix * 0.76);
		} else {
			// V3 keeps only the strongest broad flow, quiets the horizon, and adds
			// a small local contact darkening around the test boat.
			band_a = directional_band(surface_world_position.xz, vec2(0.90, 0.34), 0.125, 0.17, 1.5);
			band_b = directional_band(surface_world_position.xz, vec2(-0.52, 0.85), 0.058, 0.078, 5.0);
			float contact = exp(-length(surface_world_position.xz) * 0.42);
			color = mix(color, color * 0.78, contact * 0.085);
			band_strength = 0.095 * (1.0 - far_mix * 0.88);
		}
	}

	float ribbons = band_a * 0.65 + band_b * 0.35;
	float soft_ribbon = smoothstep(0.14, 0.86, ribbons * 0.5 + 0.5);
	color += vec3(0.045, 0.070, 0.075) * (soft_ribbon - 0.45) * band_strength;

	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.0);
	color = mix(color, sky_tint, fresnel * 0.035 * (1.0 - far_mix * 0.30));
	ALBEDO = max(color, vec3(0.0));
	ROUGHNESS = 0.90;
	SPECULAR = 0.07;
}
