class_name ParachuteController
extends Node3D
## The jump: a short tumbling freefall, the canopy snap, then a slow drift
## with WASD steering against a steady wind. Deliberately floaty and quiet —
## the tension is in where you're drifting, not in the handling.

signal deployed_canopy
signal landed(pos: Vector3)

const FREEFALL_TIME := 2.2
const FREEFALL_SPEED := 32.0
const FALL_SPEED := 5.2
const DRIFT_MAX := 6.0
const DRIFT_ACCEL := 3.5

@export var wind := Vector3(0.9, 0.0, 0.15)
@export var mouse_sensitivity := 0.0022

var camera: Camera3D
var deployed := false
var down := false
## Scene provides terrain height lookup: func(x, z) -> float.
var height_probe: Callable

var _drift := Vector3.ZERO
var _yaw := 0.0
var _pitch := -0.3
var _time := 0.0
var _canopy: Node3D
var _shake := 0.0
var _noise := FastNoiseLite.new()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_noise.seed = 11
	camera = Camera3D.new()
	camera.fov = 75.0
	add_child(camera)
	camera.make_current()
	_build_canopy()
	_canopy.hide()

func _build_canopy() -> void:
	_canopy = Node3D.new()
	var mb := MeshBuilder.new()
	var silk := Color(0.72, 0.70, 0.64)
	var s := SphereMesh.new()
	s.radius = 3.4
	s.height = 2.4
	s.radial_segments = 10
	s.rings = 4
	mb.add(s, Transform3D(Basis.IDENTITY, Vector3(0, 6.2, 0)), silk)
	for corner in [Vector3(-2.4, 0, -2.4), Vector3(2.4, 0, -2.4),
			Vector3(-2.4, 0, 2.4), Vector3(2.4, 0, 2.4)]:
		var riser := CylinderMesh.new()
		riser.top_radius = 0.015
		riser.bottom_radius = 0.015
		riser.height = 5.6
		riser.radial_segments = 4
		riser.rings = 1
		var up_dir := (Vector3(corner.x, 5.8, corner.z)).normalized()
		var basis := Basis(Vector3.FORWARD.cross(up_dir).normalized(),
			acos(Vector3.UP.dot(up_dir))) if up_dir != Vector3.UP else Basis.IDENTITY
		mb.add(riser, Transform3D(basis, Vector3(corner.x * 0.5, 3.0, corner.z * 0.5)), silk.darkened(0.4))
	_canopy.add_child(mb.commit_instance("Canopy"))
	add_child(_canopy)

func add_shake(amount: float) -> void:
	_shake = minf(_shake + amount, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not down:
		var sens := mouse_sensitivity * Settings.mouse_scale
		_yaw -= event.relative.x * sens
		_pitch = clampf(_pitch - event.relative.y * sens, -1.25, 0.55)

func _process(delta: float) -> void:
	_time += delta
	_shake = maxf(_shake - delta * 1.2, 0.0)
	if down:
		return

	if not deployed:
		position.y -= FREEFALL_SPEED * delta
		# Tumble
		camera.rotation = Vector3(_pitch + sin(_time * 3.1) * 0.35,
			_yaw + _time * 1.7, sin(_time * 2.2) * 0.5)
		if _time >= FREEFALL_TIME:
			_deploy()
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var yaw_basis := Basis(Vector3.UP, _yaw)
		var wish := yaw_basis * Vector3(input_dir.x, 0.0, input_dir.y) * DRIFT_MAX
		_drift = _drift.move_toward(wish, DRIFT_ACCEL * delta)
		position += (_drift + wind) * delta
		position.y -= FALL_SPEED * delta
		var sway := sin(_time * 0.7) * 0.03
		var sh := _shake * _shake
		camera.rotation = Vector3(
			_pitch + _noise.get_noise_1d(_time * 70.0) * sh * 0.08,
			_yaw + _noise.get_noise_1d(_time * 70.0 + 31.0) * sh * 0.08,
			sway + sin(_time * 0.45 + 1.1) * 0.02)
		_canopy.rotation.z = -sway * 2.0
		_canopy.rotation.y = _yaw

	if height_probe.is_valid() and position.y <= float(height_probe.call(position.x, position.z)) + 1.6:
		down = true
		landed.emit(position)

func _deploy() -> void:
	deployed = true
	_canopy.show()
	# The snap: yanked upright, a hard jolt settling into the sway.
	var tw := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	camera.position.y = -0.9
	tw.tween_property(camera, "position:y", 0.0, 1.4)
	add_shake(0.5)
	deployed_canopy.emit()
