shader_type spatial;

// BOAT WAVE COUPLING OCEAN POLISH — isolated R&D only.
//
// The base four-wave Gerstner surface is intentionally copied from the
// locked Variant B / Hybrid V3 R&D baseline. Candidate modes only add a
// weaker, broad secondary system and restrained graphic shading. There are
// no textures, foam stacks, refraction, caustics, or screen-space effects.

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
uniform vec2 secondary_direction = vec2(0.82, 0.28);
uniform float secondary_wavelength = 5.4;
uniform float secondary_steepness = 0.035;
uniform float secondary_time_scale = 0.70;
uniform float secondary_phase = 0.0;
uniform float secondary_displacement_scale = 1.0;

group_uniforms GraphicColors;
uniform vec3 trough_color : source_color = vec3(0.022, 0.115, 0.205);
uniform vec3 water_color : source_color = vec3(0.048, 0.245, 0.355);
uniform vec3 crest_color : source_color = vec3(0.145, 0.36, 0.415);
uniform vec3 atmospheric_color : source_color = vec3(0.205, 0.33, 0.39);
uniform vec3 sky_tint : source_color = vec3(0.48, 0.64, 0.69);
uniform vec3 directional_light_direction_world = vec3(0.35, 0.82, 0.22);
uniform vec3 camera_position_world = vec3(0.0);
uniform float style_family = 0.0; // 0=B family, 1=Hybrid V3 family
uniform float iteration = 3.0;

group_uniforms BoatInteraction;
uniform vec3 boat_position_world = vec3(0.0);
uniform vec3 boat_forward_world = vec3(0.0, 0.0, -1.0);
uniform float boat_speed = 0.0;
uniform float contact_strength = 0.0;
uniform float waterline_strength = 0.0;

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

WaveResult gerstner_wave(vec4 params, vec2 pos, float time, float phase_offset) {
	float steepness = params.z * dynamic_amplitude(pos, time) * wave_amplitude_scale;
	float wavelength = params.w * wave_length_scale;
	float k = 2.0 * PI / wavelength;
	float speed = sqrt(9.81 / k);
	vec2 direction = normalize(params.xy);
	float phase = k * (dot(direction, pos) - speed * time) + phase_offset;
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
	current = gerstner_wave(wave_1, pos, time, 0.0);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_5, pos, time, 0.0);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_7, pos, time, 0.0);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_8, pos, time, 0.0);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	result.normal = normalize(result.normal);
	return result;
}

WaveResult secondary_wave(vec2 pos, float time) {
	WaveResult result = gerstner_wave(
		// gerstner_wave applies the base wave_length_scale and
		// wave_amplitude_scale internally; undo those two base scales here so
		// the GDScript sampler and the vertex shader evaluate the same wave.
		vec4(secondary_direction, secondary_steepness / max(wave_amplitude_scale, 0.001), secondary_wavelength / max(wave_length_scale, 0.001)),
		pos,
		time * secondary_time_scale,
		secondary_phase
	);
	result.displacement *= secondary_displacement_scale;
	return result;
}

float triangle_wave(float value) {
	return abs(fract(value) * 2.0 - 1.0);
}

float broad_ribbon(vec2 pos, vec2 direction, float scale, float speed, float phase) {
	vec2 dir = normalize(direction);
	float along = dot(pos, dir) * scale - wave_time * speed + phase;
	float cross_flow = dot(pos, vec2(-dir.y, dir.x)) * 0.015;
	return sin(along + sin(cross_flow + phase) * 0.38);
}

void vertex() {
	vec2 pos = VERTEX.xz;
	float time = wave_time / time_factor;
	WaveResult base = base_wave(pos, time);
	vec3 displacement = base.displacement;
	vec3 normal = base.normal;
	if (secondary_displacement_scale > 0.0) {
		WaveResult secondary = secondary_wave(pos, time);
		displacement += secondary.displacement;
		normal = normalize(normal + secondary.normal * secondary_displacement_scale * 0.55);
	}
	VERTEX += displacement;
	wave_height = displacement.y;
	wave_normal = normal;
	surface_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float crest = smoothstep(0.08, 0.30, wave_height);
	float water_mix = smoothstep(-0.34, 0.04, wave_height);
	vec3 color = mix(trough_color, water_color, water_mix);
	color = mix(color, crest_color, crest * 0.16);

	float distance_to_camera = distance(camera_position_world, surface_world_position);
	float far_mix = smoothstep(30.0, 96.0, distance_to_camera);
	color = mix(color, atmospheric_color, far_mix * 0.16);

	float ndotl = clamp(dot(normalize(wave_normal), normalize(directional_light_direction_world)), 0.0, 1.0);
	float slope_light = 0.94 + ndotl * 0.10;
	color *= slope_light;

	float ribbon = 0.0;
	float shape_breakup = 0.0;
	if (style_family < 0.5) {
		// B+: broad faceted read; the three iterations change the shading
		// treatment rather than merely nudging one scalar.
		float facet_a = triangle_wave(dot(surface_world_position.xz, vec2(0.92, 0.38)) * 0.105 - wave_time * 0.055);
		float facet_b = triangle_wave(dot(surface_world_position.xz, vec2(-0.28, 0.96)) * 0.072 + wave_time * 0.035 + 0.7);
		shape_breakup = facet_a * 0.62 + facet_b * 0.38;
		if (iteration < 1.5) {
			color = mix(color * 0.94, color * 1.055, smoothstep(0.22, 0.80, shape_breakup) * 0.50);
		} else if (iteration < 2.5) {
			ribbon = broad_ribbon(surface_world_position.xz, vec2(0.88, 0.32), 0.082, 0.070, 0.8);
			color = mix(color * 0.95, color * 1.065, smoothstep(0.18, 0.82, shape_breakup) * 0.44);
			color += vec3(0.018, 0.032, 0.040) * ribbon;
		} else {
			ribbon = broad_ribbon(surface_world_position.xz, vec2(0.74, -0.67), 0.067, 0.052, 2.2);
			color = mix(color * 0.955, color * 1.075, smoothstep(0.16, 0.84, shape_breakup) * 0.46);
			color += vec3(0.020, 0.034, 0.042) * ribbon * (1.0 - far_mix * 0.48);
		}
	} else {
		// H3+: quieter broad flow, keeping the H3 identity while adding a
		// separate low-frequency read and less synchronized value changes.
		float envelope = broad_ribbon(surface_world_position.xz, vec2(0.76, -0.65), 0.052, 0.042, 1.4);
		float flow = broad_ribbon(surface_world_position.xz, vec2(0.91, 0.34), 0.095, 0.062, 1.5);
		shape_breakup = smoothstep(-0.80, 0.80, envelope * 0.72 + flow * 0.28);
		if (iteration < 11.5) {
			color = mix(color * 0.965, color * 1.045, shape_breakup * 0.34);
		} else if (iteration < 12.5) {
			ribbon = broad_ribbon(surface_world_position.xz, vec2(-0.42, 0.91), 0.060, 0.047, 3.8);
			color = mix(color * 0.96, color * 1.055, shape_breakup * 0.36);
			color += vec3(0.015, 0.028, 0.035) * ribbon * (1.0 - far_mix * 0.58);
		} else {
			ribbon = broad_ribbon(surface_world_position.xz, vec2(-0.36, 0.93), 0.051, 0.038, 4.6);
			color = mix(color * 0.965, color * 1.060, shape_breakup * 0.38);
			color += vec3(0.016, 0.030, 0.037) * ribbon * (1.0 - far_mix * 0.66);
		}
	}

	// Waterline/contact treatments stay local and deliberately weak. They are
	// not a screen-space halo and do not alter geometry or gameplay physics.
	vec2 local = surface_world_position.xz - boat_position_world.xz;
	float contact = exp(-dot(local, local) * 2.8);
	float forward_distance = dot(local, normalize(boat_forward_world.xz));
	float side_distance = dot(local, vec2(-boat_forward_world.z, boat_forward_world.x));
	float bow_shape = exp(-pow((forward_distance + 0.82) * 1.18, 2.0) - pow(side_distance * 2.6, 2.0));
	color = mix(color, color * 0.88, contact * contact_strength);
	color += vec3(0.105, 0.16, 0.17) * bow_shape * waterline_strength * smoothstep(0.0, 0.7, boat_speed);

	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.0);
	color = mix(color, sky_tint, fresnel * 0.022 * (1.0 - far_mix * 0.25));
	ALBEDO = max(color, vec3(0.0));
	ROUGHNESS = 0.91;
	SPECULAR = 0.065;
}
