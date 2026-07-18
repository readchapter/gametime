extends Node3D
## Chapter 5A — the train east. A boxcar full of other men's wars, slat-light
## strobing through the boards — and in the quietest corner, flipping a small
## bright saint on a chain, the reunion four chapters in the making. Then the
## grade before the border, the half-loosened bolt, and the second time in
## this war Travis Boyd jumps from a moving machine.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const CAR_W := 3.2
const CAR_L := 8.4
const CAR_H := 2.5
const WOOD := Color(0.21, 0.16, 0.11)
const WOOD_DARK := Color(0.14, 0.10, 0.07)
const CLOTH_PAT := Color(0.27, 0.25, 0.18)

var _player: CharacterBody3D
var _pat: Node3D
var _medal: MeshInstance3D
var _door_leaf: MeshInstance3D
var _slits: Array[MeshInstance3D] = []
var _corner_spot: Interactable
var _phase := 0  # 0 ride, 1 reunion done / waiting the grade, 2 door open
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _rush_node: Node3D

func _ready() -> void:
	_rng.seed = 5
	_build_environment()
	_build_car()
	_build_people()
	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-0.6, 0.05, 2.6)
	_player.rotation.y = 0.0  # facing down the car, toward the quiet corner
	add_child(_player)
	_player.camera.make_current()
	_player.move_enabled = false
	AudioManager.play_ambient("train_boxcar")
	SceneDirector.fade_in(2.0)
	Hud.subtitle("", "(A boxcar built for eight horses, holding eleven wars. The light arrives sliced. Nobody asks anybody anything.)", 6.0)
	CaptureHarness.snap("ch5_boxcar")
	_ride_in()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.014, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.18, 0.21)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_car() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(CAR_W, 0.2, CAR_L), Vector3(0, -0.1, 0), WOOD_DARK)
	mb.box(Vector3(CAR_W, 0.2, CAR_L), Vector3(0, CAR_H + 0.1, 0), WOOD_DARK)
	# Straw drifts
	for i in 8:
		mb.box(Vector3(_rng.randf_range(0.5, 1.1), 0.05, _rng.randf_range(0.4, 0.9)),
			Vector3(_rng.randf_range(-1.2, 1.2), 0.03, _rng.randf_range(-3.6, 3.6)),
			Color(0.38, 0.31, 0.16), _rng.randf_range(0.0, TAU))
	# Slatted walls: boards with gaps; the gaps get emissive slit panes
	for side: float in [-1.0, 1.0]:
		var z := -CAR_L / 2.0
		while z < CAR_L / 2.0:
			var bw := _rng.randf_range(0.24, 0.34)
			# The doorway: a real gap in the west boards, covered by the leaf
			if not (side < 0.0 and z + bw > -0.5 and z < 1.7):
				mb.box(Vector3(0.1, CAR_H, bw), Vector3(side * CAR_W / 2.0, CAR_H / 2.0, z + bw / 2.0),
					WOOD.lightened(_rng.randf_range(-0.03, 0.03)))
			z += bw + 0.035
	# Header and sill boards over the doorway
	mb.box(Vector3(0.1, 0.35, 2.4), Vector3(-CAR_W / 2.0, CAR_H - 0.175, 0.6), WOOD)
	mb.box(Vector3(0.1, 0.25, 2.4), Vector3(-CAR_W / 2.0, 0.125, 0.6), WOOD)
	# End walls solid
	for ez: float in [-CAR_L / 2.0, CAR_L / 2.0]:
		mb.box(Vector3(CAR_W, CAR_H, 0.12), Vector3(0, CAR_H / 2.0, ez), WOOD)
	add_child(mb.commit_instance("Car"))

	# The slat gaps: pale emissive slivers, flickered by passing poles
	for side: float in [-1.0, 1.0]:
		var z := -CAR_L / 2.0 + 0.28
		while z < CAR_L / 2.0 - 0.2:
			var slit := MeshInstance3D.new()
			var sb := BoxMesh.new()
			sb.size = Vector3(0.02, CAR_H - 0.5, 0.035)
			slit.mesh = sb
			var smat := StandardMaterial3D.new()
			smat.albedo_color = Color(0.55, 0.58, 0.66)
			smat.emission_enabled = true
			smat.emission = Color(0.55, 0.58, 0.66)
			smat.emission_energy_multiplier = 0.9
			slit.material_override = smat
			if not (side < 0.0 and z > -0.5 and z < 1.7):
				slit.position = Vector3(side * (CAR_W / 2.0 - 0.04), CAR_H / 2.0, z)
				add_child(slit)
				_slits.append(slit)
			z += _rng.randf_range(0.27, 0.38)

	# The sliding door leaf on the west side (closed; opens on the grade)
	_door_leaf = MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(0.14, 2.1, 2.2)
	_door_leaf.mesh = db
	var dmat := StandardMaterial3D.new()
	dmat.vertex_color_use_as_albedo = false
	dmat.albedo_color = WOOD_DARK.lightened(0.05)
	_door_leaf.material_override = dmat
	_door_leaf.position = Vector3(-CAR_W / 2.0 + 0.02, 1.05, 0.6)
	add_child(_door_leaf)

	# Interior collision
	var body := StaticBody3D.new()
	for spec: Array in [
		[Vector3(CAR_W, 0.2, CAR_L), Vector3(0, -0.1, 0)],
		[Vector3(0.3, CAR_H, CAR_L), Vector3(-CAR_W / 2.0, CAR_H / 2.0, 0)],
		[Vector3(0.3, CAR_H, CAR_L), Vector3(CAR_W / 2.0, CAR_H / 2.0, 0)],
		[Vector3(CAR_W, CAR_H, 0.3), Vector3(0, CAR_H / 2.0, -CAR_L / 2.0)],
		[Vector3(CAR_W, CAR_H, 0.3), Vector3(0, CAR_H / 2.0, CAR_L / 2.0)],
	]:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = spec[0]
		cs.shape = shape
		cs.position = spec[1]
		body.add_child(cs)
	add_child(body)

	# One weak lantern hook glow at the ceiling centre (long dead), and a
	# cold fill so faces read
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 1.9, 0)
	fill.light_color = Color(0.5, 0.53, 0.62)
	fill.light_energy = 1.6
	fill.omni_range = 8.0
	add_child(fill)

func _build_people() -> void:
	# Other wars: three silhouettes with their backs to the walls
	for spec: Array in [[Vector3(1.2, 0, -1.2), -1.9, Color(0.24, 0.22, 0.19)],
			[Vector3(1.1, 0, 1.8), -2.3, Color(0.20, 0.21, 0.24)],
			[Vector3(-1.0, 0, -0.4), 1.4, Color(0.25, 0.20, 0.16)]]:
		var fig := Figures.villager(spec[2], "Prisoner")
		fig.position = spec[0]
		fig.rotation.y = spec[1]
		add_child(fig)
	# Pat, in the quiet far corner — and the saint, catching the slat-light
	_pat = Figures.villager(CLOTH_PAT, "Pat")
	_pat.position = Vector3(0.9, 0, -3.4)
	_pat.rotation.y = 0.4
	add_child(_pat)
	_medal = MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.045, 0.055, 0.012)
	_medal.mesh = mm
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(0.85, 0.80, 0.55)
	mmat.emission_enabled = true
	mmat.emission = Color(0.85, 0.80, 0.55)
	mmat.emission_energy_multiplier = 1.3
	_medal.material_override = mmat
	_medal.position = _pat.position + Vector3(-0.15, 1.05, 0.18)
	add_child(_medal)

func _ride_in() -> void:
	await get_tree().create_timer(6.0, false).timeout
	_player.move_enabled = true
	_corner_spot = Interactable.new()
	_corner_spot.name = "QuietCorner"
	_corner_spot.prompt = "The quiet corner"
	_corner_spot.one_shot = true
	_corner_spot.position = Vector3(0.55, 0, -2.6)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.9, 1.2)
	cs.shape = shape
	cs.position = Vector3(0, 0.95, 0)
	_corner_spot.add_child(cs)
	_corner_spot.interacted.connect(_on_corner)
	add_child(_corner_spot)
	Hud.subtitle("", "(Eleven wars, and one corner quieter than arithmetic allows.)", 4.5)

func _on_corner(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	var to_pat: Vector3 = _pat.position - player.position
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(y: float) -> void:
		player.rotation = Vector3(0, y, 0),
		player.rotation.y, atan2(-to_pat.x, -to_pat.z), 0.8)
	await tw.finished
	player.look_enabled = true
	CaptureHarness.snap("ch5_pat")
	DialogueManager.start("res://data/dialogue/ch5/pat_reunion.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	GameState.set_flag("pat_alive", true)
	GameState.set_flag("with_pat", true)
	_phase = 1
	player.move_enabled = true
	Hud.subtitle("", "(Now the whole car is listening for one thing: the engine's breathing. Waiting for the hill to slow her down.)", 5.5)
	await get_tree().create_timer(8.0, false).timeout
	_the_grade()

## The grade: she slows, the bolt comes out, the night opens sideways.
func _the_grade() -> void:
	_phase = 2
	_player.move_enabled = false
	_player.look_enabled = false
	Hud.subtitle("PAT", "Feel that? She's leaning. That's the grade, Tex — that's the whole door. Count me down.", 5.0)
	await get_tree().create_timer(5.0, false).timeout
	# Pat moves to the door; the bolt; the leaf slides
	var pm := create_tween()
	pm.tween_property(_pat, "position", Vector3(-1.0, 0, 1.3), 2.0)
	await pm.finished
	AudioManager.play_sfx("cell_door", -14.0)
	var slide := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	slide.tween_property(_door_leaf, "position:z", 2.75, 1.8)
	# Face the opening; the night scrolls past it
	var face := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	face.parallel().tween_property(_player, "position", Vector3(-0.9, 0.05, 0.4), 1.6)
	face.parallel().tween_method(func(y: float) -> void:
		_player.rotation = Vector3(0, y, 0), _player.rotation.y, PI / 2.0, 1.6)  # +PI/2 faces -X: the door side
	await face.finished
	# The rushing dark: a ground band sliding past the doorway
	var rush := MeshBuilder.new()
	rush.box(Vector3(30, 0.2, 90), Vector3(-16, -1.5, 0), Color(0.06, 0.07, 0.06))
	# Pale streaks — ballast, sleepers, the odd chalk stone — to carry motion
	for i in 40:
		rush.box(Vector3(_rng.randf_range(0.5, 2.4), 0.05, _rng.randf_range(0.15, 0.4)),
			Vector3(_rng.randf_range(-28, -3), -1.38, _rng.randf_range(-44, 44)),
			Color(0.16, 0.17, 0.16).lightened(_rng.randf_range(0.0, 0.15)))
	_rush_node = rush.commit_instance("Rush")
	add_child(_rush_node)
	AudioManager.play_ambient("wind_descent")
	CaptureHarness.snap("ch5_door")
	Hud.subtitle("", "(France goes by at a run — down there, dark and stony and moving, the only free ground in a thousand miles.)", 5.5)
	await get_tree().create_timer(5.5, false).timeout
	Hud.subtitle("PAT", "She's walking now, Tex! It's this or Germany — GO, I'm right behind you, the saint and me, GO!", 4.5)
	await get_tree().create_timer(4.0, false).timeout
	Hud.damage_flash(0.6)
	await SceneDirector.fade_out(1.2)
	AudioManager.play_sfx("impact_thud", -6.0)
	AudioManager.stop_ambient(0.3)
	await get_tree().create_timer(1.2, false).timeout
	AudioManager.play_sfx("chapter_sting", -6.0)
	await CutscenePlayer.caption("Gravel, then grass, then a long time of sky.", 4.5)
	await CutscenePlayer.caption("Two men lie in a French ditch, laughing wrong,\ncounting each other's arms and legs like riches.", 5.5)
	await CutscenePlayer.caption("The train grinds east without them.\nSomewhere aboard, a bolt-hole full of night tells Voss everything.", 5.5)
	await CutscenePlayer.caption("END OF CHAPTER FIVE", 4.0)
	GameState.set_flag("escaped_train", true)
	GameState.set_flag("ch5_complete", true)
	GameState.chapter = 6
	GameState.save_game()
	await CutscenePlayer.caption("CHAPTER SIX\n\nTHE WHITE TEETH OF THE SKY", 4.5)
	SceneDirector.goto_beat("ch6_foothills", 0.1)

func _process(delta: float) -> void:
	_t += delta
	# The car rocks; the slats strobe as poles and trees interrupt the light.
	rotation.z = sin(_t * 1.7) * 0.006
	position.y = sin(_t * 3.4) * 0.015
	if _rush_node:
		# France, passing: the ground band slides by the open door
		_rush_node.position.z = fmod(_t * 14.0, 45.0) - 22.5
	for i in _slits.size():
		var mat: StandardMaterial3D = _slits[i].material_override
		var strobe := 0.9 + 0.5 * sin(_t * 9.0 + i * 2.7)
		if fmod(_t * 2.0 + i * 0.37, 4.0) < 0.12:
			strobe = 0.15  # a pole snaps past
		mat.emission_energy_multiplier = strobe
	_autoplay_step(delta)

func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	if _phase == 0 and _corner_spot and is_instance_valid(_corner_spot):
		var target := Vector3(_corner_spot.position.x, _player.position.y, _corner_spot.position.z)
		if _player.position.distance_to(target) > 1.3:
			_player.position = _player.position.move_toward(target, delta * 2.6)
		else:
			_corner_spot.interact(_player)
