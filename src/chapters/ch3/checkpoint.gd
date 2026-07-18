extends Node3D
## Chapter 3 — the station checkpoint at dusk. A queue shortening one coat
## at a time toward a lamp, a table, two Feldgendarmen — and a man in a long
## coat by the pillar who is not in the queue and never speaks. You are Jean
## Caillet, deaf and mute: the examination is behavioural, and the right
## moves are the ones where you do nothing at all. Suspicion ≥ 2 is arrest —
## the chapter's fail state. Passing walks you through the barrier past the
## coat, and a subordinate's voice gives the coat its name.

const PLAYER_SCENE := preload("res://src/player/player.tscn")

const COBBLE := Color(0.20, 0.20, 0.21)
const STONE := Color(0.30, 0.28, 0.26)
const CLOTH_SYLVIE := Color(0.30, 0.24, 0.22)
const FELDGRAU := Color(0.22, 0.24, 0.20)
const COAT := Color(0.10, 0.10, 0.12)
const SKIN := Color(0.48, 0.38, 0.30)

const TABLE_AT := Vector3(0.0, 0, -4.0)
const VOSS_AT := Vector3(-3.6, 0, -7.4)  # inside the table view's left edge
## Queue marks, back to front; the player starts at the last one.
const QUEUE: Array[Vector3] = [
	Vector3(0.4, 0, -1.8),
	Vector3(0.2, 0, 0.4),
	Vector3(0.5, 0, 2.6),
	Vector3(0.3, 0, 4.8),
	Vector3(0.5, 0, 7.0),
]

var _player: CharacterBody3D
var _sylvie: Node3D
var _civilians: Array[Node3D] = []
var _barrier_pole: MeshInstance3D
var _queue_slot := 0
var _turn_started := false
var _t := 0.0

func _ready() -> void:
	GameState.set_flag("suspicion", 0)
	GameState.set_flag("checkpoint_failed", false)

	_build_environment()
	_build_forecourt()
	_build_people()
	_spawn_player()
	AudioManager.play_ambient("station_dusk")
	SceneDirector.fade_in(2.0)
	Hud.subtitle("", "(The queue shortens one coat at a time. The man in the long coat is not in the queue. He reads faces the way other men do accounts.)", 6.5)
	CaptureHarness.snap("ch3_queue")
	_run_queue()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.045, 0.075)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.17, 0.23)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.09)
	env.fog_density = 0.0045
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

func _build_forecourt() -> void:
	var mb := MeshBuilder.new()
	mb.box(Vector3(44, 0.2, 34), Vector3(0, -0.1, 0), COBBLE)
	# Station facade across the north side, three arches into blackness
	mb.box(Vector3(34, 9.0, 0.8), Vector3(0, 4.5, -10.5), STONE)
	for x: float in [-9.0, 0.0, 9.0]:
		mb.box(Vector3(4.2, 5.2, 1.0), Vector3(x, 2.6, -10.4), Color(0.02, 0.02, 0.03))
	mb.box(Vector3(34, 1.2, 1.0), Vector3(0, 9.6, -10.5), STONE.darkened(0.15))
	# Flanking walls funneling the forecourt
	mb.box(Vector3(0.8, 5.0, 22), Vector3(-14, 2.5, 1.0), STONE.darkened(0.2))
	mb.box(Vector3(0.8, 5.0, 22), Vector3(14, 2.5, 1.0), STONE.darkened(0.2))
	# The clock: a pale disc on the facade
	var clock := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.9
	cm.bottom_radius = 0.9
	cm.height = 0.1
	clock.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.85, 0.83, 0.75)
	cmat.emission_enabled = true
	cmat.emission = Color(0.85, 0.83, 0.75)
	cmat.emission_energy_multiplier = 0.9
	clock.material_override = cmat
	clock.rotation_degrees = Vector3(90, 0, 0)
	clock.position = Vector3(0, 7.4, -10.0)
	add_child(clock)
	# The table, papers, and the barrier across the arches' approach
	mb.box(Vector3(1.6, 0.8, 0.7), TABLE_AT + Vector3(1.3, 0.4, 0), Color(0.26, 0.18, 0.11))
	mb.box(Vector3(0.4, 0.03, 0.3), TABLE_AT + Vector3(1.2, 0.82, 0), Color(0.70, 0.68, 0.60))
	for side: float in [-3.2, 3.2]:
		mb.box(Vector3(0.16, 1.15, 0.16), TABLE_AT + Vector3(side, 0.575, -1.2), STONE.darkened(0.3))
	add_child(mb.commit_instance("Forecourt"))

	# The player is a CharacterBody3D with gravity even while the queue owns
	# their feet: without a floor collider they fall through the cobbles.
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(44, 0.2, 34)
	cs.shape = shape
	cs.position = Vector3(0, -0.1, 0)
	body.add_child(cs)
	add_child(body)

	# Barrier pole: separate instance so passing can lift it
	_barrier_pole = MeshInstance3D.new()
	var bp := BoxMesh.new()
	bp.size = Vector3(6.4, 0.12, 0.12)
	_barrier_pole.mesh = bp
	var pmat := StandardMaterial3D.new()
	pmat.vertex_color_use_as_albedo = false
	pmat.albedo_color = Color(0.72, 0.68, 0.62)
	_barrier_pole.material_override = pmat
	_barrier_pole.position = TABLE_AT + Vector3(0, 1.1, -1.2)
	add_child(_barrier_pole)

	# Lamp pools: over the table, over Voss's pillar, one far one
	for spec: Array in [[TABLE_AT + Vector3(0.8, 0, 0.6), 3.2], [VOSS_AT + Vector3(0.6, 0, 0.6), 2.0],
			[Vector3(9.0, 0, 3.0), 1.5]]:
		var pole := MeshBuilder.new()
		var at: Vector3 = spec[0]
		pole.box(Vector3(0.14, 4.4, 0.14), at + Vector3(0, 2.2, 0), Color(0.10, 0.10, 0.11))
		pole.box(Vector3(0.5, 0.25, 0.5), at + Vector3(0, 4.45, 0), Color(0.12, 0.12, 0.13))
		add_child(pole.commit_instance("LampPole"))
		var glow := MeshInstance3D.new()
		var gb := BoxMesh.new()
		gb.size = Vector3(0.34, 0.16, 0.34)
		glow.mesh = gb
		var gmat := StandardMaterial3D.new()
		gmat.albedo_color = Color(1.0, 0.82, 0.52)
		gmat.emission_enabled = true
		gmat.emission = Color(1.0, 0.82, 0.52)
		gmat.emission_energy_multiplier = 2.2
		glow.material_override = gmat
		glow.position = at + Vector3(0, 4.32, 0)
		add_child(glow)
		var lamp := OmniLight3D.new()
		lamp.position = at + Vector3(0, 3.9, 0)
		lamp.light_color = Color(1.0, 0.76, 0.46)
		lamp.light_energy = spec[1]
		lamp.omni_range = 9.0
		lamp.shadow_enabled = true
		add_child(lamp)

	# Voss's pillar
	var pillar := MeshBuilder.new()
	pillar.box(Vector3(0.9, 5.0, 0.9), VOSS_AT + Vector3(-0.9, 2.5, 0), STONE.darkened(0.25))
	add_child(pillar.commit_instance("Pillar"))

	_build_dressing()

## Sandbags at the table, rope posts along the queue, notices on the walls.
func _build_dressing() -> void:
	var mb := MeshBuilder.new()
	var bag := Color(0.33, 0.30, 0.22)
	var rng := RandomNumberGenerator.new()
	rng.seed = 43
	# Sandbag revetment flanking the table
	for row in 3:
		for i in 4 - row:
			for side: float in [-1.0, 1.0]:
				mb.box(Vector3(0.62, 0.26, 0.34),
					TABLE_AT + Vector3(side * 2.6 + (i - 1.5 + row * 0.5) * 0.64,
						0.13 + row * 0.26, 0.55 + rng.randf_range(-0.04, 0.04)),
					bag.lightened(rng.randf_range(-0.05, 0.08)), rng.randf_range(-0.08, 0.08))
	# Rope posts guiding the queue
	for z: float in [-1.0, 1.4, 3.8, 6.2]:
		for side: float in [-1.3, 1.9]:
			mb.box(Vector3(0.09, 1.0, 0.09), Vector3(side, 0.5, z), Color(0.13, 0.12, 0.11))
			mb.box(Vector3(0.05, 0.05, 2.4), Vector3(side, 0.88, z + 1.2), Color(0.30, 0.26, 0.20))
	# Bekanntmachung notices: pale sheets with a dark header band
	for spec: Array in [[Vector3(-6.5, 2.0, -10.05), 0.0], [Vector3(5.8, 1.8, -10.05), 0.0],
			[Vector3(-13.55, 1.9, -3.0), PI / 2], [Vector3(13.55, 2.1, 4.0), -PI / 2]]:
		var yaw: float = spec[1]
		var b := Basis(Vector3.UP, yaw)
		mb.box(Vector3(0.9, 1.25, 0.04), spec[0], Color(0.72, 0.70, 0.62), yaw)
		mb.box(Vector3(0.9, 0.28, 0.05), spec[0] + b * Vector3(0, 0.44, -0.005), Color(0.12, 0.10, 0.10), yaw)
	add_child(mb.commit_instance("Dressing"))

func _standing(at: Vector3, yaw: float, cloth: Color, hat := false) -> Node3D:
	var node := Figures.standing(cloth, hat)
	node.position = at
	node.rotation.y = yaw
	add_child(node)
	return node

func _build_people() -> void:
	# Two Feldgendarmen: one seated-ish at the table (standing behind it), one at the barrier
	_standing(TABLE_AT + Vector3(1.3, 0, -0.9), 0.0, FELDGRAU)
	_standing(TABLE_AT + Vector3(-1.6, 0, -0.6), 0.35, FELDGRAU)
	# The coat. He faces the queue. He has nothing to do and does it perfectly.
	_standing(VOSS_AT, 0.55, COAT, true)
	# The queue ahead of you: three civilians, then Sylvie
	for i in 3:
		var c := _standing(QUEUE[i], PI + randf_range(-0.15, 0.15),
			Color(0.26 + 0.04 * i, 0.23, 0.20 + 0.03 * i))
		_civilians.append(c)
	_sylvie = _standing(QUEUE[3], PI, CLOTH_SYLVIE)

func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	_player.position = QUEUE[4] + Vector3(0, 0.05, 0)
	_player.rotation.y = 0.0  # facing -Z: the table, the lamp, the coat
	_player.move_enabled = false  # the queue owns your feet; your eyes are yours
	add_child(_player)
	_player.camera.make_current()

## The queue advances one coat at a time; each head of the line is processed
## under the lamp and released through the barrier.
func _run_queue() -> void:
	await get_tree().create_timer(4.0, false).timeout
	for round_i in 3:
		# Head of queue walks to the table, pauses, passes through
		var head: Node3D = _civilians[round_i]
		await _process_figure(head, 4.5 + round_i * 0.8)
		_advance_queue(round_i + 1)
		await get_tree().create_timer(2.0, false).timeout
	# Sylvie's turn: brisk, practiced
	Hud.subtitle("", "(Her papers cross the table like they are bored of the trip. Stamp, stamp. She does not look back.)", 5.5)
	await _process_figure(_sylvie, 4.0)
	_advance_queue(4)
	await get_tree().create_timer(2.5, false).timeout
	# Your turn.
	_your_turn()

func _process_figure(figure: Node3D, seconds: float) -> void:
	var tw := create_tween()
	tw.tween_property(figure, "position", Vector3(TABLE_AT.x, figure.position.y, TABLE_AT.z + 0.9), 2.2)
	await tw.finished
	await get_tree().create_timer(seconds, false).timeout
	AudioManager.play_sfx("stamp_thunk", -10.0)
	var through := create_tween()
	through.tween_property(figure, "position",
		Vector3(TABLE_AT.x - 1.0, figure.position.y, TABLE_AT.z - 5.5), 3.0)
	through.tween_callback(figure.hide)

## After `processed` people have been released, every remaining queue member
## (and the player at the tail) settles onto their new mark.
func _advance_queue(processed: int) -> void:
	for i in range(processed, 4):
		var mover: Node3D = _civilians[i] if i < 3 else _sylvie
		var target := QUEUE[i - processed]
		var tw := create_tween()
		tw.tween_property(mover, "position",
			Vector3(target.x, mover.position.y, target.z), 2.4)
	_queue_slot = processed
	var pt := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pt.tween_property(_player, "position",
		Vector3(QUEUE[4 - processed].x, 0.05, QUEUE[4 - processed].z), 2.6)

func _your_turn() -> void:
	if _turn_started:
		return
	_turn_started = true
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_player, "position", Vector3(TABLE_AT.x, 0.05, TABLE_AT.z + 1.1), 2.4)
	await tw.finished
	CaptureHarness.snap("ch3_voss")
	DialogueManager.start("res://data/dialogue/ch3/checkpoint.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	if GameState.get_flag("checkpoint_failed"):
		await _arrest()
	else:
		await _through()

func _arrest() -> void:
	Hud.subtitle("", "(Hands. Many. The coat finally looks at you — and looks away first, bored. That is the worst part.)", 5.5)
	await get_tree().create_timer(4.5, false).timeout
	AudioManager.stop_ambient(1.0)
	await SceneDirector.fade_out(2.0)
	GameState.set_flag("ch3_failed_once", true)
	await SceneDirector.game_over("Jean Caillet could hear after all.", "ch3_checkpoint")

func _through() -> void:
	AudioManager.play_sfx("stamp_thunk", -6.0)
	# The barrier lifts its arm
	var lift := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	lift.tween_property(_barrier_pole, "rotation:z", 1.25, 1.6)
	lift.parallel().tween_property(_barrier_pole, "position",
		TABLE_AT + Vector3(-2.6, 1.4, -1.2), 1.6)
	await lift.finished
	# NOTE: never `await tween.finished` after other awaits — a finished
	# tween is freed and the await hangs forever. Time the walk with timers.
	var walk := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	walk.tween_property(_player, "position", Vector3(-0.6, 0.05, TABLE_AT.z - 4.5), 8.0)
	await get_tree().create_timer(2.2, false).timeout
	Hud.subtitle("SOLDAT", "Herr Kriminalkommissar Voss — der Wagen ist da.", 4.5)
	await get_tree().create_timer(4.0, false).timeout
	GameState.set_flag("saw_voss", true)
	Hud.subtitle("", "(The name follows you through the barrier like a hand laid on the back of your neck.)", 5.0)
	await get_tree().create_timer(1.8, false).timeout
	CaptureHarness.snap("ch3_stamped")
	await get_tree().create_timer(4.0, false).timeout
	AudioManager.stop_ambient(2.5)
	await SceneDirector.fade_out(2.5)
	AudioManager.play_sfx("chapter_sting", -6.0)
	await CutscenePlayer.caption("The city swallows Jean Caillet whole.", 4.5)
	await CutscenePlayer.caption("Behind him, a man in a long coat gets into a car\nand opens a folder with one photograph in it.", 5.5)
	await CutscenePlayer.caption("END OF CHAPTER THREE", 4.0)
	GameState.chapter = 4
	GameState.set_flag("ch3_complete")
	GameState.save_game()
	get_tree().change_scene_to_file("res://src/ui/title.tscn")

func _process(delta: float) -> void:
	_t += delta
