shader_type sky;

// Falconeer-style procedural dusk sky: gradient + sun disc/glow + thin
// noise-cloud strata. No textures anywhere — all math.

uniform vec3 top_color : source_color = vec3(0.10, 0.13, 0.24);
uniform vec3 horizon_color : source_color = vec3(0.82, 0.45, 0.22);
uniform vec3 ground_color : source_color = vec3(0.05, 0.045, 0.055);
uniform vec3 sun_color : source_color = vec3(1.0, 0.72, 0.42);
uniform float horizon_sharpness : hint_range(1.0, 12.0) = 3.5;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.38;
uniform float cloud_scale = 1.6;
uniform float cloud_speed = 0.004;
uniform vec3 cloud_lit_color : source_color = vec3(0.95, 0.55, 0.35);
uniform vec3 cloud_shadow_color : source_color = vec3(0.16, 0.15, 0.22);
uniform float star_amount : hint_range(0.0, 1.0) = 0.0;
// Night scenes raise moon_amount and aim moon_dir; a cold disc + soft halo.
uniform float moon_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 moon_dir = vec3(0.5, 0.6, 0.3);
uniform vec3 moon_color : source_color = vec3(0.72, 0.78, 0.90);

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

void sky() {
	float up = EYEDIR.y;
	vec3 col;
	if (up >= 0.0) {
		col = mix(top_color, horizon_color, pow(1.0 - up, horizon_sharpness));
	} else {
		col = mix(ground_color, horizon_color, pow(clamp(1.0 + up, 0.0, 1.0), 10.0));
	}

	if (LIGHT0_ENABLED) {
		float c = dot(EYEDIR, LIGHT0_DIRECTION);
		float disc = smoothstep(0.99930, 0.99965, c);
		float glow = pow(max(c, 0.0), 32.0) * 0.45 + pow(max(c, 0.0), 6.0) * 0.14;
		col += sun_color * (disc * 2.5 + glow);
	}

	// Thin cloud strata projected onto a virtual plane above the horizon.
	if (up > 0.015) {
		vec2 cuv = EYEDIR.xz / (up + 0.18);
		float n = fbm(cuv * cloud_scale + vec2(TIME * cloud_speed, 0.0));
		float clouds = smoothstep(1.0 - cloud_coverage, 1.0 - cloud_coverage + 0.28, n);
		float band = smoothstep(0.015, 0.10, up) * (1.0 - smoothstep(0.30, 0.75, up));
		float sun_side = 0.0;
		if (LIGHT0_ENABLED) {
			sun_side = pow(max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0), 3.0);
		}
		vec3 cloud_col = mix(cloud_shadow_color, cloud_lit_color, sun_side);
		col = mix(col, cloud_col, clouds * band * 0.85);
	}

	// Stars: sparse bright cells on the upper hemisphere, faded near the
	// horizon. Only night scenes raise star_amount.
	if (star_amount > 0.0 && up > 0.05) {
		vec2 cell = floor(EYEDIR.xz / max(up, 0.12) * 90.0);
		float h = hash12(cell);
		float star = step(0.9965, h) * (0.4 + 0.6 * hash12(cell + 7.0));
		float horizon_fade = smoothstep(0.05, 0.30, up);
		// slow twinkle
		star *= 0.75 + 0.25 * sin(TIME * (1.5 + 3.0 * hash12(cell + 13.0)) + h * 40.0);
		col += vec3(0.9, 0.93, 1.0) * star * star_amount * horizon_fade;
	}

	if (moon_amount > 0.0) {
		float mc = dot(EYEDIR, normalize(moon_dir));
		float mdisc = smoothstep(0.99955, 0.99985, mc);
		float mglow = pow(max(mc, 0.0), 48.0) * 0.22 + pow(max(mc, 0.0), 8.0) * 0.05;
		col += moon_color * (mdisc * 1.5 + mglow) * moon_amount;
	}

	// Dither to hide gradient banding in the smooth dusk sky.
	col += (hash12(EYEDIR.xy * 1917.0) - 0.5) * 0.006;

	COLOR = col;
}
