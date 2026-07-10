class_name Fighter
extends Node3D
## An attacking fighter on a scripted run: cubic-bezier approach past the
## bomber's tail, firing window mid-run, breakaway or spiral down if killed.
## Not an AI — a choreographed threat.

signal gone(fighter: Fighter)

const HP_MAX := 5

var director: Node  # loosely typed; provides spawn_enemy_tracer / spawn_smoke
var duration := 9.0
var p0: Vector3
var p1: Vector3
var p2: Vector3
var p3: Vector3

var _hp := HP_MAX
var _t := 0.0
var _dead := false
var _dead_time := 0.0
var _vel := Vector3.ZERO
var _last_pos := Vector3.ZERO
var _fire_accum := 0.0
var _smoke_accum := 0.0

static func make(start: Vector3, attack: Vector3, exit_p: Vector3, dir_node: Node) -> Fighter:
	var f := Fighter.new()
	f.director = dir_node
	f.p0 = start
	f.p1 = start.lerp(attack, 0.45) + Vector3(randf_range(-40, 40), randf_range(-15, 25), 0)
	f.p2 = attack
	f.p3 = exit_p
	f.position = start
	f._last_pos = start
	f._build_mesh()
	return f

func _build_mesh() -> void:
	var mb := MeshBuilder.new()
	var paint := Color(0.15, 0.16, 0.13)
	var lie := Basis(Vector3.RIGHT, PI / 2)  # cylinder Y axis -> Z
	var body := CylinderMesh.new()
	body.top_radius = 0.42
	body.bottom_radius = 0.34
	body.height = 6.4
	body.radial_segments = 6
	mb.add(body, Transform3D(lie, Vector3.ZERO), paint)
	var nose := CylinderMesh.new()
	nose.top_radius = 0.42
	nose.bottom_radius = 0.06
	nose.height = 1.3
	nose.radial_segments = 6
	mb.add(nose, Transform3D(lie, Vector3(0, 0, -3.8)), paint.darkened(0.2))
	mb.box(Vector3(9.8, 0.12, 1.8), Vector3(0, -0.1, -0.6), paint, 0.0)
	mb.box(Vector3(3.4, 0.10, 1.0), Vector3(0, 0.1, 2.9), paint, 0.0)
	mb.box(Vector3(0.10, 1.2, 1.0), Vector3(0, 0.6, 3.0), paint.darkened(0.1), 0.0)
	mb.box(Vector3(0.5, 0.32, 0.9), Vector3(0, 0.45, -1.2), Color(0.08, 0.09, 0.10), 0.0)
	add_child(mb.commit_instance("Body"))

func hit() -> void:
	if _dead:
		return
	_hp -= 1
	if _hp <= 0:
		_dead = true
		_vel = (position - _last_pos).normalized() * 65.0
		if director and director.has_method("on_fighter_killed"):
			director.on_fighter_killed(self)

func _bezier(t: float) -> Vector3:
	var a := p0.lerp(p1, t)
	var b := p1.lerp(p2, t)
	var c := p2.lerp(p3, t)
	return a.lerp(b, t).lerp(b.lerp(c, t), t)

func _process(delta: float) -> void:
	if _dead:
		_dead_time += delta
		_vel.y -= 22.0 * delta
		position += _vel * delta
		rotate_object_local(Vector3(0, 0, 1), delta * 3.2)
		global_rotate(Vector3.RIGHT, delta * 0.25)
		_smoke_accum += delta
		if _smoke_accum > 0.14 and director:
			_smoke_accum = 0.0
			director.spawn_smoke(global_position, 1.6)
		if _dead_time > 7.0 or global_position.y < -900.0:
			gone.emit(self)
			queue_free()
		return

	_last_pos = position
	_t += delta / duration
	if _t >= 1.0:
		gone.emit(self)
		queue_free()
		return
	position = _bezier(_t)
	var v := position - _last_pos
	if v.length() > 0.001:
		look_at(position + v, Vector3.UP)
		_vel = v / delta

	# Firing window on the way in.
	if _t > 0.30 and _t < 0.62 and director:
		_fire_accum += delta
		if _fire_accum >= 0.38:
			_fire_accum = 0.0
			for i in 3:
				var muzzle := global_position - global_transform.basis.z * 3.0
				director.spawn_enemy_tracer(muzzle, i * 0.05)
