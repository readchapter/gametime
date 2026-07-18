extends Node3D
## Chapter 3 — the road west, at dawn. Out of the barn with Marcel, south
## along the road's east side — until a Feldgendarmerie checkpoint on the
## road forces you both flat and then wide, across the fields, to a
## crossroads calvary where the next link of the line is waiting: Sylvie,
## a courier who moves in plain sight. Daylight makes the same country
## worse: there is nowhere to be a shadow at seven in the morning.

const FIELD_SCENE := preload("res://src/chapters/ch1/field.tscn")
const PLAYER_SCENE := preload("res://src/player/player.tscn")

const CLOTH_MARCEL := Color(0.16, 0.17, 0.19)
const CLOTH_SYLVIE := Color(0.30, 0.24, 0.22)
const SKIN := Color(0.48, 0.38, 0.30)
const CALVARY_AT := Vector3(-55, 0, 85)
const CHECKPOINT_AT := Vector3(80, 0, 72)

## Route: south beside the road → the sighting → back and across north of
## the post → west across the crop fields → the calvary.
const WAYPOINTS: Array[Vector3] = [
	Vector3(88, 0, 24),
	Vector3(86, 0, 46),    # index 1: reaching it fires the sighting beat
	Vector3(74, 0, 36),    # back from the road, crossing north of the post
	Vector3(52, 0, 44),
	Vector3(20, 0, 56),
	Vector3(-18, 0, 68),
	Vector3(-48, 0, 82),
]

var _field: Node3D
var _player: CharacterBody3D
var _marcel: Node3D
var _sylvie: Node3D
var _wp := 0
var _sighting_done := false
var _lock := false
var _handoff_started := false
var _waited_line := false
var _t := 0.0

func _ready() -> void:
	_field = FIELD_SCENE.instantiate()
	add_child(_field)
	_dawn()
	var terrain: MeshInstance3D = _field.get_node("Terrain")
	terrain.create_trimesh_collision()

	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(92, _h(92, 14) + 0.3, 14)
	_player.rotation.y = PI  # facing south, down the road's edge
	add_child(_player)
	_player.camera.make_current()

	_marcel = _figure(Vector3(89, 0, 19), CLOTH_MARCEL, "Marcel")
	_sylvie = _figure(CALVARY_AT + Vector3(1.2, 0, -0.6), CLOTH_SYLVIE, "Sylvie")
	_build_checkpoint()
	_build_calvary()
	AudioManager.play_ambient("morning_farm")
	SceneDirector.fade_in(1.8)
	Hud.subtitle("MARCEL", "Walk like a man late for work. Not like a man early for a boat.", 5.0)
	CaptureHarness.snap("ch3_road")

func _h(x: float, z: float) -> float:
	return float(_field.height_at(x, z))

## Cold early morning: low sun out of the east, pale sky, thin ground haze.
func _dawn() -> void:
	var we: WorldEnvironment = _field.get_node("WorldEnvironment")
	we.environment.ambient_light_color = Color(0.38, 0.40, 0.46)
	we.environment.ambient_light_energy = 1.0
	we.environment.fog_density = 0.0045
	we.environment.fog_light_color = Color(0.52, 0.54, 0.58)
	var sun: DirectionalLight3D = _field.get_node("Sun")
	sun.rotation_degrees = Vector3(-11, 92, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.88, 0.70)
	var sky_mat: ShaderMaterial = we.environment.sky.sky_material
	sky_mat.set_shader_parameter("top_color", Color(0.34, 0.42, 0.55))
	sky_mat.set_shader_parameter("horizon_color", Color(0.78, 0.70, 0.58))
	sky_mat.set_shader_parameter("ground_color", Color(0.16, 0.16, 0.13))
	sky_mat.set_shader_parameter("sun_color", Color(1.0, 0.85, 0.6))
	sky_mat.set_shader_parameter("cloud_coverage", 0.30)
	sky_mat.set_shader_parameter("cloud_lit_color", Color(0.95, 0.80, 0.62))
	sky_mat.set_shader_parameter("cloud_shadow_color", Color(0.40, 0.42, 0.50))

func _figure(at: Vector3, cloth: Color, fig_name: String) -> Node3D:
	var node := Figures.villager(cloth, fig_name)
	node.position = Vector3(at.x, _h(at.x, at.z), at.z)
	add_child(node)
	return node

## The post on the road: striped barrier, a squat vehicle, three figures.
## Never approached — it exists to be seen and gone around.
func _build_checkpoint() -> void:
	var at := Vector3(CHECKPOINT_AT.x, _h(CHECKPOINT_AT.x, CHECKPOINT_AT.z), CHECKPOINT_AT.z)
	var mb := MeshBuilder.new()
	var grey := Color(0.30, 0.31, 0.28)
	for side: float in [-3.4, 3.4]:
		mb.box(Vector3(0.18, 1.1, 0.18), at + Vector3(side, 0.55, 0), grey.darkened(0.2))
	# Striped pole
	for i in 8:
		mb.box(Vector3(0.85, 0.1, 0.1), at + Vector3(-3.0 + i * 0.85, 1.05, 0),
			Color(0.75, 0.72, 0.68) if i % 2 == 0 else Color(0.55, 0.12, 0.10))
	# Vehicle parked off the verge
	mb.box(Vector3(2.0, 1.0, 4.2), at + Vector3(5.2, 0.9, -2.5), Color(0.16, 0.18, 0.15))
	mb.box(Vector3(1.8, 0.7, 1.4), at + Vector3(5.2, 1.75, -3.4), Color(0.14, 0.16, 0.13))
	# Sentries
	for spec: Array in [[Vector3(-1.2, 0, 1.0), 0.4], [Vector3(1.4, 0, -0.8), -2.6],
			[Vector3(4.0, 0, 0.6), 1.8]]:
		var g := Color(0.20, 0.22, 0.18)
		mb.box(Vector3(0.38, 0.6, 0.24), at + spec[0] + Vector3(0, 1.08, 0), g, spec[1])
		mb.box(Vector3(0.24, 0.78, 0.2), at + spec[0] + Vector3(0, 0.39, 0), g.darkened(0.2), spec[1])
		mb.sphere(0.11, 0.22, at + spec[0] + Vector3(0, 1.52, 0), SKIN.darkened(0.1))
	add_child(mb.commit_instance("CheckpointPost"))

## A roadside calvary at the crossroads — the handoff mark.
func _build_calvary() -> void:
	var at := Vector3(CALVARY_AT.x, _h(CALVARY_AT.x, CALVARY_AT.z), CALVARY_AT.z)
	var mb := MeshBuilder.new()
	var stone := Color(0.42, 0.41, 0.38)
	mb.box(Vector3(1.2, 0.5, 1.2), at + Vector3(0, 0.25, 0), stone)
	mb.box(Vector3(0.7, 0.4, 0.7), at + Vector3(0, 0.7, 0), stone.darkened(0.1))
	mb.box(Vector3(0.16, 2.6, 0.16), at + Vector3(0, 2.2, 0), stone.darkened(0.2))
	mb.box(Vector3(1.0, 0.16, 0.16), at + Vector3(0, 2.9, 0), stone.darkened(0.2))
	add_child(mb.commit_instance("Calvary"))

func _process(delta: float) -> void:
	_t += delta
	if _marcel == null or _player == null:
		return
	_marcel_walk(delta)
	if not _handoff_started and _wp >= WAYPOINTS.size() \
			and _player.position.distance_to(_marcel.position) < 4.0:
		_handoff_started = true
		_handoff()
	_autoplay_step(delta)

func _marcel_walk(delta: float) -> void:
	if _lock or _wp >= WAYPOINTS.size():
		return
	var target := WAYPOINTS[_wp]
	target.y = _h(target.x, target.z)
	if _marcel.position.distance_to(_player.position) > 9.0:
		if not _waited_line:
			_waited_line = true
			Hud.subtitle("", "(He does not look back. He simply stops walking.)", 3.5)
		return
	_waited_line = false
	var flat := _marcel.position.move_toward(target, 3.1 * delta)
	flat.y = _h(flat.x, flat.z) + absf(sin(_t * 9.0)) * 0.04
	if Vector2(flat.x, flat.z).distance_to(Vector2(target.x, target.z)) < 0.6:
		_wp += 1
		if _wp == 2 and not _sighting_done:
			_sighting()
	else:
		var look := target - _marcel.position
		if look.length() > 0.5:
			_marcel.rotation.y = atan2(-look.x, -look.z) + PI
	_marcel.position = flat

## The checkpoint, seen: flat in the verge while Marcel reads the road.
func _sighting() -> void:
	_sighting_done = true
	_lock = true
	Hud.subtitle("MARCEL", "Stop. Down — slowly, no drop.", 3.5)
	_player.move_enabled = false
	_player.look_enabled = false
	var cam: Camera3D = _player.camera
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "position:y", 0.5, 0.9)
	# Turned toward the post down the road so the read is unmissable.
	tw.parallel().tween_property(_player, "rotation:y", PI + 0.35, 0.9)
	tw.parallel().tween_property(_marcel, "scale:y", 0.55, 0.7)
	await tw.finished
	CaptureHarness.snap("ch3_post")
	await get_tree().create_timer(3.0, false).timeout
	Hud.subtitle("MARCEL", "Feldgendarmerie. A post since yesterday — that is new, and new is about you.", 5.0)
	await get_tree().create_timer(5.0, false).timeout
	Hud.subtitle("MARCEL", "A man came from Paris to ask about one airman from that bomber. One. Not the crew — one man.", 5.5)
	await get_tree().create_timer(5.5, false).timeout
	Hud.subtitle("", "(He looks at you a moment longer than he needs to.)", 4.0)
	await get_tree().create_timer(4.0, false).timeout
	Hud.subtitle("MARCEL", "We go around. North of the post, through the beets, and you keep my pace.", 4.5)
	var up := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	up.tween_property(cam, "position:y", 1.65, 0.7)
	up.parallel().tween_property(_marcel, "scale:y", 1.0, 0.6)
	await up.finished
	_player.move_enabled = true
	_player.look_enabled = true
	_lock = false

func _handoff() -> void:
	_player.move_enabled = false
	_player.look_enabled = false
	# Face the calvary — Sylvie beside it, Marcel between.
	var to_cross := CALVARY_AT - _player.position
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_player, "rotation:y", atan2(-to_cross.x, -to_cross.z), 1.0)
	await tw.finished
	_player.look_enabled = true
	CaptureHarness.snap("ch3_calvary")
	DialogueManager.start("res://data/dialogue/ch3/road_handoff.json")
	if "--autoplay" in OS.get_cmdline_user_args():
		DialogueManager.autoplay()
	await DialogueManager.dialogue_ended
	Hud.subtitle("", "(She is already walking. Marcel is already gone.)", 3.5)
	await get_tree().create_timer(3.0, false).timeout
	AudioManager.stop_ambient(1.5)
	GameState.set_flag("ch3_road_done")
	SceneDirector.goto_beat("ch3_safehouse", 1.5)

## Headless drive: chase Marcel until the route ends at the calvary.
func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	var target := _marcel.position
	if _wp < WAYPOINTS.size() and _player.position.distance_to(target) < 2.5:
		return
	target.y = _player.position.y
	_player.position = _player.position.move_toward(target, delta * 3.6)
	_player.position.y = _h(_player.position.x, _player.position.z) + 0.3
