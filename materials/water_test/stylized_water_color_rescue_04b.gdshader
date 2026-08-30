shader_type spatial;

// WATER COLOR RESCUE 04B - isolated Balanced color test.
// The Gerstner wave skeleton and its geometry remain identical to the
// Balanced preset: wave_1, wave_5, wave_7, wave_8, amplitude 0.55,
// wavelength scale 4.60, and time factor 2.7.
// Only the color/readability treatment is changed here.
render_mode unshaded, cull_disabled, depth_draw_opaque;

group_uniforms Waves;
uniform vec4 wave_1 = vec4(0.34, 3.60, 0.18, 0.86);
uniform vec4 wave_2 = vec4(-0.26, -0.19, 0.01, 0.47);
uniform vec4 wave_3 = vec4(-7.67, 5.63, 0.1, 0.38);
uniform vec4 wave_4 = vec4(-0.42, -1.63, 0.1, 0.28);
uniform vec4 wave_5 = vec4(1.42, 0.28, 0.12, 2.18);
uniform vec4 wave_6 = vec4(1.20, 1.14, 0.01, 0.33);
uniform vec4 wave_7 = vec4(-1.05, 2.90, 0.08, 1.30);
uniform vec4 wave_8 = vec4(-0.58, -1.22, 0.10, 1.82);
uniform float wave_time = 0.0;
uniform float time_factor = 2.7;
uniform float wave_amplitude_scale = 0.55;
uniform float wave_length_scale = 4.60;

group_uniforms ColorSources;
uniform vec3 trough_color : source_color = vec3(0.030, 0.115, 0.190);
uniform vec3 water_color : source_color = vec3(0.045, 0.235, 0.345);
uniform vec3 crest_color : source_color = vec3(0.120, 0.310, 0.370);
uniform vec3 atmospheric_water_color : source_color = vec3(0.180, 0.310, 0.380);
uniform vec3 sky_tint : source_color = vec3(0.48, 0.64, 0.69);
uniform vec3 directional_light_direction_world = vec3(0.35, 0.82, 0.22);
uniform vec3 camera_position_world = vec3(0.0, 0.0, 0.0);
uniform float crest_strength = 0.18;
uniform float directional_shading_strength = 0.16;
uniform float fresnel_strength = 0.065;
uniform float distance_color_strength = 0.16;
uniform float breakup_strength = 0.03;

varying float wave_height;
varying vec3 wave_normal;
varying vec2 surface_position;
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
	float c = sqrt(9.81 / k);
	vec2 direction = normalize(params.xy);
	float phase = k * (dot(direction, pos) - c * time);
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

WaveResult wave(vec2 pos, float time) {
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

void vertex() {
	WaveResult result = wave(VERTEX.xz, wave_time / time_factor);
	VERTEX += result.displacement;
	wave_height = result.displacement.y;
	wave_normal = result.normal;
	surface_position = VERTEX.xz;
	surface_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Smooth height source: the main water color occupies most of the range;
	// trough and crest are gentle shifts rather than hard bands.
	float water_mix = smoothstep(-0.34, 0.08, wave_height);
	float crest_mix = smoothstep(0.15, 0.40, wave_height) * crest_strength;
	vec3 color = mix(trough_color, water_color, water_mix);
	color = mix(color, crest_color, crest_mix);

	// Use the actual scene DirectionalLight direction supplied by the test
	// script. This only changes the broad value of a face, never creates a toon
	// threshold or a separate foam layer.
	vec3 light_view = normalize((VIEW_MATRIX * vec4(directional_light_direction_world, 0.0)).xyz);
	float ndotl = clamp(dot(normalize(NORMAL), light_view), 0.0, 1.0);
	color *= mix(1.0 - directional_shading_strength * 0.32, 1.0 + directional_shading_strength * 0.42, ndotl);

	// Very slow, very broad breakup: maximum contribution is approximately
	// +/-3% and is not intended to read as visible noise.
	float breakup = sin(surface_position.x * 0.095 + surface_position.y * 0.061 + wave_time * 0.075);
	color *= 1.0 + breakup * breakup_strength;
	color += vec3(0.0, 0.004, 0.005) * breakup * breakup_strength;

	// A restrained near-to-far atmospheric blend creates near / middle / far
	// separation without making the horizon a bright strip.
	float camera_distance = distance(camera_position_world, surface_world_position);
	float distance_mix = smoothstep(10.0, 58.0, camera_distance) * distance_color_strength;
	color = mix(color, atmospheric_water_color, distance_mix);

	// Small sky-color response at grazing angles, capped well below a horizon
	// reflection. The sky remains visibly lighter than the sea.
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 4.0);
	color = mix(color, sky_tint, fresnel * fresnel_strength);

	ALBEDO = max(color, vec3(0.0));
	ROUGHNESS = 0.93;
	SPECULAR = 0.08;
}
