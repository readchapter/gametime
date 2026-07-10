shader_type spatial;
render_mode unshaded, cull_disabled;

// Undercast far below the bomber: a huge plane with fbm-noise alpha.
// Textureless like everything else.

uniform vec3 cloud_color : source_color = vec3(0.80, 0.83, 0.88);
uniform float noise_scale = 0.0012;
uniform float coverage : hint_range(0.0, 1.0) = 0.6;
uniform float drift = 0.002;

varying vec3 wpos;

float hash12(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
		mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x),
		u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.3, 9.1);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = fbm(wpos.xz * noise_scale + vec2(TIME * drift, 0.0));
	float a = smoothstep(1.0 - coverage, 1.0 - coverage + 0.35, n);
	ALBEDO = cloud_color;
	ALPHA = a * 0.92;
}
