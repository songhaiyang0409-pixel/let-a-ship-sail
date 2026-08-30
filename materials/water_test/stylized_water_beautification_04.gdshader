shader_type spatial;

// WATER BEAUTIFICATION 04 - isolated showable-water test.
// Keeps the project's custom Gerstner geometry approach while using broad,
// softly blended color fields. No textures, caustics, refraction, foam layer,
// or high-frequency normal map are used here.
render_mode cull_disabled, depth_draw_opaque;

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
uniform float wave_length_scale = 4.6;

group_uniforms GraphicColors;
uniform vec3 trough_color : source_color = vec3(0.022, 0.105, 0.18);
uniform vec3 water_color : source_color = vec3(0.035, 0.245, 0.35);
uniform vec3 crest_color : source_color = vec3(0.16, 0.36, 0.40);
uniform float crest_strength = 0.24;
uniform float broad_light_strength = 0.035;
uniform float surface_breakup_strength = 0.018;
uniform float fresnel_strength = 0.035;

varying float wave_height;
varying vec3 wave_normal;
varying vec2 surface_position;

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
}

void fragment() {
	// Broad transitions keep the main water color dominant and avoid hard
	// three-color bands or large pure-cyan patches.
	float water_mix = smoothstep(-0.34, 0.08, wave_height);
	float crest_mix = smoothstep(0.12, 0.34, wave_height) * crest_strength;
	vec3 color = mix(trough_color, water_color, water_mix);
	color = mix(color, crest_color, crest_mix);

	// A very low-frequency breakup prevents a perfectly mathematical surface
	// without introducing a noisy texture layer.
	float breakup = sin(surface_position.x * 0.11 + surface_position.y * 0.07 + wave_time * 0.09) * surface_breakup_strength;
	color += breakup;

	vec3 view_direction = normalize(VIEW);
	float fresnel = pow(1.0 - max(dot(normalize(NORMAL), view_direction), 0.0), 3.0);
	color += vec3(0.035, 0.055, 0.055) * fresnel * fresnel_strength;
	color *= 1.0 + broad_light_strength * 0.35;

	ALBEDO = max(color, vec3(0.0));
	ROUGHNESS = 0.94;
	SPECULAR = 0.08;
}
