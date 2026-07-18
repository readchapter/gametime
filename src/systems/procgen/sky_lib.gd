class_name SkyLib
extends RefCounted
## One-call procedural sky: wraps sky_dusk.gdshader (gradient + sun disc +
## noise clouds + stars + moon) onto an Environment. Returns the material so
## scenes can tween parameters (dawn lerps, weather turns).

static func apply(env: Environment, params: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/shaders/sky_dusk.gdshader")
	for k: String in params:
		mat.set_shader_parameter(k, params[k])
	var sky := Sky.new()
	sky.sky_material = mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	return mat
