extends Node3D
## Chapter 1 opening — the hardstand at dawn. Cold fog, the ship a silhouette,
## Pat by the tail. The player walks over, talks (medal beat, the Paine
## paperback), and boards. Restraint is the point: one conversation, then
## the war.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const GRASS := Color(0.24, 0.27, 0.21)
const CONCRETE := Color(0.42, 0.42, 0.40)
const CLOTH := Color(0.24, 0.22, 0.19)
const SKIN := Color(0.55, 0.44, 0.36)

var _player: CharacterBody3D

func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_bomber()
	_build_props()
	_build_pat()
	_spawn_player()
	AudioManager.play_ambient("hardstand_dawn")
	_intro()

func _intro() -> void:
	_player.move_enabled = false
	_player.look_enabled = false
	await CutscenePlayer.play("res://data/cutscenes/ch1/hardstand_intro.json", self)
	_player.move_enabled = true
	_player.look_enabled = true
	if "--autoplay" in OS.get_cmdline_user_args():
		CaptureHarness.snap("hardstand")

func _build_environment() -> void:
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://src/shaders/sky_dusk.gdshader")
	sky_mat.set_shader_parameter("top_color", Color(0.16, 0.20, 0.28))
	sky_mat.set_shader_parameter("horizon_color", Color(0.52, 0.48, 0.46))
	sky_mat.set_shader_parameter("ground_color", Color(0.20, 0.21, 0.19))
	sky_mat.set_shader_parameter("sun_color", Color(0.85, 0.72, 0.60))
	sky_mat.set_shader_parameter("horizon_sharpness", 2.2)
	sky_mat.set_shader_parameter("cloud_coverage", 0.55)
	sky_mat.set_shader_parameter("cloud_lit_color", Color(0.48, 0.46, 0.46))
	sky_mat.set_shader_parameter("cloud_shadow_color", Color(0.24, 0.25, 0.28))
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.34, 0.36, 0.40)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.44, 0.45, 0.46)
	env.fog_density = 0.028
	env.fog_sky_affect = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-9, 70, 0)
	sun.light_color = Color(0.9, 0.78, 0.65)
	sun.light_energy = 0.65
	sun.shadow_enabled = true
	add_child(sun)

func _build_ground() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(400, 0.3, 400), Vector3(0, -0.15, 0), GRASS)
	# Hardstand pad and taxiway
	mb.box(Vector3(42, 0.34, 40), Vector3(0, -0.13, 0), CONCRETE)
	mb.box(Vector3(10, 0.34, 120), Vector3(0, -0.13, 80), CONCRETE.darkened(0.06))
	var mi := mb.commit_instance("Ground")
	add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(400, 0.3, 400)
	cs.shape = shape
	cs.position = Vector3(0, -0.15, 0)
	body.add_child(cs)
	add_child(body)

func _build_bomber() -> void:
	# Tail-dragger stance: nose up, tail wheel down (rotation.x < 0 pitches
	# the -Z nose upward). Gear legs are computed from the pitched hull so
	# the wheels stay planted.
	var pitch := -0.10
	var pos := Vector3(0, 3.2, 4)
	var ship := ModelLib.get_model("b17", Aircraft.b17)
	ship.position = pos
	ship.rotation.y = 0.35
	ship.rotation.x = pitch
	add_child(ship)

	var mb := MeshBuilder.new()
	var hull := Basis(Vector3.UP, 0.35) * Basis(Vector3.RIGHT, pitch)
	var wheel_r := 0.75
	for side in [-4.4, 4.4]:
		# Main gear: from the wing underside straight down to the wheel.
		var attach: Vector3 = pos + hull * Vector3(side, -1.0, -2.4)
		var leg_len := attach.y - wheel_r
		mb.box(Vector3(0.25, leg_len, 0.25),
			Vector3(attach.x, attach.y - leg_len / 2.0, attach.z), Color(0.1, 0.1, 0.1))
		var wheel := CylinderMesh.new()
		wheel.top_radius = wheel_r
		wheel.bottom_radius = wheel_r
		wheel.height = 0.5
		wheel.radial_segments = 8
		mb.add(wheel, Transform3D(Basis(Vector3.FORWARD, PI / 2),
			Vector3(attach.x, wheel_r, attach.z)), Color(0.05, 0.05, 0.05))
	# Tail wheel under the pitched tail
	var tail_attach: Vector3 = pos + hull * Vector3(0, -0.8, 8.6)
	var tail_leg := maxf(tail_attach.y - 0.3, 0.4)
	mb.box(Vector3(0.16, tail_leg, 0.16),
		Vector3(tail_attach.x, tail_attach.y - tail_leg / 2.0, tail_attach.z), Color(0.1, 0.1, 0.1))
	var tw := CylinderMesh.new()
	tw.top_radius = 0.3
	tw.bottom_radius = 0.3
	tw.height = 0.28
	tw.radial_segments = 8
	mb.add(tw, Transform3D(Basis(Vector3.FORWARD, PI / 2),
		Vector3(tail_attach.x, 0.3, tail_attach.z)), Color(0.05, 0.05, 0.05))
	add_child(mb.commit_instance("Gear"))
	# Distant sister ships swallowed by the fog
	for spec in [[Vector3(-90, 3.4, 60), 1.1], [Vector3(70, 3.4, 110), -0.7]]:
		var far := ModelLib.get_model("b17", Aircraft.b17)
		far.position = spec[0]
		far.rotation.y = spec[1]
		add_child(far)

func _build_props() -> void:
	var drum_tint := Color(0.45, 0.36, 0.28)
	var crate_tint := Color(0.5, 0.44, 0.34)
	# Fuel drums (kit barrels, tinted to dawn)
	var drum_rng := RandomNumberGenerator.new()
	drum_rng.seed = 4
	for spot in [Vector3(-9, 0, -6), Vector3(-9.8, 0, -5.2), Vector3(-9.4, 0, -6.9),
			Vector3(-10.5, 0, -6.1), Vector3(7.2, 0, -8.1)]:
		var d := Kit.model("barrel", drum_tint, 1.15)
		if d:
			d.position = spot
			d.rotation.y = drum_rng.randf_range(0, TAU)
			add_child(d)
	# Crate stacks (kit boxes)
	for spec in [[Vector3(8, 0, -7), 0.2, 1.6], [Vector3(8.25, 0.62, -6.9), 0.55, 1.3],
			[Vector3(6.8, 0, -7.4), 0.9, 1.4]]:
		var c := Kit.model("box", crate_tint, spec[2])
		if c:
			c.position = spec[0]
			c.rotation.y = spec[1]
			add_child(c)
	# Bedroll + bucket by the drums (a crew waited here all night)
	var br := Kit.model("bedroll", Color(0.42, 0.40, 0.36), 1.3)
	if br:
		br.position = Vector3(-8.0, 0, -7.6)
		br.rotation.y = 1.2
		add_child(br)
	var bk := Kit.model("bucket", drum_tint, 1.2)
	if bk:
		bk.position = Vector3(-8.6, 0, -4.4)
		add_child(bk)
	# Bomb trolley silhouette (procedural)
	var mb := MeshBuilder.new()
	mb.box(Vector3(3.2, 0.3, 1.2), Vector3(-6, 0.45, 12), Color(0.16, 0.17, 0.16))
	mb.cylinder(0.4, 0.4, 2.6, Vector3(-6, 0.9, 12), Color(0.20, 0.21, 0.19))
	# Ground crew: two figures by the trolley and one at the drums —
	# somebody was up before the fliers.
	_crew_figure(mb, Vector3(-4.6, 0, 11.4), 2.2, Color(0.20, 0.21, 0.19))
	_crew_figure(mb, Vector3(-7.4, 0, 12.6), -0.8, Color(0.23, 0.22, 0.18))
	_crew_figure(mb, Vector3(-8.6, 0, -5.0), 0.9, Color(0.19, 0.20, 0.17))
	# Windsock, hanging slack in the still dawn air
	mb.cylinder(0.06, 0.08, 6.0, Vector3(22, 3.0, -16), Color(0.22, 0.22, 0.22))
	var sock := CylinderMesh.new()
	sock.top_radius = 0.10
	sock.bottom_radius = 0.30
	sock.height = 1.8
	sock.radial_segments = 6
	mb.add(sock, Transform3D(Basis(Vector3(0, 0, 1), 0.5), Vector3(22.5, 5.3, -16)),
		Color(0.55, 0.30, 0.18))
	add_child(mb.commit_instance("Props"))

	# Grass tufts along the pad edges (the concrete is an island in a field)
	var g_rng := RandomNumberGenerator.new()
	g_rng.seed = 12
	for i in 26:
		var tuft := Kit.model("grass", Color(0.40, 0.45, 0.32), g_rng.randf_range(1.0, 1.8))
		if tuft == null:
			break
		var ang := g_rng.randf_range(0, TAU)
		var r := g_rng.randf_range(22.0, 34.0)
		tuft.position = Vector3(cos(ang) * r, 0, sin(ang) * r)
		tuft.rotation.y = g_rng.randf_range(0, TAU)
		add_child(tuft)

## Standing silhouette figure in work clothes (same visual language as Pat).
func _crew_figure(mb: MeshBuilder, at: Vector3, yaw: float, cloth: Color) -> void:
	mb.box(Vector3(0.42, 0.62, 0.26), at + Vector3(0, 1.15, 0), cloth, yaw)
	mb.sphere(0.12, 0.24, at + Vector3(0, 1.62, 0), SKIN)
	mb.box(Vector3(0.34, 0.10, 0.30), at + Vector3(0, 1.66, 0), cloth.darkened(0.25), yaw)
	var b := Basis(Vector3.UP, yaw)
	for side in [-0.13, 0.13]:
		mb.box(Vector3(0.15, 0.85, 0.18), at + b * Vector3(side, 0.42, 0), cloth.darkened(0.15), yaw)
	for side in [-0.28, 0.28]:
		mb.box(Vector3(0.10, 0.55, 0.13), at + b * Vector3(side, 1.12, 0.02), cloth.darkened(0.08), yaw)

## Pat, standing near the tail, waiting.
func _build_pat() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(0.42, 0.62, 0.26), Vector3(0, 1.15, 0), CLOTH)
	mb.sphere(0.12, 0.24, Vector3(0, 1.62, 0), SKIN)
	mb.box(Vector3(0.34, 0.10, 0.30), Vector3(0, 1.66, 0), Color(0.28, 0.24, 0.16))  # cap
	for side in [-0.13, 0.13]:
		mb.box(Vector3(0.15, 0.85, 0.18), Vector3(side, 0.42, 0), CLOTH.darkened(0.15))
	for side in [-0.28, 0.28]:
		mb.box(Vector3(0.10, 0.55, 0.13), Vector3(side, 1.12, 0.02), CLOTH.darkened(0.08))
	# The medal: a small bright spot at the chest
	mb.box(Vector3(0.05, 0.06, 0.02), Vector3(0.08, 1.32, 0.15), Color(0.75, 0.68, 0.40))

	var pat := Interactable.new()
	pat.name = "Pat"
	pat.prompt = "Talk to Pat"
	pat.blocked_flag = "pat_talked"
	pat.position = Vector3(6.5, 0, 13.5)
	pat.rotation.y = 2.1
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.9, 1.8, 0.9)
	cs.shape = shape
	cs.position = Vector3(0, 0.9, 0)
	pat.add_child(cs)
	pat.add_child(ModelLib.get_model("airman_standing",
		func() -> Node3D: return mb.commit_instance("Visual")))
	pat.interacted.connect(_on_talk_pat)
	add_child(pat)

	# Boarding hatch — usable only after the conversation
	var hatch := Interactable.new()
	hatch.name = "Hatch"
	hatch.prompt = "Board"
	hatch.required_flag = "pat_talked"
	hatch.one_shot = true
	hatch.position = Vector3(2.5, 1.0, 9.5)
	var hcs := CollisionShape3D.new()
	var hshape := BoxShape3D.new()
	hshape.size = Vector3(1.2, 2.0, 1.2)
	hcs.shape = hshape
	hatch.add_child(hcs)
	hatch.interacted.connect(_on_board)
	add_child(hatch)

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-2, 0.1, -14)
	_player.rotation.y = PI + 0.4
	add_child(_player)
	GameState.add_item("paine_book")

func _on_talk_pat(player: Node) -> void:
	player.move_enabled = false
	Hud.hide_prompt()
	DialogueManager.start("res://data/dialogue/ch1/hardstand.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	GameState.set_flag("pat_talked")
	player.move_enabled = true

func _on_board(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	SceneDirector.goto_beat("raid", 1.5)

func _process(_delta: float) -> void:
	if "--autoplay" in OS.get_cmdline_user_args() and _player and _player.move_enabled:
		# Headless verification: walk the beats without input.
		if not GameState.get_flag("pat_talked"):
			var pat := get_node_or_null("Pat")
			if pat and _player.position.distance_to(pat.position) > 2.0:
				_player.position = _player.position.move_toward(pat.position, 0.06)
			elif pat:
				pat.interact(_player)
		else:
			var hatch := get_node_or_null("Hatch")
			if hatch:
				hatch.interact(_player)
