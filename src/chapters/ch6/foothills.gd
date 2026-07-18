extends Node3D
## Chapter 6 — the shepherd's hut at the third bell tower: the last roof in
## France. Fire, cheese that argues back, a dog with judicial authority,
## and a Basque shepherd who has taken ninety-one parcels over the top —
## plus the bad stone in the bread: a man in a city coat went up the valley
## yesterday, asking for a parcel by name. He is ahead, not behind.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const STONE := Color(0.33, 0.31, 0.28)
const WOOD_DARK := Color(0.15, 0.11, 0.08)
const CLOTH_SHEPHERD := Color(0.28, 0.26, 0.22)
const CLOTH_PAT := Color(0.27, 0.25, 0.18)

const W := 5.8
const D := 4.6
const H := 2.4

var _player: CharacterBody3D
var _shepherd: Node3D
var _pat: Node3D
var _fire_light: OmniLight3D
var _door: Interactable
var _talk_done := false
var _t := 0.0

func _ready() -> void:
	_build_environment()
	_build_hut()
	_build_people()
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-0.2, 0.05, 1.4)
	_player.rotation.y = PI / 2 - 0.5  # facing the fire and the shepherd
	add_child(_player)
	_player.camera.make_current()
	_player.move_enabled = false
	AudioManager.play_ambient("night_interior")
	SceneDirector.fade_in(2.0)
	Hud.subtitle("", "(The last roof in France: stone, smoke, hanging cheeses, and a dog who has already decided about you.)", 5.5)
	CaptureHarness.snap("ch6_hut")
	_evening()

func _build_environment() -> void:
	var env := Environment.new()
	SkyLib.apply(env, {
		"top_color": Color(0.010, 0.014, 0.030),
		"horizon_color": Color(0.035, 0.045, 0.075),
		"ground_color": Color(0.012, 0.015, 0.025),
		"sun_color": Color(0.02, 0.02, 0.03),
		"star_amount": 0.75,
		"moon_amount": 0.5,
		"moon_dir": Vector3(0.4, 0.5, 0.65),
		"cloud_coverage": 0.15,
		"cloud_lit_color": Color(0.06, 0.07, 0.10),
		"cloud_shadow_color": Color(0.02, 0.025, 0.045),
	})
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.13, 0.13)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_hut() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(W, 0.2, D), Vector3(0, -0.1, 0), Color(0.24, 0.20, 0.15))
	mb.box(Vector3(W, 0.2, D), Vector3(0, H + 0.1, 0), WOOD_DARK)
	for x: float in [-1.6, 0.8]:
		mb.box(Vector3(0.16, 0.2, D), Vector3(x, H - 0.1, 0), WOOD_DARK.darkened(0.2))
	mb.box(Vector3(0.25, H, D), Vector3(-W / 2, H / 2, 0), STONE)
	mb.box(Vector3(0.25, H, D), Vector3(W / 2, H / 2, 0), STONE.darkened(0.05))
	mb.box(Vector3(W, H, 0.25), Vector3(0, H / 2, -D / 2), STONE)
	# South wall with the door gap (door x -0.3..0.7)
	mb.box(Vector3(2.6, H, 0.25), Vector3(-1.9, H / 2, D / 2), STONE)
	mb.box(Vector3(2.1, H, 0.25), Vector3(1.75, H / 2, D / 2), STONE)
	mb.box(Vector3(1.0, H - 1.95, 0.25), Vector3(0.2, (H + 1.95) / 2, D / 2), STONE.darkened(0.1))
	# The hearth on the west wall
	mb.box(Vector3(0.5, 1.6, 1.5), Vector3(-2.7, 0.8, -0.6), STONE.darkened(0.2))
	mb.box(Vector3(0.35, 0.7, 0.9), Vector3(-2.65, 0.4, -0.6), Color(0.04, 0.03, 0.02))
	# Bench, table, cheeses hanging from the beams, staffs by the wall
	mb.box(Vector3(1.6, 0.45, 0.45), Vector3(0.3, 0.22, -1.5), WOOD_DARK)
	mb.box(Vector3(1.1, 0.7, 0.8), Vector3(1.7, 0.35, 0.3), WOOD_DARK.lightened(0.08))
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	for i in 5:
		var cx := rng.randf_range(-1.4, 1.6)
		var cz := rng.randf_range(-1.6, 0.6)
		mb.cylinder(0.16, 0.19, 0.22, Vector3(cx, H - 0.45, cz), Color(0.62, 0.54, 0.34))
		mb.box(Vector3(0.02, 0.35, 0.02), Vector3(cx, H - 0.18, cz), Color(0.1, 0.09, 0.08))
	for sx: float in [2.5, 2.62]:
		mb.box(Vector3(0.05, 2.1, 0.05), Vector3(sx, 1.05, -1.9), Color(0.30, 0.22, 0.12), 0.1)
	# The iron pot over the fire, on its chain from a swing arm
	mb.box(Vector3(0.9, 0.06, 0.06), Vector3(-2.45, 1.55, -0.6), Color(0.10, 0.10, 0.11))
	mb.box(Vector3(0.025, 0.5, 0.025), Vector3(-2.2, 1.28, -0.6), Color(0.12, 0.12, 0.13))
	mb.cylinder(0.22, 0.17, 0.26, Vector3(-2.2, 0.95, -0.6), Color(0.08, 0.08, 0.09))
	# Firewood stacked in the hearth corner, an axe leaned on it
	var wrng := RandomNumberGenerator.new()
	wrng.seed = 7
	for i in 7:
		mb.cylinder(0.06, 0.06, 0.55,
			Vector3(-2.55 + wrng.randf_range(-0.1, 0.1), 0.08 + (i / 3) * 0.12,
				-1.75 + (i % 3) * 0.16), Color(0.30, 0.22, 0.13), 6)
	# The table set for the argument: bread, knife, two bowls, a jug
	mb.box(Vector3(0.42, 0.14, 0.2), Vector3(1.55, 0.77, 0.25), Color(0.62, 0.48, 0.28), 0.3)
	mb.box(Vector3(0.26, 0.02, 0.05), Vector3(1.85, 0.72, 0.45), Color(0.65, 0.66, 0.68), -0.5)
	for bx: Vector3 in [Vector3(1.35, 0.74, 0.55), Vector3(2.0, 0.74, 0.1)]:
		mb.cylinder(0.11, 0.07, 0.07, bx, Color(0.35, 0.28, 0.20))
	mb.cylinder(0.09, 0.12, 0.30, Vector3(1.25, 0.85, 0.05), Color(0.42, 0.34, 0.24))
	# A stool by the fire and coats on wall pegs
	mb.cylinder(0.16, 0.14, 0.09, Vector3(-1.0, 0.42, 0.35), WOOD_DARK.lightened(0.1))
	for leg in 3:
		var a := TAU * leg / 3.0
		mb.box(Vector3(0.05, 0.4, 0.05), Vector3(-1.0 + cos(a) * 0.11, 0.19, 0.35 + sin(a) * 0.11),
			WOOD_DARK)
	for px: float in [-0.6, 0.1]:
		mb.box(Vector3(0.05, 0.05, 0.14), Vector3(px, 1.85, -D / 2 + 0.18), Color(0.30, 0.22, 0.12))
		mb.box(Vector3(0.34, 0.62, 0.12), Vector3(px, 1.5, -D / 2 + 0.24),
			Color(0.22, 0.20, 0.16) if px < 0 else Color(0.26, 0.22, 0.15))
	# Snow blown over the threshold, melting in a dark arc
	mb.box(Vector3(0.9, 0.03, 0.35), Vector3(0.2, 0.02, D / 2 - 0.25), Color(0.70, 0.72, 0.76))
	mb.box(Vector3(0.6, 0.02, 0.22), Vector3(0.2, 0.025, D / 2 - 0.5), Color(0.16, 0.13, 0.10))
	add_child(mb.commit_instance("Hut"))

	# The night outside the door: far ridge silhouettes
	var ridge := MeshBuilder.new()
	ridge.prism(Vector3(14, 5.0, 3.0), Vector3(1.0, 2.0, D / 2 + 9.0), Color(0.05, 0.06, 0.09))
	ridge.prism(Vector3(10, 3.6, 2.5), Vector3(-5.0, 1.4, D / 2 + 7.0), Color(0.04, 0.05, 0.08))
	add_child(ridge.commit_instance("Ridge"))

	var body := StaticBody3D.new()
	for spec: Array in [
		[Vector3(W, 0.2, D), Vector3(0, -0.1, 0)],
		[Vector3(0.4, H, D), Vector3(-W / 2, H / 2, 0)],
		[Vector3(0.4, H, D), Vector3(W / 2, H / 2, 0)],
		[Vector3(W, H, 0.4), Vector3(0, H / 2, -D / 2)],
		[Vector3(2.6, H, 0.4), Vector3(-1.9, H / 2, D / 2)],
		[Vector3(2.1, H, 0.4), Vector3(1.75, H / 2, D / 2)],
		[Vector3(1.1, 0.7, 0.8), Vector3(1.7, 0.35, 0.3)],
	]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = spec[0]
		cs.shape = shape
		cs.position = spec[1]
		body.add_child(cs)
	add_child(body)

	# Fire glow + embers
	var embers := MeshInstance3D.new()
	var eb := BoxMesh.new()
	eb.size = Vector3(0.25, 0.1, 0.6)
	embers.mesh = eb
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(0.95, 0.4, 0.1)
	emat.emission_enabled = true
	emat.emission = Color(0.95, 0.4, 0.1)
	emat.emission_energy_multiplier = 2.2
	embers.material_override = emat
	embers.position = Vector3(-2.62, 0.12, -0.6)
	add_child(embers)
	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(-2.3, 0.7, -0.6)
	_fire_light.light_color = Color(1.0, 0.5, 0.2)
	_fire_light.light_energy = 1.6
	_fire_light.omni_range = 6.5
	_fire_light.shadow_enabled = true
	add_child(_fire_light)

func _build_people() -> void:
	_shepherd = Figures.villager(CLOTH_SHEPHERD, "Shepherd")
	_shepherd.position = Vector3(-1.6, 0, -1.3)
	_shepherd.rotation.y = -0.9
	add_child(_shepherd)
	# The dog: a small judicial presence by the hearth
	var mb := MeshBuilder.new()
	mb.box(Vector3(0.22, 0.28, 0.55), Vector3(0, 0.2, 0), Color(0.16, 0.14, 0.11))
	mb.box(Vector3(0.16, 0.18, 0.2), Vector3(0, 0.42, -0.32), Color(0.18, 0.16, 0.12))
	mb.box(Vector3(0.05, 0.14, 0.05), Vector3(0, 0.32, 0.32), Color(0.14, 0.12, 0.10), 0.4)
	var dog := mb.commit_instance("Dog")
	dog.position = Vector3(-1.9, 0, 0.4)
	dog.rotation.y = 2.3
	add_child(dog)
	if GameState.get_flag("with_pat"):
		_pat = Figures.villager(CLOTH_PAT, "Pat")
		_pat.position = Vector3(0.8, 0, -1.3)
		_pat.rotation.y = 0.6
		add_child(_pat)

func _evening() -> void:
	await get_tree().create_timer(3.0, false).timeout
	DialogueManager.start("res://data/dialogue/ch6/shepherd_talk.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	_talk_done = true
	_player.move_enabled = true
	CaptureHarness.snap("ch6_talk")
	Hud.subtitle("", "(Sleep, of a kind. Then a cold nose against your hand, twice, formally: the dog, serving her warrant.)", 5.5)
	await get_tree().create_timer(4.0, false).timeout
	_door = Interactable.new()
	_door.name = "HutDoor"
	_door.prompt = "Out, before light"
	_door.one_shot = true
	_door.position = Vector3(0.2, 0, D / 2 - 0.3)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 2.0, 0.9)
	cs.shape = shape
	cs.position = Vector3(0, 1.0, 0.2)
	_door.add_child(cs)
	_door.interacted.connect(_on_leave)
	add_child(_door)

func _on_leave(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	AudioManager.stop_ambient(1.5)
	GameState.set_flag("ch6_foothills_done", true)
	SceneDirector.goto_beat("ch6_crossing", 1.5)

func _process(delta: float) -> void:
	_t += delta
	if _fire_light:
		_fire_light.light_energy = 1.6 + sin(_t * 9.0) * 0.08 + sin(_t * 4.3 + 0.7) * 0.07
	_autoplay_step(delta)

func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled or not _talk_done:
		return
	if _door and is_instance_valid(_door):
		var target := Vector3(_door.position.x, _player.position.y, _door.position.z - 0.4)
		if _player.position.distance_to(target) > 1.2:
			_player.position = _player.position.move_toward(target, delta * 3.0)
		else:
			_door.interact(_player)
