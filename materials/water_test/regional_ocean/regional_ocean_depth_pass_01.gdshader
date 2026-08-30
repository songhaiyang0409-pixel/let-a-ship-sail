shader_type spatial;

// OCEAN PRODUCTION DEPTH PASS 01
//
// Isolated visual candidate derived from the approved Regional Ocean B+ V3
// wave structure. The macro waves are intentionally kept identical to the
// shared B+ sampling path. Medium waves and the micro response are visual
// layers only; the boat continues to follow the shared macro sample.

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
uniform vec2 secondary_direction = vec2(-0.36, 0.93);
uniform float secondary_wavelength = 7.2;
uniform float secondary_steepness = 0.043;
uniform float secondary_time_scale = 0.48;
uniform float secondary_phase = 3.4;
uniform vec4 depth_medium_wave_1 = vec4(0.82, 0.24, 0.030, 7.5);
uniform vec4 depth_medium_wave_2 = vec4(-0.20, 0.98, 0.022, 12.0);
uniform float depth_medium_strength = 0.48;
uniform float depth_micro_strength = 0.035;
uniform float depth_micro_scale = 0.62;

group_uniforms Route;
uniform float route_origin_z = 10.0;
uniform float transition_01_start = 32.0;
uniform float transition_01_end = 48.0;
uniform float transition_12_start = 70.0;
uniform float transition_12_end = 86.0;
uniform float transition_23_start = 112.0;
uniform float transition_23_end = 128.0;
uniform float forced_region = -1.0;

group_uniforms Region0_HarborCalm;
uniform vec3 region0_trough_color : source_color;
uniform vec3 region0_water_color : source_color;
uniform vec3 region0_crest_color : source_color;
uniform vec3 region0_atmospheric_color : source_color;
uniform vec4 region0_tuning;
uniform vec4 region0_surface;

group_uniforms Region1_NorthAtlantic;
uniform vec3 region1_trough_color : source_color;
uniform vec3 region1_water_color : source_color;
uniform vec3 region1_crest_color : source_color;
uniform vec3 region1_atmospheric_color : source_color;
uniform vec4 region1_tuning;
uniform vec4 region1_surface;

group_uniforms Region2_OpenOcean;
uniform vec3 region2_trough_color : source_color;
uniform vec3 region2_water_color : source_color;
uniform vec3 region2_crest_color : source_color;
uniform vec3 region2_atmospheric_color : source_color;
uniform vec4 region2_tuning;
uniform vec4 region2_surface;

group_uniforms Region3_ShallowBay;
uniform vec3 region3_trough_color : source_color;
uniform vec3 region3_water_color : source_color;
uniform vec3 region3_crest_color : source_color;
uniform vec3 region3_atmospheric_color : source_color;
uniform vec4 region3_tuning;
uniform vec4 region3_surface;

group_uniforms BoatInteraction;
uniform vec3 boat_position_world = vec3(0.0);
uniform vec3 boat_forward_world = vec3(0.0, 0.0, -1.0);
uniform float boat_speed = 0.0;
uniform vec3 camera_position_world = vec3(0.0);

group_uniforms CoastalLocalModifiers;
uniform float coastal_local_enabled = 0.0;
uniform float coast_front_z = -24.0;
uniform float harbor_entry_z = -30.0;
uniform float harbor_back_z = -74.0;
uniform float harbor_half_width = 11.5;
uniform float harbor_wall_x = 16.0;

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

WaveResult gerstner_wave(vec4 params, vec2 pos, float time, float phase_offset, float regional_amplitude) {
	float steepness = params.z * dynamic_amplitude(pos, time) * wave_amplitude_scale * regional_amplitude;
	float wavelength = params.w * wave_length_scale;
	float k = 2.0 * PI / wavelength;
	float speed = sqrt(9.81 / k);
	vec2 direction = normalize(params.xy);
	float phase = k * (dot(direction, pos) - speed * time) + phase_offset;
	float amplitude = steepness / k;
	vec3 displacement = vec3(direction.x * amplitude * cos(phase), amplitude * sin(phase), direction.y * amplitude * cos(phase));
	vec3 tangent = vec3(1.0 - direction.x * direction.x * steepness * sin(phase), steepness * cos(phase), -direction.x * direction.y * steepness * sin(phase));
	vec3 binormal = vec3(-direction.x * direction.y * steepness * sin(phase), steepness * cos(phase), 1.0 - direction.y * direction.y * steepness * sin(phase));
	return WaveResult(displacement, tangent, binormal, normalize(cross(binormal, tangent)));
}

WaveResult base_wave(vec2 pos, float time, float regional_amplitude) {
	WaveResult result;
	result.displacement = vec3(0.0);
	result.tangent = vec3(1.0, 0.0, 0.0);
	result.binormal = vec3(0.0, 0.0, 1.0);
	result.normal = vec3(0.0, 1.0, 0.0);
	WaveResult current;
	current = gerstner_wave(wave_1, pos, time, 0.0, regional_amplitude);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_5, pos, time, 0.0, regional_amplitude);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_7, pos, time, 0.0, regional_amplitude);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	current = gerstner_wave(wave_8, pos, time, 0.0, regional_amplitude);
	result.displacement += current.displacement;
	result.tangent += current.tangent;
	result.binormal += current.binormal;
	result.normal += current.normal;
	result.normal = normalize(result.normal);
	return result;
}

WaveResult secondary_wave(vec2 pos, float time, float regional_amplitude) {
	return gerstner_wave(vec4(secondary_direction, secondary_steepness / max(wave_amplitude_scale, 0.001), secondary_wavelength / max(wave_length_scale, 0.001)), pos, time * secondary_time_scale, secondary_phase, regional_amplitude);
}

WaveResult medium_wave(vec4 params, vec2 pos, float time, float regional_amplitude) {
	return gerstner_wave(params, pos, time, 0.0, regional_amplitude);
}

vec4 profile_tuning(float id) {
	if (id < 0.5) return region0_tuning;
	if (id < 1.5) return region1_tuning;
	if (id < 2.5) return region2_tuning;
	return region3_tuning;
}

vec4 profile_surface(float id) {
	if (id < 0.5) return region0_surface;
	if (id < 1.5) return region1_surface;
	if (id < 2.5) return region2_surface;
	return region3_surface;
}

vec3 profile_color(float id, float kind) {
	if (id < 0.5) {
		if (kind < 0.5) return region0_trough_color;
		if (kind < 1.5) return region0_water_color;
		if (kind < 2.5) return region0_crest_color;
		return region0_atmospheric_color;
	}
	if (id < 1.5) {
		if (kind < 0.5) return region1_trough_color;
		if (kind < 1.5) return region1_water_color;
		if (kind < 2.5) return region1_crest_color;
		return region1_atmospheric_color;
	}
	if (id < 2.5) {
		if (kind < 0.5) return region2_trough_color;
		if (kind < 1.5) return region2_water_color;
		if (kind < 2.5) return region2_crest_color;
		return region2_atmospheric_color;
	}
	if (kind < 0.5) return region3_trough_color;
	if (kind < 1.5) return region3_water_color;
	if (kind < 2.5) return region3_crest_color;
	return region3_atmospheric_color;
}

vec4 route_tuning(vec2 pos) {
	if (forced_region >= -0.5) return profile_tuning(forced_region);
	float route_distance = max(-pos.y - route_origin_z, 0.0);
	float t01 = smoothstep(transition_01_start, transition_01_end, route_distance);
	float t12 = smoothstep(transition_12_start, transition_12_end, route_distance);
	float t23 = smoothstep(transition_23_start, transition_23_end, route_distance);
	vec4 blended = mix(profile_tuning(0.0), profile_tuning(1.0), t01);
	blended = mix(blended, profile_tuning(2.0), t12);
	return mix(blended, profile_tuning(3.0), t23);
}

vec4 route_surface(vec2 pos) {
	if (forced_region >= -0.5) return profile_surface(forced_region);
	float route_distance = max(-pos.y - route_origin_z, 0.0);
	float t01 = smoothstep(transition_01_start, transition_01_end, route_distance);
	float t12 = smoothstep(transition_12_start, transition_12_end, route_distance);
	float t23 = smoothstep(transition_23_start, transition_23_end, route_distance);
	vec4 blended = mix(profile_surface(0.0), profile_surface(1.0), t01);
	blended = mix(blended, profile_surface(2.0), t12);
	return mix(blended, profile_surface(3.0), t23);
}

vec3 route_color(vec2 pos, float kind) {
	if (forced_region >= -0.5) return profile_color(forced_region, kind);
	float route_distance = max(-pos.y - route_origin_z, 0.0);
	float t01 = smoothstep(transition_01_start, transition_01_end, route_distance);
	float t12 = smoothstep(transition_12_start, transition_12_end, route_distance);
	float t23 = smoothstep(transition_23_start, transition_23_end, route_distance);
	vec3 blended = mix(profile_color(0.0, kind), profile_color(1.0, kind), t01);
	blended = mix(blended, profile_color(2.0, kind), t12);
	return mix(blended, profile_color(3.0, kind), t23);
}

vec3 coastal_local_masks(vec2 pos) {
	if (coastal_local_enabled < 0.5) return vec3(0.0);
	float route_distance = max(-pos.y - route_origin_z, 0.0);
	float coast_mask = smoothstep(62.0, 98.0, route_distance);
	float harbor_entry_distance = max(-harbor_entry_z - route_origin_z, 0.0);
	float harbor_back_distance = max(-harbor_back_z - route_origin_z, harbor_entry_distance + 1.0);
	float harbor_z = smoothstep(harbor_entry_distance, harbor_entry_distance + 14.0, route_distance) * (1.0 - smoothstep(harbor_back_distance - 14.0, harbor_back_distance, route_distance));
	float harbor_x = 1.0 - smoothstep(harbor_half_width, harbor_wall_x, abs(pos.x));
	float harbor_mask = clamp(harbor_z * harbor_x, 0.0, 1.0);
	float outside_channel = smoothstep(harbor_half_width, harbor_wall_x + 4.0, abs(pos.x));
	float front_contact = (1.0 - smoothstep(0.0, 3.0, abs(pos.y - coast_front_z))) * outside_channel;
	float wall_contact = (1.0 - smoothstep(0.0, 2.5, abs(abs(pos.x) - harbor_half_width))) * harbor_z;
	return vec3(coast_mask, harbor_mask, clamp(front_contact + wall_contact, 0.0, 1.0));
}

vec4 apply_coastal_tuning(vec4 tuning, vec2 pos) {
	vec3 local = coastal_local_masks(pos);
	tuning.x *= 1.0 - local.x * 0.14 - local.y * 0.30;
	tuning.y *= 1.0 - local.x * 0.24 - local.y * 0.44;
	tuning.z *= 1.0 - local.x * 0.14 - local.y * 0.24;
	tuning.w += local.y * 0.012;
	return tuning;
}

void vertex() {
	vec2 pos = VERTEX.xz;
	float time = wave_time / time_factor;
	vec4 tuning = apply_coastal_tuning(route_tuning(pos), pos);
	WaveResult base = base_wave(pos, time, tuning.x);
	WaveResult secondary = secondary_wave(pos, time, tuning.x);
	WaveResult medium_a = medium_wave(depth_medium_wave_1, pos, time * 0.78, tuning.x);
	WaveResult medium_b = medium_wave(depth_medium_wave_2, pos, time * 0.61 + 1.7, tuning.x);
	vec3 displacement = base.displacement + secondary.displacement * tuning.y;
	displacement += (medium_a.displacement * 0.60 + medium_b.displacement * 0.40) * depth_medium_strength * tuning.y;
	vec3 normal = normalize(base.normal + secondary.normal * tuning.y * 0.55 + medium_a.normal * depth_medium_strength * 0.24 + medium_b.normal * depth_medium_strength * 0.18);
	VERTEX += displacement;
	wave_height = displacement.y;
	wave_normal = normal;
	surface_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 apply_saturation(vec3 color, float amount) {
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	return mix(vec3(luminance), color, amount);
}

void fragment() {
	vec4 tuning = route_tuning(surface_world_position.xz);
	vec4 surface = route_surface(surface_world_position.xz);
	float broad_swell = smoothstep(-0.38, 0.10, wave_height);
	float crest = smoothstep(0.10, 0.34, wave_height);
	vec3 trough = route_color(surface_world_position.xz, 0.0);
	vec3 water = route_color(surface_world_position.xz, 1.0);
	vec3 crest_color = route_color(surface_world_position.xz, 2.0);
	vec3 atmospheric = route_color(surface_world_position.xz, 3.0);
	vec3 color = mix(trough, water, broad_swell);
	color = mix(color, crest_color, crest * 0.10);

	vec3 local_conditions = coastal_local_masks(surface_world_position.xz);
	color = mix(color, color * vec3(0.93, 1.035, 1.02), local_conditions.x * 0.08);
	color = mix(color, color * vec3(0.97, 1.025, 1.015), local_conditions.y * 0.07);

	float distance_to_camera = distance(camera_position_world, surface_world_position);
	float far_mix = smoothstep(30.0, 110.0, distance_to_camera);
	color = mix(color, atmospheric, far_mix * tuning.w * 0.18);

	vec3 light_direction = normalize(vec3(0.35, 0.82, 0.22));
	float ndotl = clamp(dot(normalize(wave_normal), light_direction), 0.0, 1.0);
	color *= 0.94 + ndotl * 0.09;

	// A single broad, directional breakup layer. It is strongest nearby and
	// fades before the horizon so the distant sea remains a quiet shape.
	vec2 ripple_axis = normalize(vec2(0.84, -0.54));
	vec2 ripple_cross = vec2(-ripple_axis.y, ripple_axis.x);
	float ripple_a = sin(dot(surface_world_position.xz, ripple_axis) * depth_micro_scale - wave_time * 0.22);
	float ripple_b = sin(dot(surface_world_position.xz, ripple_cross) * depth_micro_scale * 0.56 - wave_time * 0.13 + 1.9);
	float ripple = (ripple_a * 0.68 + ripple_b * 0.32) * depth_micro_strength * (1.0 - far_mix);
	color *= 1.0 + ripple;

	// Rare crest breakup: low contrast and tied to the broad slope, never a
	// full-screen foam layer.
	float crest_breakup = smoothstep(0.0, 1.0, 0.5 + 0.5 * sin(dot(surface_world_position.xz, ripple_axis) * 0.42 - wave_time * 0.17 + 2.4));
	float foam = smoothstep(0.28, 0.48, wave_height) * crest_breakup * 0.055 * (1.0 - far_mix * 0.7);
	color = mix(color, crest_color, foam);

	vec2 boat_forward = normalize(boat_forward_world.xz);
	vec2 boat_right = vec2(-boat_forward.y, boat_forward.x);
	vec2 local = surface_world_position.xz - boat_position_world.xz;
	float forward_distance = dot(local, boat_forward);
	float side_distance = dot(local, boat_right);
	float bow_shape = exp(-pow((forward_distance + 0.82) * 1.18, 2.0) - pow(side_distance * 2.6, 2.0));
	color += vec3(0.035, 0.055, 0.058) * bow_shape * 0.045 * smoothstep(0.0, 0.7, boat_speed);

	color = apply_saturation(color, surface.x);
	float fresnel = pow(1.0 - max(dot(normalize(wave_normal), normalize(VIEW)), 0.0), 4.0);
	vec3 sky_tint = vec3(0.45, 0.58, 0.64);
	color = mix(color, sky_tint, fresnel * surface.y * 0.32 * (1.0 - far_mix * 0.25));
	color += vec3(0.035, 0.050, 0.048) * local_conditions.z * 0.10;
	ALBEDO = max(color, vec3(0.0));
	ROUGHNESS = 0.94;
	SPECULAR = surface.y * 0.45;
}
