extends Node3D
## Chapter 2 — the walk to the barn. The same countryside Travis fell into,
## now crossed on foot in the dark behind Marcel: hedgerows, open ground,
## and the road — where a German truck forces both of them flat into the
## grass as its headlights sweep past. Ends at a barn on the village edge.

const FIELD_SCENE := preload("res://src/chapters/ch1/field.tscn")
const PLAYER_SCENE := preload("res://src/player/player.tscn")

const CLOTH_MARCEL := Color(0.16, 0.17, 0.19)
const BARN_AT := Vector3(95, 0, 8)

## Marcel's route: farmhouse door → the diagonal hedgerow → along the south
## hedgerow line → the ditch short of the road → across → the barn.
const WAYPOINTS: Array[Vector3] = [
	Vector3(-30, 0, 18),
	Vector3(-14, 0, -20),
	Vector3(20, 0, -34),
	Vector3(52, 0, -30),
	Vector3(70, 0, -24),   # ditch: the truck beat fires here
	Vector3(86, 0, -14),
	Vector3(93, 0, 2),
]

var _field: Node3D
var _player: CharacterBody3D
var _marcel: Node3D
var _wp := 0
var _truck_done := false
var _truck_lock := false
var _waited_line := false
var _door: Interactable
var _t := 0.0

func _ready() -> void:
	_field = FIELD_SCENE.instantiate()
	add_child(_field)
	_night()
	# The field was only ever seen from the air / lying down; walking it
	# needs real ground collision.
	var terrain: MeshInstance3D = _field.get_node("Terrain")
	terrain.create_trimesh_collision()

	_player = PLAYER_SCENE.instantiate()
	_player.position = Vector3(-36, _h(-36, 24) + 0.3, 24)
	_player.rotation.y = -PI / 2 + 0.5  # facing Marcel / the first hedgerow
	add_child(_player)
	# field.tscn ships a current=true CaptureCam; the player must win.
	_player.camera.make_current()

	_marcel = _figure(Vector3(-33, 0, 20))
	_build_barn()
	AudioManager.play_ambient("wind_descent")
	SceneDirector.fade_in(1.8)
	Hud.subtitle("MARCEL", "Stay in my shadow. If I drop, you drop.", 4.5)
	CaptureHarness.snap("ch2_walk")

func _h(x: float, z: float) -> float:
	return float(_field.height_at(x, z))

func _night() -> void:
	var we: WorldEnvironment = _field.get_node("WorldEnvironment")
	we.environment.ambient_light_color = Color(0.10, 0.11, 0.17)
	we.environment.ambient_light_energy = 0.85
	we.environment.fog_density = 0.004
	we.environment.fog_light_color = Color(0.05, 0.06, 0.10)
	var sun: DirectionalLight3D = _field.get_node("Sun")
	sun.light_energy = 0.14
	sun.light_color = Color(0.5, 0.6, 0.8)
	sun.rotation_degrees = Vector3(-35, 40, 0)
	var sky_mat: ShaderMaterial = we.environment.sky.sky_material
	sky_mat.set_shader_parameter("top_color", Color(0.03, 0.04, 0.08))
	sky_mat.set_shader_parameter("horizon_color", Color(0.10, 0.10, 0.14))
	sky_mat.set_shader_parameter("sun_color", Color(0.0, 0.0, 0.0))
	sky_mat.set_shader_parameter("cloud_coverage", 0.15)
	sky_mat.set_shader_parameter("star_amount", 0.8)
	# A low moon ahead of the route (the walk heads east).
	sky_mat.set_shader_parameter("moon_amount", 1.0)
	sky_mat.set_shader_parameter("moon_dir", Vector3(0.65, 0.42, 0.18))
	# Kit trees carry a bright color atlas that glows against the night —
	# crush just the hedgerow trees down to true silhouettes.
	for child in _field.get_children():
		if child.name.begins_with("Hedgerow"):
			Kit.tint_node(child, Color(0.16, 0.18, 0.20))

func _figure(at: Vector3) -> Node3D:
	var node := Figures.villager(CLOTH_MARCEL, "Marcel")
	node.position = Vector3(at.x, _h(at.x, at.z), at.z)
	add_child(node)
	return node

func _build_barn() -> void:
	var mb := MeshBuilder.new()
	var at := Vector3(BARN_AT.x, _h(BARN_AT.x, BARN_AT.z), BARN_AT.z)
	var wood := Color(0.20, 0.15, 0.10)
	mb.box(Vector3(9.0, 4.2, 7.0), at + Vector3(0, 2.1, 0), wood, 0.15)
	mb.prism(Vector3(9.6, 2.2, 7.6), at + Vector3(0, 5.3, 0), Color(0.14, 0.10, 0.08), 0.15)
	# Door on the west face, a lantern's dim spill beside it
	mb.box(Vector3(0.15, 2.6, 1.8), at + Vector3(-4.5, 1.3, 0.6), wood.darkened(0.4), 0.15)
	add_child(mb.commit_instance("Barn"))
	var lamp := OmniLight3D.new()
	lamp.position = at + Vector3(-4.9, 2.2, 0)
	lamp.light_color = Color(1.0, 0.7, 0.4)
	lamp.light_energy = 0.7
	lamp.omni_range = 4.0
	add_child(lamp)

	_door = Interactable.new()
	_door.name = "BarnDoor"
	_door.prompt = "Go in"
	_door.one_shot = true
	_door.position = at + Vector3(-4.6, 0, 0.6)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 2.4, 2.2)
	cs.shape = shape
	cs.position = Vector3(0, 1.2, 0)
	_door.add_child(cs)
	_door.interacted.connect(_on_door)
	add_child(_door)

func _process(delta: float) -> void:
	_t += delta
	if _marcel == null or _player == null:
		return
	_marcel_walk(delta)
	if not _truck_done and not _truck_lock and _wp >= 5:
		_truck_beat()
	_autoplay_step(delta)

## Marcel leads: he advances while the player keeps up, waits when they lag.
func _marcel_walk(delta: float) -> void:
	if _truck_lock or _wp >= WAYPOINTS.size():
		return
	var target := WAYPOINTS[_wp]
	target.y = _h(target.x, target.z)
	var to_player := _marcel.position.distance_to(_player.position)
	if to_player > 9.0:
		if not _waited_line:
			_waited_line = true
			Hud.subtitle("", "(He has stopped. He is waiting, not patiently.)", 3.5)
		return
	_waited_line = false
	var step := 3.1 * delta
	var flat := _marcel.position.move_toward(target, step)
	flat.y = _h(flat.x, flat.z) + absf(sin(_t * 9.0)) * 0.04
	if Vector2(flat.x, flat.z).distance_to(Vector2(target.x, target.z)) < 0.6:
		_wp += 1
		if _wp == 3:
			Hud.subtitle("MARCEL", "The road ahead. We cross where it bends.", 4.0)
	else:
		var look := target - _marcel.position
		if look.length() > 0.5:
			_marcel.rotation.y = atan2(-look.x, -look.z) + PI
	_marcel.position = flat

## The truck: both of you flat in the grass while the headlights walk the
## hedgerow over your heads.
func _truck_beat() -> void:
	_truck_lock = true
	Hud.subtitle("MARCEL", "Down. Into the grass. NOW.", 3.0)
	_player.move_enabled = false
	_player.look_enabled = false
	var cam: Camera3D = _player.camera
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "position:y", 0.45, 0.7)
	# Shoved down facing the road: you watch the lights come through the grass.
	tw.parallel().tween_property(_player, "rotation:y", -PI / 2, 0.7)
	tw.parallel().tween_property(cam, "rotation:x", 0.12, 0.7)
	# Marcel goes down with you — a shape in the grass, nothing more.
	tw.parallel().tween_property(_marcel, "scale:y", 0.3, 0.5)
	AudioManager.play_sfx("truck_pass")

	var truck := _build_truck()
	truck.position = Vector3(80, 0, -120)
	truck.position.y = _h(80, -120) + 0.1
	add_child(truck)
	var run := create_tween()
	run.tween_method(func(z: float) -> void:
		truck.position = Vector3(80, _h(80, z) + 0.1, z), -120.0, 130.0, 11.0)
	await get_tree().create_timer(3.8, false).timeout
	CaptureHarness.snap("ch2_truck")
	await run.finished
	truck.queue_free()
	var rise := create_tween()
	rise.tween_property(_marcel, "scale:y", 1.0, 0.6)
	Hud.subtitle("MARCEL", "Allez. Cross now — walk, do not run.", 4.0)
	var up := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	up.tween_property(cam, "position:y", 1.65, 0.7)
	up.parallel().tween_property(cam, "rotation:x", 0.0, 0.7)
	_player.look_enabled = true
	_player.move_enabled = true
	_truck_done = true
	_truck_lock = false

func _build_truck() -> Node3D:
	var root := Node3D.new()
	var mb := MeshBuilder.new()
	var body := Color(0.13, 0.14, 0.12)
	mb.box(Vector3(2.2, 1.1, 4.6), Vector3(0, 1.15, 0.4), body)          # bed/canvas
	mb.box(Vector3(2.0, 0.9, 1.6), Vector3(0, 0.95, -2.6), body.lightened(0.1))  # cab
	mb.box(Vector3(2.2, 0.5, 6.4), Vector3(0, 0.45, -0.4), body.darkened(0.3))   # chassis
	for side: float in [-0.9, 0.9]:
		for zz: float in [-2.4, 0.6, 1.8]:
			mb.cylinder(0.42, 0.42, 0.3, Vector3(side, 0.42, zz), Color(0.05, 0.05, 0.05))
	root.add_child(mb.commit_instance("Truck"))
	# Headlights: hooded slits, but the spill is what the player reads.
	for side: float in [-0.7, 0.7]:
		var head := SpotLight3D.new()
		head.position = Vector3(side, 0.9, -3.4)
		head.rotation_degrees = Vector3(-8, 0, 0)  # SpotLight forward is -Z: out past the cab
		head.light_color = Color(0.95, 0.9, 0.75)
		head.light_energy = 4.2
		head.spot_range = 36.0
		head.spot_angle = 24.0
		root.add_child(head)
	root.rotation.y = PI  # driving north→south becomes south→north flip
	return root

func _on_door(player: Node) -> void:
	player.move_enabled = false
	player.look_enabled = false
	Hud.hide_prompt()
	AudioManager.stop_ambient(1.5)
	GameState.set_flag("ch2_walk_done")
	SceneDirector.goto_beat("ch2_vetting", 1.4)

## Headless drive: chase Marcel's current waypoint, then the barn door.
func _autoplay_step(delta: float) -> void:
	if not ("--autoplay" in OS.get_cmdline_user_args()):
		return
	if _player == null or not _player.move_enabled:
		return
	var target: Vector3
	if _wp < WAYPOINTS.size():
		target = _marcel.position
		if _player.position.distance_to(target) < 2.5:
			return  # don't crowd him; let him advance
	else:
		target = _door.position
		if _player.position.distance_to(target) < 1.6:
			_door.interact(_player)
			return
	target.y = _player.position.y
	_player.position = _player.position.move_toward(target, delta * 3.6)
	_player.position.y = _h(_player.position.x, _player.position.z) + 0.3
