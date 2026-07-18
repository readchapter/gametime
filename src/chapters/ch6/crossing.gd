extends Node3D
## Chapter 6 — the crossing. The white teeth of the sky: a snow shoulder
## above the grass line, wind with opinions, a cairn where France runs out
## of stones — and a man in a city coat who climbed ahead to keep the last
## appointment of his career. The game's final scene: the confrontation
## resolves by choice, Spain is thirty steps past sentiment, and the ledger
## is read over the fade.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const SNOW := Color(0.78, 0.80, 0.84)
const SNOW_SHADE := Color(0.62, 0.66, 0.74)
const ROCK := Color(0.30, 0.29, 0.30)
const ROCK_DARK := Color(0.22, 0.21, 0.23)
const COAT := Color(0.10, 0.10, 0.12)
const CLOTH_PAT := Color(0.27, 0.25, 0.18)
const CLOTH_SHEPHERD := Color(0.28, 0.26, 0.22)

const CAIRN_Z := 40.0
const SPAIN_Z := 52.0
const PATH_HALF := 3.2

enum Phase { FAREWELL, CLIMB, CAIRN, WALK_ON, DONE }

var _phase := Phase.FAREWELL
var _player: CharacterBody3D
var _voss: Node3D
var _pat: Node3D
var _shepherd: Node3D
var _sun: DirectionalLight3D
var _env: Environment
var _sky_mat: ShaderMaterial
var _wind_a: Node3D
var _wind_b: Node3D
var _snow_a: Node3D
var _snow_b: Node3D
var _white: ColorRect
var _t := 0.0
var _ridge_snapped := false
var _spain_snapped := false

func _ready() -> void:
	# Dev capture hook: drive the together/truth variant on a direct load.
	if "--ch6-pat" in OS.get_cmdline_user_args():
		GameState.set_flag("with_pat", true)
		GameState.set_flag("met_voss", true)
		GameState.set_flag("told_truth_document", true)
	_build_environment()
	_build_terrain()
	_build_cairn_and_voss()
	_build_wind()
	_build_whiteout()
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(0, 0.05, 0)
	_player.rotation.y = PI  # facing up the path, toward the col
	add_child(_player)
	_player.camera.make_current()
	_player.move_enabled = false
	_build_people()
	AudioManager.play_ambient("mountain_wind")
	SceneDirector.fade_in(2.5)
	_farewell()

func _build_environment() -> void:
	_env = Environment.new()
	_sky_mat = SkyLib.apply(_env, {
		"top_color": Color(0.20, 0.28, 0.44),
		"horizon_color": Color(0.60, 0.64, 0.72),
		"ground_color": Color(0.42, 0.45, 0.52),
		"sun_color": Color(0.55, 0.58, 0.66),
		"horizon_sharpness": 2.4,
		"cloud_coverage": 0.34,
		"cloud_scale": 2.4,
		"cloud_lit_color": Color(0.82, 0.84, 0.90),
		"cloud_shadow_color": Color(0.44, 0.48, 0.58),
	})
	_env.fog_sky_affect = 0.35
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.55, 0.58, 0.66)
	_env.ambient_light_energy = 1.0
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.55, 0.60, 0.68)
	_env.fog_density = 0.011
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-13, -118, 0)
	_sun.light_color = Color(0.72, 0.78, 0.92)
	_sun.light_energy = 0.85
	_sun.shadow_enabled = true
	add_child(_sun)

func _build_terrain() -> void:
	var mb := MeshBuilder.new()
	# The shoulder: a long snowfield with a trampled path up its spine.
	mb.box(Vector3(46, 0.3, 130), Vector3(0, -0.15, 34), SNOW)
	mb.box(Vector3(2.4, 0.32, 130), Vector3(0.2, -0.14, 34), SNOW_SHADE.darkened(0.06))
	var rng := RandomNumberGenerator.new()
	rng.seed = 66
	# Drifts and wind-scoured rock breaking the white
	for i in 34:
		var x := rng.randf_range(-20.0, 20.0)
		if absf(x) < 2.2:
			continue
		var z := rng.randf_range(-8.0, 66.0)
		if rng.randf() < 0.55:
			mb.prism(Vector3(rng.randf_range(1.5, 4.0), rng.randf_range(0.3, 0.9), rng.randf_range(1.2, 3.0)),
				Vector3(x, 0.1, z), SNOW.lightened(0.05), rng.randf_range(0, TAU))
		else:
			mb.box(Vector3(rng.randf_range(0.6, 1.8), rng.randf_range(0.3, 0.8), rng.randf_range(0.5, 1.4)),
				Vector3(x, 0.15, z), ROCK if rng.randf() < 0.5 else ROCK_DARK, rng.randf_range(0, TAU))
	# Flanking crags: rock at the base, strata bands, snow teeth above with
	# a wind-built cornice lip on the lee side
	for spec: Array in [
		[Vector2(-12.0, 14.0), 9.0, 16.0], [Vector2(-16.0, 30.0), 12.0, 22.0],
		[Vector2(-13.0, 48.0), 10.0, 18.0], [Vector2(11.0, 8.0), 8.0, 15.0],
		[Vector2(15.0, 26.0), 13.0, 24.0], [Vector2(12.0, 44.0), 9.0, 17.0],
		[Vector2(17.0, 58.0), 11.0, 20.0],
	]:
		var at: Vector2 = spec[0]
		var h: float = spec[1]
		var w: float = spec[2]
		mb.prism(Vector3(w, h * 0.55, w * 0.8), Vector3(at.x, h * 0.2, at.y), ROCK_DARK)
		mb.box(Vector3(w * 0.72, 0.5, w * 0.60), Vector3(at.x, h * 0.16, at.y), ROCK.darkened(0.12))
		mb.box(Vector3(w * 0.52, 0.35, w * 0.46), Vector3(at.x, h * 0.30, at.y), ROCK.lightened(0.06))
		mb.prism(Vector3(w * 0.62, h, w * 0.5), Vector3(at.x, h * 0.42, at.y), SNOW_SHADE)
		var lee := 1.0 if at.x > 0 else -1.0
		mb.box(Vector3(w * 0.22, 0.30, w * 0.20),
			Vector3(at.x - lee * w * 0.16, h * 0.80, at.y), SNOW.lightened(0.12), 0.3)
	# The far teeth: the range itself, pale against the sky
	for spec: Array in [
		[-30.0, 95.0, 26.0, 40.0], [-8.0, 105.0, 32.0, 48.0], [14.0, 98.0, 24.0, 38.0],
		[34.0, 92.0, 20.0, 34.0], [-48.0, 90.0, 18.0, 30.0],
	]:
		mb.prism(Vector3(spec[3], spec[2], spec[3] * 0.7), Vector3(spec[0], spec[2] * 0.34, spec[1]),
			SNOW.lightened(0.06))
	# The smugglers' route markers: weathered stakes leaning out of the snow,
	# spaced up the shoulder — ninety-one parcels' worth of wayfinding
	var srng := RandomNumberGenerator.new()
	srng.seed = 92
	for z: float in [3.0, 10.0, 17.0, 24.0, 31.0, 37.5]:
		var sx := 2.0 if int(z) % 2 == 0 else -1.9
		mb.box(Vector3(0.07, 1.15, 0.07), Vector3(sx, 0.5, z + srng.randf_range(-1.0, 1.0)),
			Color(0.20, 0.15, 0.09), srng.randf_range(-0.25, 0.25))
	# Kicked snow along the trampled line, and glints where the light catches
	for i in 40:
		var lx := srng.randf_range(-1.6, 1.9)
		var lz := srng.randf_range(0.0, 50.0)
		if srng.randf() < 0.5:
			mb.box(Vector3(srng.randf_range(0.15, 0.4), 0.07, srng.randf_range(0.12, 0.3)),
				Vector3(lx, 0.16, lz), SNOW.lightened(0.08), srng.randf_range(0, TAU))
		else:
			mb.box(Vector3(0.05, 0.03, 0.05), Vector3(lx, 0.17, lz),
				SNOW.lightened(0.22), srng.randf_range(0, TAU))
	# Behind: the France the player is leaving, dropping away dark
	mb.prism(Vector3(60, 10, 30), Vector3(-10, 2.0, -34), Color(0.20, 0.23, 0.28))
	mb.prism(Vector3(44, 7, 24), Vector3(18, 1.2, -30), Color(0.17, 0.20, 0.25))
	add_child(mb.commit_instance("Ridge"))

	# A cloud band hanging below the far teeth, and one drifting wisp
	for spec: Array in [
		[Vector3(-6, 11.5, 86.0), Vector3(70, 2.6, 10), 0.34],
		[Vector3(22, 9.0, 80.0), Vector3(46, 1.8, 8), 0.26],
		[Vector3(-26, 14.5, 92.0), Vector3(34, 1.5, 7), 0.22],
	]:
		var cloud := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = spec[1]
		cloud.mesh = cm
		var cmat := StandardMaterial3D.new()
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cmat.albedo_color = Color(0.88, 0.90, 0.95, spec[2])
		cloud.material_override = cmat
		cloud.position = spec[0]
		add_child(cloud)

	# Far below and behind: the last lamps of a French valley, pre-dawn
	var lamps := MeshInstance3D.new()
	var lmesh := ImmediateMesh.new()
	var lmat := StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.albedo_color = Color(1.0, 0.82, 0.55)
	lmesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, lmat)
	for spec: Vector3 in [Vector3(-14, 1.1, -26), Vector3(-11.5, 0.8, -29),
			Vector3(6.0, 1.4, -27), Vector3(20, 0.6, -24)]:
		for v: Vector3 in [spec, spec + Vector3(0.16, 0, 0), spec + Vector3(0, 0.16, 0)]:
			lmesh.surface_add_vertex(v)
	lmesh.surface_end()
	lamps.mesh = lmesh
	add_child(lamps)

	var body := StaticBody3D.new()
	for spec: Array in [
		[Vector3(46, 0.3, 130), Vector3(0, -0.15, 34)],
		[Vector3(0.5, 4.0, 130), Vector3(-PATH_HALF - 0.4, 2.0, 34)],
		[Vector3(0.5, 4.0, 130), Vector3(PATH_HALF + 0.6, 2.0, 34)],
		[Vector3(10, 4.0, 0.5), Vector3(0, 2.0, -6.0)],
	]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = spec[0]
		cs.shape = shape
		cs.position = spec[1]
		body.add_child(cs)
	add_child(body)

func _build_cairn_and_voss() -> void:
	var mb := MeshBuilder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	# The cairn: every stone left by a leaving hand
	for layer in 6:
		var r := 0.75 - layer * 0.105
		var y := 0.14 + layer * 0.24
		var n := 7 - layer
		for i in n:
			var a := TAU * i / n + rng.randf_range(-0.2, 0.2)
			var stone_c := ROCK.lightened(rng.randf_range(-0.05, 0.12))
			mb.box(Vector3(rng.randf_range(0.26, 0.40), 0.24, rng.randf_range(0.22, 0.34)),
				Vector3(-1.35 + cos(a) * r, y, CAIRN_Z + sin(a) * r), stone_c, rng.randf())
	mb.box(Vector3(0.34, 0.26, 0.30), Vector3(-1.35, 1.56, CAIRN_Z), ROCK.lightened(0.15), 0.4)
	# Snow caps on the windward stones
	mb.box(Vector3(0.5, 0.05, 0.4), Vector3(-1.5, 1.7, CAIRN_Z), SNOW.lightened(0.1), 0.3)
	add_child(mb.commit_instance("Cairn"))
	var cbody := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.7, 1.8, 1.7)
	cs.shape = shape
	cs.position = Vector3(-1.35, 0.9, CAIRN_Z)
	cbody.add_child(cs)
	add_child(cbody)

	_voss = Figures.standing(COAT, true)
	_voss.position = Vector3(0.55, 0, CAIRN_Z + 0.9)
	_voss.rotation.y = 0.15  # facing down the path he has watched since noon
	add_child(_voss)
	# The folder under his arm: his whole war
	var fm := MeshBuilder.new()
	fm.box(Vector3(0.05, 0.30, 0.24), Vector3(0.34, 1.06, 0.02), Color(0.45, 0.38, 0.26))
	var folder := fm.commit_instance("Folder")
	_voss.add_child(folder)

func _build_people() -> void:
	_shepherd = Figures.villager(CLOTH_SHEPHERD, "Shepherd")
	_shepherd.position = Vector3(1.6, 0, 1.2)
	_shepherd.rotation.y = -2.2
	add_child(_shepherd)
	# A few sheep, already turning back: the best papers in these hills
	var mb := MeshBuilder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	for i in 5:
		var at := Vector3(rng.randf_range(1.2, 3.4), 0, rng.randf_range(-3.5, -0.5))
		var yaw := rng.randf_range(2.4, 3.8)
		mb.box(Vector3(0.36, 0.34, 0.62), at + Vector3(0, 0.38, 0), Color(0.70, 0.68, 0.62), yaw)
		mb.box(Vector3(0.18, 0.20, 0.22), at + Vector3(sin(yaw) * -0.36, 0.55, cos(yaw) * -0.36),
			Color(0.24, 0.22, 0.20), yaw)
	add_child(mb.commit_instance("Sheep"))
	if GameState.get_flag("with_pat"):
		_pat = Figures.villager(CLOTH_PAT, "Pat")
		_pat.position = Vector3(-1.1, 0, 0.6)
		_pat.rotation.y = PI
		add_child(_pat)

func _build_wind() -> void:
	_wind_a = _wind_band(0.10, 31)
	_wind_b = _wind_band(0.07, 57)
	add_child(_wind_a)
	add_child(_wind_b)
	_snow_a = _snowfall(21)
	_snow_b = _snowfall(83)
	_snow_b.position.y = 3.0
	add_child(_snow_a)
	add_child(_snow_b)

## A field of small flakes, moved as a body and wrapped in _process — two
## offset copies at different speeds read as continuous snowfall.
func _snowfall(seed_v: int) -> Node3D:
	var node := Node3D.new()
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.96, 0.97, 1.0, 0.7)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	for i in 110:
		var p := Vector3(rng.randf_range(-14.0, 14.0), rng.randf_range(0.0, 6.0),
			rng.randf_range(-8.0, 58.0))
		var s := rng.randf_range(0.02, 0.045)
		for v: Vector3 in [p, p + Vector3(s, 0, 0), p + Vector3(0, s, 0)]:
			im.surface_add_vertex(v)
	im.surface_end()
	mi.mesh = im
	node.add_child(mi)
	return node

func _wind_band(alpha: float, seed_v: int) -> Node3D:
	var band := Node3D.new()
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.95, 0.96, 1.0, alpha)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	for i in 46:
		var p := Vector3(rng.randf_range(-16.0, 16.0), rng.randf_range(0.3, 3.4), rng.randf_range(-10.0, 62.0))
		var ln := rng.randf_range(1.2, 3.2)
		var th := 0.015
		for v: Vector3 in [
			p, p + Vector3(ln, 0, ln * 0.3), p + Vector3(0, th, 0),
			p + Vector3(0, th, 0), p + Vector3(ln, 0, ln * 0.3), p + Vector3(ln, th, ln * 0.3),
		]:
			im.surface_add_vertex(v)
	im.surface_end()
	mi.mesh = im
	band.add_child(mi)
	return band

func _build_whiteout() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	_white = ColorRect.new()
	_white.color = Color(0.94, 0.95, 0.98, 0.0)
	_white.set_anchors_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_white)
	add_child(layer)

func _farewell() -> void:
	await get_tree().create_timer(3.0, false).timeout
	Hud.subtitle("SHEPHERD", "Here the grass ends, and here my sheep turn back — and my authority with them. The path is one path now. You cannot miss the col; the col will not permit it.", 6.5)
	await get_tree().create_timer(6.8, false).timeout
	Hud.subtitle("SHEPHERD", "The cairn, then Spain, then the rest of your life. Whatever waits at the stones — the mountain has kept worse. Go, parcel. Ninety-two.", 6.0)
	await get_tree().create_timer(6.3, false).timeout
	if GameState.get_flag("with_pat"):
		Hud.subtitle("PAT", "Ninety-two and ninety-three, padre. — C'mon, Tex. Last leg. Sister Immaculata always said heaven's uphill both ways.", 5.5)
		await get_tree().create_timer(5.8, false).timeout
	_phase = Phase.CLIMB
	_player.move_enabled = true
	Hud.subtitle("", "(The wind takes the shepherd's goodbye and starts, immediately, on you.)", 4.5)

func _process(delta: float) -> void:
	_t += delta
	# Wind bands stream across the path, harder with altitude
	var prog: float = 0.0
	if _player:
		prog = clampf(_player.position.z / CAIRN_Z, 0.0, 1.0)
	var speed := 7.0 + prog * 9.0
	if _wind_a:
		_wind_a.position.x = fmod(_t * speed, 40.0) - 20.0
		_wind_b.position.x = fmod(_t * speed * 1.35 + 13.0, 40.0) - 20.0
	if _snow_a:
		# Fall plus sidelong drift, harder with altitude; wrap over 6m of sky
		_snow_a.position.y = 6.0 - fmod(_t * (0.9 + prog * 0.5), 6.0)
		_snow_a.position.x = fmod(_t * (1.2 + prog * 2.0), 28.0) - 14.0
		_snow_b.position.y = 6.0 - fmod(_t * (1.25 + prog * 0.5) + 3.0, 6.0)
		_snow_b.position.x = fmod(_t * (1.7 + prog * 2.2) + 9.0, 28.0) - 14.0
	if _player and _pat and is_instance_valid(_pat) and _phase in [Phase.CLIMB, Phase.WALK_ON]:
		# Ahead-left, in view: you climb watching his back, like the night walk
		var slot := _player.position + Vector3(-1.7, 0, 3.0)
		slot.y = 0
		if _phase == Phase.CLIMB:
			slot.z = minf(slot.z, CAIRN_Z - 4.5)  # he stops short of Voss with you
		_pat.position = _pat.position.move_toward(slot, delta * 3.8)
		_pat.rotation.y = PI
	if _phase == Phase.CLIMB and _player:
		if not _ridge_snapped and _player.position.z > 14.0:
			_ridge_snapped = true
			CaptureHarness.snap("ch6_ridge")
			Hud.subtitle("", "(Halfway up the shoulder there is a figure by the cairn. Small, dark, patient. It does not move, and neither does your stomach.)", 5.5)
		if _player.position.z >= CAIRN_Z - 6.5:
			_cairn_beat()
	if _phase == Phase.WALK_ON and _player and not _spain_snapped and _player.position.z > CAIRN_Z + 4.0:
		_spain_snapped = true
		CaptureHarness.snap("ch6_spain")
	_autoplay_step(delta)

func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	if _phase == Phase.CLIMB:
		var target := Vector3(0.2, _player.position.y, CAIRN_Z - 6.0)
		_player.position = _player.position.move_toward(target, delta * 3.2)
	elif _phase == Phase.WALK_ON:
		var target := Vector3(0.2, _player.position.y, SPAIN_Z + 2.0)
		_player.position = _player.position.move_toward(target, delta * 3.0)

func _cairn_beat() -> void:
	_phase = Phase.CAIRN
	_player.move_enabled = false
	_player.look_enabled = false
	Hud.hide_prompt()
	# Face the appointment
	var from_y := _player.rotation.y
	var to_voss := _voss.position - _player.position
	var to_y := atan2(-to_voss.x, -to_voss.z)
	to_y = from_y + wrapf(to_y - from_y, -PI, PI)
	var tw := create_tween()
	tw.tween_method(func(y: float) -> void:
		_player.rotation = Vector3(0, y, 0), from_y, to_y, 1.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	await get_tree().create_timer(0.8, false).timeout
	CaptureHarness.snap("ch6_cairn")
	Hud.focus(true)
	DialogueManager.start("res://data/dialogue/ch6/voss_cairn.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	Hud.focus(false)
	_resolve()

func _resolve() -> void:
	if GameState.get_flag("killed_voss"):
		await _resolve_kill()
		return
	if GameState.get_flag("told_voss_truth"):
		await _resolve_concluded()
	elif not GameState.get_flag("voss_fired"):
		# "Beaten by everyone": he steps back from the path, procedure concluding
		var tw := create_tween()
		tw.tween_property(_voss, "position", _voss.position + Vector3(1.3, 0, 0.4), 2.2) \
			.set_trans(Tween.TRANS_SINE)
		await get_tree().create_timer(2.5, false).timeout
	_walk_on()

func _resolve_concluded() -> void:
	# He sits down on the cairn among every stone left by every leaving hand
	var tw := create_tween()
	tw.tween_property(_voss, "position", Vector3(-1.35, 0.62, CAIRN_Z + 0.95), 2.6) \
		.set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_voss, "rotation:y", 0.4, 2.6)
	await tw.finished
	_voss.scale.y = 0.72  # folded onto the stones, folder flat on his knees
	await get_tree().create_timer(1.6, false).timeout
	CaptureHarness.snap("ch6_concluded")

func _resolve_kill() -> void:
	AudioManager.stop_ambient(0.3)
	var tw := create_tween()
	tw.tween_property(_white, "color:a", 1.0, 0.9).set_trans(Tween.TRANS_QUAD)
	await get_tree().create_timer(0.45, false).timeout
	AudioManager.play_sfx("impact_thud", 2.0)
	await tw.finished
	CaptureHarness.snap("ch6_whiteout")
	if _voss and is_instance_valid(_voss):
		_voss.visible = false
	Hud.subtitle("", "(Eleven seconds. One for every statement in his folder. The mountain does not testify.)", 5.0)
	await get_tree().create_timer(5.5, false).timeout
	var tw2 := create_tween()
	tw2.tween_property(_white, "color:a", 0.0, 2.5)
	AudioManager.play_ambient("mountain_wind")
	await tw2.finished
	_walk_on()

func _walk_on() -> void:
	_phase = Phase.WALK_ON
	_player.move_enabled = true
	_player.look_enabled = true
	# Morning arrives over Spain: the light goes from bone to honey
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_sun, "light_color", Color(1.0, 0.87, 0.66), 14.0)
	tw.tween_property(_sun, "light_energy", 1.25, 14.0)
	tw.tween_property(_env, "fog_light_color", Color(0.75, 0.68, 0.60), 14.0)
	tw.tween_property(_sky_mat, "shader_parameter/horizon_color", Color(0.90, 0.76, 0.58), 14.0)
	tw.tween_property(_sky_mat, "shader_parameter/sun_color", Color(1.0, 0.86, 0.62), 14.0)
	tw.tween_property(_sky_mat, "shader_parameter/cloud_lit_color", Color(0.96, 0.84, 0.70), 14.0)
	Hud.subtitle("", "(Thirty steps. You count them without meaning to.)", 4.0)
	_watch_border()

func _watch_border() -> void:
	while _player.position.z < SPAIN_Z:
		await get_tree().create_timer(0.2, false).timeout
	if GameState.get_flag("voss_fired") and not GameState.get_flag("killed_voss"):
		await get_tree().create_timer(1.2, false).timeout
		AudioManager.play_sfx("rifle_crack", -4.0)
		Hud.subtitle("", "(One shot, behind you, into the snow. A full stop, fired at the end of his own sentence. You do not turn around.)", 5.5)
		await get_tree().create_timer(5.0, false).timeout
	_phase = Phase.DONE
	_player.move_enabled = false
	_player.look_enabled = false
	Hud.subtitle("", "(The thirty-first step is Spanish. It feels exactly like the others, which is the entire point of borders.)", 5.5)
	await get_tree().create_timer(6.0, false).timeout
	AudioManager.stop_ambient(3.0)
	await SceneDirector.fade_out(3.0)
	_ending_cards()

func _ending_cards() -> void:
	AudioManager.play_music("title_theme")
	await CutscenePlayer.caption("Sergeant Travis Boyd crossed into Spain\non a morning the war did not record.", 5.5)
	# The companion
	if GameState.get_flag("with_pat"):
		await CutscenePlayer.caption("Pat Costa crossed four paces behind him, talking.\nHe talked through Pamplona, Madrid, and Gibraltar,\nand did not stop, it is said, until Naples.", 6.5)
	else:
		await CutscenePlayer.caption("He crossed alone.\nThe careful ones always do. It is the fee.", 5.5)
	# Voss
	if GameState.get_flag("killed_voss"):
		await CutscenePlayer.caption("Kriminalkommissar Anton Voss was recorded missing\nin the mountains, file unresolved.\nThe cairn is one stone heavier.\nThe mountain does not testify.", 7.0)
	elif GameState.get_flag("told_voss_truth"):
		await CutscenePlayer.caption("Anton Voss walked back down into France\nand filed a single page: FILE CLOSED — OVERTAKEN BY EVENTS.\nSome men are killed.\nHis kind are concluded.", 7.0)
	else:
		await CutscenePlayer.caption("Anton Voss fired one shot that morning,\ninto the snow, wide and flat and final.\nNo report of it was ever filed.\nIt was not that kind of shot.", 7.0)
	# The paper
	if GameState.get_flag("told_truth_document"):
		await CutscenePlayer.caption("The page from the bomber — the one he carried without knowing,\nthe one a country of small true things moved past every checkpoint —\nreached London eleven days before he reached the wire at Gibraltar.", 7.5)
	else:
		await CutscenePlayer.caption("The page from the bomber, the one he carried without knowing,\nwas moved by hands he never saw and names he never learned.\nIt reached London. He read about the war it shortened\nin a newspaper, like everyone else.", 7.5)
	await CutscenePlayer.caption("On the sixth of June, 1944, the answer to that page\ncame back across the Channel in five thousand ships.", 6.0)
	# The ledger
	await _ledger_cards()
	# The book
	if GameState.get_flag("paine_kept"):
		await CutscenePlayer.caption("The Paine paperback came home with him,\nargued with in pencil, in two hands.\n'The summer soldier' is underlined twice.\nBeside it, no longer in question: 'Not me.'", 7.0)
	else:
		await CutscenePlayer.caption("The Paine paperback stayed in France, in a flour tin,\nwhere a lieutenant of the last war put it for safekeeping.\nIt is argued with in pencil, in two hands.\nPerhaps it is there still.", 7.0)
	await CutscenePlayer.caption("This story is finished.\nThe ledger never balances.\nIt was never supposed to.\nIt was only supposed to be carried.", 6.5)
	await CutscenePlayer.caption("THE END", 5.0)
	GameState.chapter = 7
	GameState.beat = ""
	GameState.save_game()
	get_tree().change_scene_to_file("res://src/ui/title.tscn")

func _ledger_cards() -> void:
	var lines: Array[String] = []
	if GameState.get_flag("beranger_taken"):
		lines.append("Lt. Béranger was taken at the barrier and did not return.\nThe line he built kept working. That was the design.")
	elif GameState.get_flag("trust_beranger"):
		lines.append("Lt. Béranger went on building his line in the dark,\none stamp, one barrier, one parcel at a time.")
	if GameState.get_flag("lucien_marked"):
		lines.append("Lucien spent what he had, as he said he would.\nThe line paid two to move one. It kept moving.")
	if GameState.get_flag("freeman_lost"):
		lines.append("Sgt. Freeman's name is on a wall in Cambridge,\namong nine thousand others the sky kept.")
	if lines.is_empty():
		lines.append("The line that moved him — the widow, the forger, the shepherd,\nninety-one parcels' worth of ordinary hands —\nwas never written down anywhere. That was the point.")
	for line in lines:
		await CutscenePlayer.caption(line, 6.5)
