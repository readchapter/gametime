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
var _flashes: Array[MeshInstance3D] = []
var _flash_left := 0.0

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
	add_child(ModelLib.get_model("fw190", Aircraft.fw190))
	# Wing muzzle flashes: hidden emissive quads pulsed during firing bursts.
	# At attack range these read as flickering points — "they're shooting".
	for side in [-1.7, 1.7]:
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.45, 0.45, 0.7)
		mi.mesh = b
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.85, 0.5)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.45)
		mat.emission_energy_multiplier = 3.0
		mi.material_override = mat
		mi.position = Vector3(side, -0.05, -1.6)
		mi.hide()
		add_child(mi)
		_flashes.append(mi)

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

	# Muzzle flash pulse decay
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			for f in _flashes:
				f.hide()

	# Firing window on the way in.
	if _t > 0.30 and _t < 0.62 and director:
		_fire_accum += delta
		if _fire_accum >= 0.38:
			_fire_accum = 0.0
			_flash_left = 0.12
			for f in _flashes:
				f.show()
			for i in 3:
				var muzzle := global_position - global_transform.basis.z * 3.0
				director.spawn_enemy_tracer(muzzle, i * 0.05)
