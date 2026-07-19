shader_type spatial;
// Ground blend for the textured heightmap terrain (realism roadmap step 1).
// Two PBR sets (grass, dirt) blended by a per-vertex mask painted by
// field_gen: COLOR.r = dirt amount (dips, road shoulders, crop rows),
// COLOR.g = large-scale brightness variation that breaks tiling repetition.
// UVs are world-space so texel density is independent of mesh tessellation.

uniform sampler2D grass_diff: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_nor: hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D grass_rough: hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_diff: source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_nor: hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_rough: hint_default_white, filter_linear_mipmap, repeat_enable;
// Repeats per meter; CC0 sets are ~1-2m per tile.
uniform float grass_scale = 0.35;
uniform float dirt_scale = 0.30;
// Cohesion grade (Grade.ALBEDO_GRADE): desaturated dusk multiply.
uniform vec3 grade: source_color = vec3(0.74, 0.80, 0.70);
// Extra pull on the dirt set: mud albedo goes brick-red under the low
// warm sun without a cooler multiply.
uniform vec3 dirt_grade: source_color = vec3(0.55, 0.63, 0.66);

varying vec2 wuv;

void vertex() {
	wuv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

// Sample at two scales to hide the tile repeat at mid distance.
vec3 detile(sampler2D tex, vec2 uv) {
	return mix(texture(tex, uv).rgb, texture(tex, uv * 0.27 + 13.7).rgb, 0.35);
}

void fragment() {
	float m = COLOR.r;
	vec3 albedo = mix(detile(grass_diff, wuv * grass_scale),
			detile(dirt_diff, wuv * dirt_scale) * dirt_grade, m);
	float vary = mix(0.78, 1.18, COLOR.g);
	ALBEDO = albedo * grade * vary;
	NORMAL_MAP = mix(texture(grass_nor, wuv * grass_scale).rgb,
			texture(dirt_nor, wuv * dirt_scale).rgb, m);
	NORMAL_MAP_DEPTH = 0.7;
	ROUGHNESS = mix(texture(grass_rough, wuv * grass_scale).r,
			texture(dirt_rough, wuv * dirt_scale).r, m);
	METALLIC = 0.0;
	// Soil, not lacquer: kill the grazing-angle glare band toward the sun.
	SPECULAR = 0.1;
}
