class_name Grade
extends RefCounted
## Material pass (realism roadmap, code change #3): loads a CC0 PBR texture
## set from assets/textures/<set>/ (Poly Haven or ambientCG file naming) into
## a StandardMaterial3D with the game's grading applied — desaturated,
## fog-friendly albedo multiply, full-roughness bias, restrained normals — so
## packs from different sources read as one game. Every lookup degrades
## gracefully: a missing set returns null and the caller keeps its
## procedural/vertex-color fallback (the game must run with zero assets).

const DIR := "res://assets/textures/"
## Cohesion grade: pulls every albedo map toward the dusk palette. Multiplied
## into albedo_color, same trick as Kit's tint on the Kenney atlas.
const ALBEDO_GRADE := Color(0.74, 0.80, 0.70)

const KEYS := {
	"albedo": ["_diff_", "_color", "_col_", "albedo"],
	"normal": ["_nor_gl_", "normalgl"],
	"rough": ["_rough", "roughness"],
	"ao": ["_ao_", "_ao.", "ambientocclusion"],
}

static var _warned := {}

## First set of `candidates` that exists on disk, or "" — lets call sites
## rank a Poly Haven hero set above ambientCG alternates above nothing.
static func first_set(candidates: Array) -> String:
	for c: String in candidates:
		if DirAccess.dir_exists_absolute(DIR + c) and find_map(c, "albedo") != null:
			return c
	return ""

## A single graded map from a set ("albedo"/"normal"/"rough"/"ao"), for
## shaders that assemble their own materials. Null when absent.
static func find_map(set_name: String, kind: String) -> Texture2D:
	var dir := DirAccess.open(DIR + set_name)
	if dir == null:
		return null
	for f in dir.get_files():
		var low := f.to_lower()
		if not (low.ends_with(".jpg") or low.ends_with(".png")):
			continue
		for key: String in KEYS[kind]:
			if key in low:
				return load(DIR + set_name + "/" + f)
	return null

## The factory: full graded StandardMaterial3D from a texture set.
## uv_scale is repeats-per-unit on UV1; `triplanar` switches to world
## triplanar mapping so procedural geometry needs no authored UVs.
static func pbr(set_name: String, uv_scale := 1.0, tint := ALBEDO_GRADE,
		triplanar := false) -> StandardMaterial3D:
	var albedo := find_map(set_name, "albedo")
	if albedo == null:
		if not _warned.has(set_name):
			_warned[set_name] = true
			print("Grade: no texture set '%s', caller keeps its fallback" % set_name)
		return null
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo
	mat.albedo_color = tint
	mat.metallic = 0.0
	mat.roughness = 1.0
	var rough := find_map(set_name, "rough")
	if rough:
		mat.roughness_texture = rough
	var nor := find_map(set_name, "normal")
	if nor:
		mat.normal_enabled = true
		mat.normal_texture = nor
		mat.normal_scale = 0.7  # restrained: fog and dusk light do the rest
	var ao := find_map(set_name, "ao")
	if ao:
		mat.ao_enabled = true
		mat.ao_texture = ao
		mat.ao_light_affect = 0.3
	mat.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	if triplanar:
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
	return mat
