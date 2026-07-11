extends Node3D
## Chapter 1 — the descent. Reuses the field scene (same seed: this is the
## exact field Travis lands in), adds the dying bomber receding, distant
## chutes (Pat ambiguity), drift steering, and the landing-grade consequence:
## drift toward the road/village and you get shot at and marked as seen.
## No fail state — the grade persists as flags the farmhouse dialogue and
## Chapter 2 read.

const FIELD_SCENE := preload("res://src/chapters/ch1/field.tscn")

var _para: ParachuteController
var _field: Node3D
var _fired_at := false
var _tracers: Array[Dictionary] = []
var _bomber: Node3D
var _bomber_vel := Vector3(-14, -3.5, 26)
var _smoke_accum := 0.0
var _t := 0.0

func _ready() -> void:
	_field = FIELD_SCENE.instantiate()
	add_child(_field)
	# Much thinner haze than the ground-level scene: the player has to read
	# the hedgerow / road / village zones from altitude to steer.
	var we: WorldEnvironment = _field.get_node("WorldEnvironment")
	we.environment.fog_density = 0.0006
	we.environment.fog_light_color = Color(0.42, 0.35, 0.28)
	we.environment.ambient_light_energy = 1.15
	# Earlier in the evening than the ground scene: sun high enough (~25 deg)
	# that the terrain is actually lit from above — the player steers by it.
	var sun: DirectionalLight3D = _field.get_node("Sun")
	sun.rotation_degrees = Vector3(-25, -110, 0)
	sun.light_energy = 1.5
	# The detailed field is only ~260m wide; from altitude most of the view
	# is past its edge. Continue the world: far countryside plane + a
	# field-toned sky ground hemisphere instead of the void.
	var sky_mat: ShaderMaterial = we.environment.sky.sky_material
	sky_mat.set_shader_parameter("ground_color", Color(0.14, 0.13, 0.10))
	add_child(_far_ground())

	_para = ParachuteController.new()
	_para.position = Vector3(-25, 340, -15)
	_para.height_probe = _field.height_at
	_para.deployed_canopy.connect(_on_deploy)
	_para.landed.connect(_on_landed)
	add_child(_para)
	_para.camera.make_current()

	_build_bomber()
	_build_distant_chutes()
	AudioManager.play_ambient("wind_descent")
	SceneDirector.fade_in(0.5)
	_beats()
	# Headless verification can't steer: bias the wind east so the run
	# exercises the ground-fire / bad-landing path.
	if "--autoplay" in OS.get_cmdline_user_args():
		_para.wind.x = 2.4

func _process(delta: float) -> void:
	_t += delta
	# The burning ship flies on without him.
	if is_instance_valid(_bomber):
		_bomber.position += _bomber_vel * delta
		_smoke_accum += delta
		if _smoke_accum > 0.25:
			_smoke_accum = 0.0
			_spawn_smoke(_bomber.position + Vector3(2, 0.5, -3))
	# Drifting toward the road gets Travis seen and shot at.
	if not _fired_at and _para.deployed and not _para.down \
			and _para.position.x > 40.0 and _para.position.y < 280.0:
		_fired_at = true
		GameState.set_flag("seen_during_descent")
		_ground_fire()

func _physics_process(delta: float) -> void:
	for i in range(_tracers.size() - 1, -1, -1):
		var tr: Dictionary = _tracers[i]
		var node: MeshInstance3D = tr["node"]
		node.position += tr["vel"] * delta
		tr["life"] -= delta
		if not tr["near"] and node.position.distance_to(_para.position) < 14.0:
			tr["near"] = true
			_para.add_shake(0.35)
		if tr["life"] <= 0.0:
			node.queue_free()
			_tracers.remove_at(i)

func _beats() -> void:
	await _para.deployed_canopy
	await get_tree().create_timer(1.5, false).timeout
	Hud.subtitle("", "(Canopy. Breathe.)", 3.0)
	await get_tree().create_timer(6.5, false).timeout
	Hud.subtitle("", "(Two more chutes, east — one short of the treeline. Pat—)", 4.5)
	CaptureHarness.snap("descent_view")

## Where you land is what tomorrow costs. Grade thresholds tuned so passive
## wind drift ends near the road (bad) and deliberate steering west reaches
## the hedgerow (good).
static func grade_landing(pos: Vector3) -> String:
	var a := Vector2(-10, -30)
	var b := Vector2(-90, 60)
	var p := Vector2(pos.x, pos.z)
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	if p.distance_to(a + ab * t) < 20.0:
		return "good"
	if pos.x > 50.0:
		return "bad"
	return "neutral"

func _on_deploy() -> void:
	AudioManager.play_sfx("chute_open")
	CaptureHarness.snap("canopy")

func _on_landed(pos: Vector3) -> void:
	CaptureHarness.snap("impact")
	var grade := grade_landing(pos)
	GameState.set_flag("landing_grade", grade)
	GameState.set_flag("landing_bad", grade == "bad" or GameState.get_flag("seen_during_descent"))
	Hud.damage_flash(1.3)
	_para.add_shake(1.0)
	AudioManager.play_sfx("impact_thud")
	AudioManager.stop_ambient(1.5)
	await SceneDirector.fade_out(0.4)
	await get_tree().create_timer(2.0, false).timeout
	await _wake_beat(pos)
	SceneDirector.goto_beat("farmhouse", 0.1)

## Spec beat 6: he comes to in the grass, the family standing over him,
## wary, a lamp kept low. Night has fallen while he was out.
func _wake_beat(pos: Vector3) -> void:
	var h := float(_field.height_at(pos.x, pos.z))
	var cam := _para.camera
	_para.position = Vector3(pos.x, h, pos.z)
	cam.position = Vector3(0, 0.45, 0)
	cam.rotation = Vector3(1.15, 0.2, -0.15)
	_para.set_process(false)

	# Night falls while he's out.
	var we: WorldEnvironment = _field.get_node("WorldEnvironment")
	we.environment.ambient_light_color = Color(0.10, 0.11, 0.17)
	we.environment.ambient_light_energy = 0.8
	we.environment.fog_density = 0.006
	var sun: DirectionalLight3D = _field.get_node("Sun")
	sun.light_energy = 0.12
	sun.light_color = Color(0.5, 0.6, 0.8)
	var sky_mat: ShaderMaterial = we.environment.sky.sky_material
	sky_mat.set_shader_parameter("top_color", Color(0.03, 0.04, 0.08))
	sky_mat.set_shader_parameter("horizon_color", Color(0.10, 0.10, 0.14))
	sky_mat.set_shader_parameter("sun_color", Color(0.0, 0.0, 0.0))

	# The family, leaning over him; Luc's lamp kept low.
	var around := [Vector3(1.1, 0, 0.8), Vector3(-1.0, 0, 1.0), Vector3(0.2, 0, 1.5)]
	for i in around.size():
		add_child(_wake_figure(_para.position + around[i], cam.global_position))
	var lamp := OmniLight3D.new()
	lamp.position = _para.position + Vector3(0.2, 1.1, 0.9)
	lamp.light_color = Color(1.0, 0.72, 0.45)
	lamp.light_energy = 1.4
	lamp.omni_range = 4.0
	add_child(lamp)

	await SceneDirector.fade_in(2.4)
	CaptureHarness.snap("wake")
	DialogueManager.start("res://data/dialogue/ch1/field_wake.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	await get_tree().create_timer(0.8, false).timeout

func _wake_figure(at: Vector3, toward: Vector3) -> Node3D:
	var mb := MeshBuilder.new()
	var cloth := Color(0.16, 0.15, 0.13)
	var yaw := atan2(toward.x - at.x, toward.z - at.z)
	var b := Basis(Vector3.UP, yaw)
	# Leaning in over him — torso and head shifted toward the camera.
	mb.box(Vector3(0.44, 0.60, 0.26), b * Vector3(0, 1.05, 0.14), cloth, yaw)
	mb.sphere(0.12, 0.24, b * Vector3(0, 1.42, 0.26), Color(0.48, 0.38, 0.31))
	for side in [-0.13, 0.13]:
		mb.box(Vector3(0.15, 0.80, 0.18), b * Vector3(side, 0.40, 0), cloth.darkened(0.15), yaw)
	var fig := ModelLib.get_model("villager_standing",
		func() -> Node3D: return mb.commit_instance("Figure"))
	fig.position = at
	if fig.name != "Figure":  # imported model: orient it ourselves
		fig.rotation.y = yaw
	return fig

func _ground_fire() -> void:
	AudioManager.play_sfx("distant_gunfire")
	Hud.subtitle("", "(Muzzle flashes. The road— they see the canopy—)", 4.0)
	for volley in 8:
		if _para.down:
			return
		var from := Vector3(randf_range(72, 95), 0, _para.position.z + randf_range(-50, 50))
		from.y = _field.height_at(from.x, from.z) + 1.5
		for i in 3:
			var target := _para.position + Vector3(randf_range(-10, 10), randf_range(-6, 6), randf_range(-10, 10))
			var dir := (target - from).normalized()
			_add_tracer(from + dir * (8.0 + i * 4.0), dir * 190.0)
		if volley == 2:
			CaptureHarness.snap("ground_fire")
		await get_tree().create_timer(0.55, false).timeout

func _add_tracer(from: Vector3, vel: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.09, 0.09, 2.2)
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.75, 1.0, 0.80)
	mat.emission_enabled = true
	mat.emission = Color(0.75, 1.0, 0.80)
	mat.emission_energy_multiplier = 2.5
	mi.material_override = mat
	mi.position = from
	mi.basis = Basis.looking_at(vel.normalized(), Vector3.UP)
	add_child(mi)
	_tracers.append({"node": mi, "vel": vel, "life": 2.8, "near": false})

## Coarse patchwork countryside continuing beyond the detailed field.
func _far_ground() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tint := FastNoiseLite.new()
	tint.seed = 33
	tint.frequency = 0.004
	var cell := 90.0
	var half := 1800.0
	var y := -3.0
	var x := -half
	while x < half:
		var z := -half
		while z < half:
			var t := (tint.get_noise_2d(x, z) + 1.0) * 0.5
			var c := Color(0.19, 0.26, 0.13).lerp(Color(0.30, 0.28, 0.15), t)
			if tint.get_noise_2d(x * 3.0 + 500.0, z * 3.0) > 0.32:
				c = Color(0.24, 0.19, 0.13)  # plowed patches
			for p in [Vector3(x, y, z), Vector3(x + cell, y, z), Vector3(x + cell, y, z + cell),
					Vector3(x, y, z), Vector3(x + cell, y, z + cell), Vector3(x, y, z + cell)]:
				st.set_color(c)
				st.set_normal(Vector3.UP)
				st.add_vertex(p)
			z += cell
		x += cell
	var mi := MeshInstance3D.new()
	mi.name = "FarGround"
	mi.mesh = st.commit()
	mi.material_override = MeshBuilder.vertex_color_material()
	return mi

func _build_bomber() -> void:
	_bomber = ModelLib.get_model("b17", Aircraft.b17)
	_bomber.position = Vector3(30, 320, 60)
	_bomber.rotation.y = 0.5
	_bomber.rotation.z = 0.12
	add_child(_bomber)

func _spawn_smoke(at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.4
	s.height = 2.8
	s.radial_segments = 5
	s.rings = 2
	mi.mesh = s
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.14, 0.13, 0.12, 0.65)
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 3.0, 2.2)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 2.2)
	tw.tween_callback(mi.queue_free)

func _build_distant_chutes() -> void:
	for spec in [Vector3(260, 240, 190), Vector3(310, 210, 240)]:
		var mb := MeshBuilder.new()
		var s := SphereMesh.new()
		s.radius = 3.0
		s.height = 2.2
		s.radial_segments = 8
		s.rings = 3
		mb.add(s, Transform3D(Basis.IDENTITY, Vector3(0, 5, 0)), Color(0.70, 0.68, 0.62))
		mb.box(Vector3(0.5, 0.9, 0.4), Vector3.ZERO, Color(0.15, 0.14, 0.13))
		var chute := mb.commit_instance("DistantChute")
		chute.position = spec
		add_child(chute)
		var tw := create_tween()
		tw.tween_property(chute, "position", spec + Vector3(25, -235, 15), 55.0)
