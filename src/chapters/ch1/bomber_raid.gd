extends Node3D
## Chapter 1 — the raid, from the tail turret. A choreographed escalation
## driven by data/ch1/raid_script.json: quiet flight, flak, fighter passes,
## the ship dying, the bail-out order, and the crawl to the hatch where
## Travis grabs a loose paper without knowing what it is. Fixed outcome —
## tension, not challenge.

const RAID_SCRIPT := "res://data/ch1/raid_script.json"
const PLAYER_SCENE := preload("res://src/player/player.tscn")

const OLIVE := Color(0.23, 0.24, 0.20)
const METAL := Color(0.13, 0.14, 0.13)
const METAL_LIGHT := Color(0.19, 0.20, 0.19)

var _turret: TurretController
var _fighters: Array[Fighter] = []
var _tracers: Array[Dictionary] = []
var _flak_level := 0
var _flak_accum := 0.0
var _fire_active := false
var _fire_light: OmniLight3D
var _smoke_quads: Array[MeshInstance3D] = []
var _papers: Array[Dictionary] = []
var _papers_active := false
var _player: CharacterBody3D
var _doc_paper: MeshInstance3D
var _doc_grabbed := false
var _jumped := false
var _formation: Array[Node3D] = []
var _falling_ship: Node3D
var _fall_smoke_t := 0.0
var _kill_subtitle_done := false
var _t := 0.0
# Timeline-critical randomness (fighter paths/durations) uses its own seeded
# stream so runs are reproducible regardless of frame rate; cosmetic effects
# (flak spread, smoke) stay on the global stream.
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	# Deterministic run: reproducible fighter paths for the capture loop, and
	# the groundwork for seeded replay variation later.
	_rng.seed = 7
	_build_environment()
	_build_interior()
	_build_formation()
	_build_own_contrails()
	_build_cloud_deck()

	_turret = TurretController.new()
	_turret.rotation.y = PI  # tail position: face backward, +Z
	_turret.fired.connect(_on_player_fired)
	add_child(_turret)
	Hud.show_crosshair(true)
	AudioManager.play_ambient("bomber_interior")

	# goto_beat leaves the screen faded to black; every gameplay scene must
	# reveal itself (descent/farmhouse do the same). Without this the raid
	# renders under a full-black overlay — looks like a hang.
	SceneDirector.fade_in(1.2)
	_run_script()

func _process(delta: float) -> void:
	_t += delta
	_update_flak(delta)
	_update_fire(delta)
	_update_papers(delta)
	# Smoke trail behind the falling sister ship
	if is_instance_valid(_falling_ship):
		_fall_smoke_t += delta
		if _fall_smoke_t > 0.22:
			_fall_smoke_t = 0.0
			spawn_smoke(_falling_ship.position + Vector3(randf_range(-2, 2), 1.0, 3.0), 2.4)

func _physics_process(delta: float) -> void:
	_update_tracers(delta)

# --- world building ---------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://src/shaders/sky_dusk.gdshader")
	sky_mat.set_shader_parameter("top_color", Color(0.10, 0.22, 0.48))
	sky_mat.set_shader_parameter("horizon_color", Color(0.66, 0.72, 0.80))
	sky_mat.set_shader_parameter("ground_color", Color(0.58, 0.62, 0.70))
	sky_mat.set_shader_parameter("sun_color", Color(1.0, 0.96, 0.86))
	sky_mat.set_shader_parameter("horizon_sharpness", 5.0)
	sky_mat.set_shader_parameter("cloud_coverage", 0.22)
	sky_mat.set_shader_parameter("cloud_lit_color", Color(0.95, 0.95, 0.98))
	sky_mat.set_shader_parameter("cloud_shadow_color", Color(0.55, 0.60, 0.70))
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.47, 0.56)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.68, 0.76)
	env.fog_density = 0.00018
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 150, 0)
	sun.light_color = Color(1.0, 0.97, 0.90)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

## Tail compartment: enclosure, tapered ribs toward the nose, glazing frame,
## ammo boxes. Camera sits at the origin looking +Z (out the tail).
func _build_interior() -> void:
	var mb := MeshBuilder.new()
	# Enclosure
	mb.box(Vector3(2.3, 0.08, 9.4), Vector3(0, -1.02, -3.4), METAL)          # floor
	mb.box(Vector3(2.3, 0.08, 9.4), Vector3(0, 1.25, -3.4), METAL)           # ceiling
	for side in [-1.18, 1.18]:
		mb.box(Vector3(0.07, 2.4, 9.4), Vector3(side, 0.1, -3.4), METAL)     # walls
	# Tapered ribs
	for i in 10:
		var z := 0.4 - i * 0.9
		var r := 0.85 + i * 0.035
		mb.box(Vector3(1.9, 0.09, 0.14), Vector3(0, r + 0.15, z), METAL_LIGHT)
		mb.box(Vector3(1.9, 0.09, 0.14), Vector3(0, -r - 0.1, z), METAL_LIGHT)
		for side in [-1.12, 1.12]:
			mb.box(Vector3(0.09, 2.0, 0.14), Vector3(side, 0.1, z), METAL_LIGHT)
	# Glazing frame around the tail window
	for side in [-0.62, 0.62]:
		mb.box(Vector3(0.06, 1.25, 0.07), Vector3(side, 0.0, 0.86), METAL_LIGHT)
	mb.box(Vector3(1.35, 0.06, 0.07), Vector3(0, 0.58, 0.86), METAL_LIGHT)
	mb.box(Vector3(1.35, 0.45, 0.10), Vector3(0, -0.80, 0.86), METAL)        # sill
	# Skin panels around the window opening
	mb.box(Vector3(2.3, 0.55, 0.10), Vector3(0, 0.95, 0.90), METAL)
	for side in [-0.95, 0.95]:
		mb.box(Vector3(0.45, 2.3, 0.10), Vector3(side, 0.1, 0.90), METAL)
	# Tail cone behind the glazing
	mb.box(Vector3(2.3, 0.5, 1.4), Vector3(0, 1.35, 1.4), METAL)
	mb.box(Vector3(2.3, 0.5, 1.4), Vector3(0, -1.15, 1.4), METAL)
	# The ship's own fin and rudder, looming directly overhead — the tail
	# gunner lives under it. Reads at the top of the view when looking up.
	mb.box(Vector3(0.24, 3.6, 2.6), Vector3(0, 3.2, 1.9), OLIVE)
	var fin_slope := PrismMesh.new()
	fin_slope.size = Vector3(0.24, 1.4, 2.6)
	mb.add(fin_slope, Transform3D(Basis(Vector3.RIGHT, -PI / 2), Vector3(0, 2.0, 0.4)), OLIVE)
	# Horizontal stabilizers flanking the compartment
	for s: float in [-1.0, 1.0]:
		mb.box(Vector3(4.6, 0.22, 2.2), Vector3(s * 3.4, 1.1, 0.9), OLIVE)
	# Ammo boxes and feed chutes
	mb.box(Vector3(0.5, 0.4, 0.7), Vector3(-0.75, -0.75, -0.4), OLIVE)
	mb.box(Vector3(0.5, 0.4, 0.7), Vector3(0.75, -0.75, -0.4), OLIVE)
	mb.box(Vector3(1.1, 0.16, 0.5), Vector3(0, -0.9, -1.6), METAL_LIGHT)
	# Forward bulkhead so the crawl doesn't end in open sky
	mb.box(Vector3(2.3, 2.5, 0.14), Vector3(0, 0.1, -8.2), Color(0.09, 0.10, 0.09))
	add_child(mb.commit_instance("Interior"))

	# Waist-window light pools, far up the fuselage
	for side in [-1.13, 1.13]:
		_emissive_quad(Vector3(0.05, 0.55, 0.75), Vector3(side, 0.25, -6.2),
			Color(0.55, 0.60, 0.70), 0.7)
		var pool := OmniLight3D.new()
		pool.position = Vector3(side * 0.7, 0.25, -6.2)
		pool.light_color = Color(0.60, 0.66, 0.78)
		pool.light_energy = 1.1
		pool.omni_range = 3.2
		add_child(pool)
	# Side hatch (crawl destination), kept dark until the end
	_emissive_quad(Vector3(0.05, 0.9, 0.6), Vector3(1.13, -0.2, -7.4),
		Color(0.30, 0.33, 0.38), 0.6)

func _build_formation() -> void:
	for spec in [[Vector3(25, 8, 90), 0.0], [Vector3(-32, 16, 130), 0.06], [Vector3(12, 24, 175), -0.05]]:
		var b17 := ModelLib.get_model("b17", Aircraft.b17)
		b17.position = spec[0]
		b17.rotation.y = spec[1]
		add_child(b17)
		_formation.append(b17)
		for engine_x in [-8.6, -4.4, 4.4, 8.6]:
			_contrail(spec[0] + Vector3(engine_x, -0.4, 130), 240.0, 0.28)

func _build_own_contrails() -> void:
	for spec in [Vector3(-8.6, -0.9, 90), Vector3(-4.4, -0.75, 90),
			Vector3(4.4, -0.75, 90), Vector3(8.6, -0.9, 90)]:
		_contrail(spec, 200.0, 0.32)

func _contrail(at: Vector3, length: float, alpha: float) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.9, 0.9, length)
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.92, 0.94, 0.97, alpha)
	mi.material_override = mat
	mi.position = at
	add_child(mi)

func _build_cloud_deck() -> void:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24000, 24000)
	mi.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/shaders/cloud_deck.gdshader")
	mi.material_override = mat
	mi.position = Vector3(0, -1600, 0)
	add_child(mi)

func _emissive_quad(size: Vector3, at: Vector3, color: Color, energy: float) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mi.material_override = mat
	mi.position = at
	add_child(mi)

# --- timeline ---------------------------------------------------------------

func _run_script() -> void:
	var f := FileAccess.open(RAID_SCRIPT, FileAccess.READ)
	if f == null:
		push_error("Missing raid script")
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	for step: Dictionary in data.get("steps", []):
		await _do_step(step)

func _do_step(step: Dictionary) -> void:
	match str(step.get("type", "")):
		"wait":
			await get_tree().create_timer(float(step.get("seconds", 1.0)), false).timeout
		"subtitle":
			Hud.subtitle(str(step.get("speaker", "")), str(step.get("text", "")),
				float(step.get("seconds", 4.0)))
		"flak":
			_flak_level = int(step.get("level", 0))
		"shake":
			_turret.add_trauma(float(step.get("amount", 0.5)))
		"damage":
			Hud.damage_flash(float(step.get("strength", 1.0)))
		"wave":
			await _spawn_wave(int(step.get("count", 2)))
		"wait_wave":
			while _fighters.size() > 0:
				await get_tree().process_frame
		"fire_start":
			_start_fire()
		"ship_down":
			_ship_down()
		"bailout":
			_begin_bailout()
		_:
			push_warning("Unknown raid step: " + str(step))

# --- combat -----------------------------------------------------------------

func _spawn_wave(count: int) -> void:
	for i in count:
		var attack := Vector3(_rng.randf_range(-35, 35), _rng.randf_range(-10, 22), _rng.randf_range(40, 70))
		var start := Vector3(_rng.randf_range(-150, 150), _rng.randf_range(-80, -20), _rng.randf_range(420, 520))
		var exit_p := Vector3(-signf(attack.x) * _rng.randf_range(120, 220),
			_rng.randf_range(-140, -60), _rng.randf_range(-140, -80))
		var fighter := Fighter.make(start, attack, exit_p, self)
		fighter.duration = _rng.randf_range(8.0, 10.5)
		fighter.gone.connect(_on_fighter_gone)
		_fighters.append(fighter)
		add_child(fighter)
		await get_tree().create_timer(1.2, false).timeout

func _on_fighter_gone(f: Fighter) -> void:
	_fighters.erase(f)

func on_fighter_killed(f: Fighter) -> void:
	# A falling wreck shouldn't block wait_wave or soak up further hits.
	_fighters.erase(f)
	if not _kill_subtitle_done:
		_kill_subtitle_done = true
		Hud.subtitle("PAT", "Smoke! He's out of it — that's yours, Tex!", 3.5)

func _on_player_fired(muzzle: Vector3, dir: Vector3) -> void:
	AudioManager.play_sfx("m2_shot", -6.0)
	_add_tracer(muzzle, dir * 340.0, Color(1.0, 0.72, 0.32), true)

func spawn_enemy_tracer(muzzle: Vector3, delay: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	var target := _turret.camera.global_position \
		+ Vector3(randf_range(-4, 4), randf_range(-4, 4), 0)
	var dir := (target - muzzle).normalized()
	_add_tracer(muzzle, dir * 300.0, Color(0.75, 1.0, 0.80), false)

func _add_tracer(from: Vector3, vel: Vector3, color: Color, friendly: bool) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.07, 0.07, 1.6)
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.5
	mi.material_override = mat
	mi.position = from
	if vel.length() > 0.01:
		mi.basis = Basis.looking_at(vel.normalized(), Vector3.UP)
	add_child(mi)
	_tracers.append({"node": mi, "vel": vel, "life": 2.2, "friendly": friendly, "near": false})

func _update_tracers(delta: float) -> void:
	for i in range(_tracers.size() - 1, -1, -1):
		var tr: Dictionary = _tracers[i]
		var node: MeshInstance3D = tr["node"]
		node.position += tr["vel"] * delta
		tr["life"] -= delta
		if tr["friendly"]:
			for f in _fighters:
				if is_instance_valid(f) and node.position.distance_to(f.position) < 6.0:
					f.hit()
					tr["life"] = 0.0
					break
		elif not tr["near"]:
			if node.position.distance_to(_turret.camera.global_position) < 2.8:
				tr["near"] = true
				_turret.add_trauma(0.22)
		if tr["life"] <= 0.0:
			node.queue_free()
			_tracers.remove_at(i)

func _update_flak(delta: float) -> void:
	if _flak_level <= 0:
		return
	_flak_accum += delta * (0.8 if _flak_level == 1 else 2.2)
	if _flak_accum >= 1.0:
		_flak_accum -= 1.0
		_flak_burst()

func _flak_burst() -> void:
	var yaw := randf_range(-0.55, 0.55)
	var pitch := randf_range(-0.22, 0.28)
	var dist := randf_range(65, 190)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var pos := dir * dist
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.8
	s.height = 3.6
	s.radial_segments = 6
	s.rings = 3
	mi.mesh = s
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.95, 0.55, 0.2, 0.95)
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	var tw := create_tween()
	tw.tween_callback(func() -> void: mat.albedo_color = Color(0.10, 0.095, 0.09, 0.85)).set_delay(0.07)
	tw.parallel().tween_property(mi, "scale", Vector3.ONE * randf_range(2.4, 3.2), 1.3)
	tw.parallel().tween_property(mi, "position", pos + Vector3(0, 2, 30), 1.6)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 1.6).set_delay(0.3)
	tw.tween_callback(mi.queue_free)
	if dist < 95.0:
		_turret.add_trauma(0.3)
		AudioManager.play_sfx("flak_close")

## Smoke with a drift vector — fire smoke streams down the fuselage past the
## turret; wreck smoke just billows.
func spawn_smoke(at: Vector3, size := 1.0, drift := Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = size
	s.height = size * 2.0
	s.radial_segments = 5
	s.rings = 2
	mi.mesh = s
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.16, 0.15, 0.14, 0.7)
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 2.5, 1.4)
	if drift != Vector3.ZERO:
		tw.parallel().tween_property(mi, "position", at + drift, 1.4)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 1.4)
	tw.tween_callback(mi.queue_free)

# --- ship on fire, papers, bail-out -----------------------------------------

## A sister ship takes a hit and falls out of the formation, trailing smoke —
## the beat that makes the flak real before it's Travis's turn.
func _ship_down() -> void:
	if _formation.size() < 2:
		return
	AudioManager.play_sfx("engine_dying", -6.0)
	_falling_ship = _formation[1]
	var start := _falling_ship.position
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_falling_ship, "position", start + Vector3(-90, -520, 240), 26.0)
	tw.parallel().tween_property(_falling_ship, "rotation:z", -0.7, 14.0)
	tw.parallel().tween_property(_falling_ship, "rotation:x", 0.35, 18.0)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_falling_ship):
			_falling_ship.queue_free()
		_falling_ship = null)
	await get_tree().create_timer(3.5, false).timeout
	CaptureHarness.snap("ship_down")

func _start_fire() -> void:
	_fire_active = true
	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(-0.6, 0.1, -2.6)
	_fire_light.light_color = Color(1.0, 0.45, 0.15)
	_fire_light.light_energy = 3.2
	_fire_light.omni_range = 7.0
	add_child(_fire_light)
	_emissive_quad(Vector3(0.06, 0.8, 1.2), Vector3(-1.08, -0.1, -2.6), Color(1.0, 0.5, 0.12), 2.4)

func _update_fire(delta: float) -> void:
	if not _fire_active:
		return
	_fire_light.light_energy = 3.2 + sin(_t * 13.0) * 0.6 + sin(_t * 5.3 + 0.7) * 0.45
	if randf() < delta * 2.5:
		spawn_smoke(Vector3(-0.6, 0.2, -2.6) + Vector3(randf_range(-0.3, 0.3), 0, 0),
			0.35, Vector3(0.3, 0.25, 6.5))

## Bail-out order: hand off from the turret to first-person movement. The
## player crawls forward through the fuselage to the side hatch, passing over
## the loose document (grabbed on instinct, no callout), and jumps.
func _begin_bailout() -> void:
	AudioManager.play_sfx("alarm_bell", -3.0)  # the bail-out bell
	Hud.hide_prompt()
	Hud.show_crosshair(false)
	_turret.enabled = false
	if _turret.camera:
		_turret.camera.current = false
	_turret.hide()  # remove the gun/muzzle meshes from the walk view
	GameState.set_flag("bailed_out")

	_add_interior_collision()
	_spawn_papers()

	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(0, -0.9, -0.3)
	_player.rotation.y = 0.0  # face -Z, up the fuselage toward the hatch
	_player.walk_speed = 2.3  # a cramped, deliberate crawl-pace
	add_child(_player)
	_player.camera.make_current()
	# Follow light so the dark interior stays readable as the player moves.
	var follow := OmniLight3D.new()
	follow.light_color = Color(0.82, 0.72, 0.55)
	follow.light_energy = 0.9
	follow.omni_range = 4.5
	follow.position = Vector3(0, 1.3, 0)
	_player.add_child(follow)

	_add_document_pickup(Vector3(0.3, -0.86, -3.4))
	_add_hatch(Vector3(1.02, -0.35, -7.0))
	Hud.subtitle("", "(The hatch — forward, on the right. Go.)", 6.0)

	if "--autoplay" in OS.get_cmdline_user_args():
		_autoplay_bailout()

func _add_interior_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "InteriorCollision"
	_col_box(body, Vector3(2.3, 0.15, 9.8), Vector3(0, -1.02, -3.4))    # floor
	_col_box(body, Vector3(0.12, 2.4, 9.8), Vector3(-1.17, 0.1, -3.4))  # left wall
	_col_box(body, Vector3(0.12, 2.4, 9.8), Vector3(1.17, 0.1, -3.4))   # right wall
	_col_box(body, Vector3(2.3, 2.4, 0.12), Vector3(0, 0.1, -8.15))     # forward bulkhead
	_col_box(body, Vector3(2.3, 2.4, 0.12), Vector3(0, 0.1, 1.1))       # tail behind spawn
	add_child(body)

func _col_box(body: StaticBody3D, size: Vector3, at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = at
	body.add_child(cs)

## The document: a paper on the floor, silently pocketed when the player
## reaches it. No prompt, no callout — the reveal is chapters away (spec §3).
func _add_document_pickup(at: Vector3) -> void:
	_doc_paper = MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.24, 0.006, 0.32)
	_doc_paper.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.85, 0.74)
	mat.emission_enabled = true
	mat.emission = Color(0.88, 0.85, 0.74)
	mat.emission_energy_multiplier = 0.6
	_doc_paper.material_override = mat
	_doc_paper.rotation.y = 0.5
	_doc_paper.position = at
	add_child(_doc_paper)

	var area := Area3D.new()
	area.position = at + Vector3(0, 0.5, 0)
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	cs.shape = shape
	area.add_child(cs)
	area.body_entered.connect(_on_document_touched)
	add_child(area)

func _on_document_touched(body: Node) -> void:
	if _doc_grabbed or not (body is CharacterBody3D):
		return
	_doc_grabbed = true
	GameState.add_item("document_fragment")  # silent, per brief
	if is_instance_valid(_doc_paper):
		var tw := create_tween()
		tw.tween_property(_doc_paper, "position",
			_doc_paper.position + Vector3(0, 1.1, 0), 0.3)
		tw.parallel().tween_property(_doc_paper, "scale", Vector3.ZERO, 0.3)
		tw.tween_callback(_doc_paper.queue_free)

## The side hatch: an Interactable on the right wall. Interact to jump.
func _add_hatch(at: Vector3) -> void:
	var hatch := Interactable.new()
	hatch.name = "Hatch"
	hatch.prompt = "Jump"
	hatch.one_shot = true
	hatch.position = at
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.7, 1.4, 1.1)
	cs.shape = shape
	hatch.add_child(cs)
	# Open hatchway: cold daylight spilling in against the dark interior.
	var glow := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.06, 1.15, 0.95)
	glow.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.66, 0.82)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.72, 0.9)
	mat.emission_energy_multiplier = 1.6
	glow.material_override = mat
	glow.position = Vector3(0.12, 0.1, 0)
	hatch.add_child(glow)
	var spill := OmniLight3D.new()
	spill.position = Vector3(-0.3, 0.2, 0)
	spill.light_color = Color(0.6, 0.72, 0.9)
	spill.light_energy = 1.2
	spill.omni_range = 3.0
	hatch.add_child(spill)
	hatch.interacted.connect(_on_hatch)
	add_child(hatch)

func _on_hatch(_who: Node) -> void:
	if _jumped:
		return
	_jumped = true
	if _player:
		_player.move_enabled = false
		_player.look_enabled = false
	Hud.hide_prompt()
	await SceneDirector.fade_out(0.9)
	_papers_active = false
	await CutscenePlayer.caption("— THE JUMP —", 3.0)
	SceneDirector.goto_beat("descent")

## Headless verification: crawl to the document, then the hatch, then jump.
func _autoplay_bailout() -> void:
	await get_tree().create_timer(0.6, false).timeout
	CaptureHarness.snap("bailout_view")
	await _autoplay_walk_to(Vector3(0.3, -0.9, -3.4))
	_on_document_touched(_player)
	await get_tree().create_timer(0.4, false).timeout
	await _autoplay_walk_to(Vector3(0.2, -0.9, -6.4))
	CaptureHarness.snap("hatch_view")
	await get_tree().create_timer(0.3, false).timeout
	_on_hatch(_player)

func _autoplay_walk_to(target: Vector3) -> void:
	var guard := 0
	while is_instance_valid(_player) and _player.position.distance_to(target) > 0.4 and guard < 800:
		_player.position = _player.position.move_toward(target, 0.05)
		guard += 1
		await get_tree().process_frame

## Loose papers from a shot-up map case, swirling in the wind blast. One of
## them ends up in Travis's jacket. No callout — the reveal is chapters away.
func _spawn_papers() -> void:
	_papers_active = true
	for i in 20:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.20, 0.28, 0.006)
		mi.mesh = b
		var mat := StandardMaterial3D.new()
		var paper_c := Color(0.85, 0.82, 0.72)
		mat.albedo_color = paper_c
		# Faint self-glow so they read inside the dark fuselage.
		mat.emission_enabled = true
		mat.emission = paper_c
		mat.emission_energy_multiplier = 0.45
		mi.material_override = mat
		mi.position = Vector3(randf_range(-0.75, 0.75), randf_range(-0.5, 0.7),
			randf_range(-7.5, -2.5))
		mi.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		add_child(mi)
		_papers.append({
			"node": mi,
			"vel": Vector3(randf_range(-0.25, 0.25), randf_range(-0.15, 0.25), randf_range(0.1, 0.35)),
			"spin": Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4)),
			"phase": randf() * TAU,
		})

func _update_papers(delta: float) -> void:
	if not _papers_active:
		return
	for p: Dictionary in _papers:
		var node: MeshInstance3D = p["node"]
		if not is_instance_valid(node):
			continue
		var flutter := Vector3(sin(_t * 3.0 + p["phase"]), cos(_t * 2.3 + p["phase"]), 0) * 0.4
		node.position += (p["vel"] + flutter) * delta
		node.rotation += p["spin"] * delta
		if node.position.z > 1.5:
			node.position.z = -7.5
