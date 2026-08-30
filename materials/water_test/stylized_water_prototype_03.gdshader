shader_type spatial;

// Isolated Stylized Water Prototype 03.
//
// This is intentionally not a copy of the LesusX material. It keeps only the
// same Gerstner-wave starting point and renders the result as a few controlled
// color planes. There are no textures, screen-space refraction, caustics, or
// high-frequency normals in this prototype.
render_mode unshaded, cull_disabled;

group_uniforms Waves;
uniform vec4 wave_1 = vec4(0.3, 4.0, 0.2, 0.6);
uniform vec4 wave_2 = vec4(-0.26, -0.19, 0.01, 0.47);
uniform vec4 wave_3 = vec4(-7.67, 5.63, 0.1, 0.38);
uniform vec4 wave_4 = vec4(-0.42, -1.63, 0.1, 0.28);
uniform vec4 wave_5 = vec4(1.66, 0.07, 0.15, 1.81);
uniform vec4 wave_6 = vec4(1.20, 1.14, 0.01, 0.33);
uniform vec4 wave_7 = vec4(-1.6, 7.3, 0.11, 0.73);
uniform vec4 wave_8 = vec4(-0.42, -1.63, 0.15, 1.52);
uniform float wave_time = 0.0;
uniform float time_factor = 2.5;
uniform float wave_amplitude_scale = 0.95;
uniform float wave_length_scale = 3.2;

group_uniforms GraphicColors;
uniform vec3 trough_color : source_color = vec3(0.025, 0.16, 0.29);
uniform vec3 water_color : source_color = vec3(0.055, 0.36, 0.53);
uniform vec3 crest_color : source_color = vec3(0.34, 0.64, 0.68);
uniform float crest_strength = 0.55;
uniform float broad_light_strength = 0.10;

varying float wave_height;
varying vec3 wave_normal;

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
		direction.x * (amplitude * cos(phase)),
		amplitude * sin(phase),
		direction.y * (amplitude * cos(phase))
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
}

void fragment() {
	// Broad height bands create the graphic read: deep trough, main water,
	// and a restrained blue-green crest. No texture is sampled here.
	float water_mix = smoothstep(-0.12, 0.015, wave_height);
	float crest_mix = smoothstep(0.05, 0.18, wave_height) * crest_strength;
	vec3 color = mix(trough_color, water_color, water_mix);
	color = mix(color, crest_color, crest_mix);

	float facing = clamp(dot(normalize(wave_normal), normalize(vec3(-0.35, 0.92, 0.22))), 0.0, 1.0);
	color = mix(color, color * 1.08, facing * broad_light_strength);

	ALBEDO = color;
	ROUGHNESS = 0.88;
	SPECULAR = 0.07;
}
