class_name TurretController
extends Node3D
## Tail-gunner position: mouse aim inside a traverse/elevation cone, twin
## .50s with alternating muzzles, trauma-based screen shake. Not an arcade
## shooter — the point is claustrophobic tension, so the cone is tight and
## the guns feel heavy.

signal fired(muzzle: Vector3, dir: Vector3)

const YAW_LIMIT := 1.0     # ~57 deg each way
const PITCH_UP := 0.55
const PITCH_DOWN := 0.5
const FIRE_INTERVAL := 0.11

@export var mouse_sensitivity := 0.0022

var enabled := true
var trauma := 0.0
var camera: Camera3D

var _yaw := 0.0
var _pitch := 0.0
var _cooldown := 0.0
var _gun_left := true
var _t := 0.0
var _noise := FastNoiseLite.new()
var _muzzle_light: OmniLight3D
var _muzzle_flash: MeshInstance3D
var _flash := 0.0
# Dev-only: hold fire during headless capture runs so the muzzle flash and
# tracers can be verified without input.
var _auto_fire := "--autoplay" in OS.get_cmdline_user_args()

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_noise.seed = 3
	camera = Camera3D.new()
	camera.fov = 70.0
	add_child(camera)
	camera.make_current()
	_build_guns()

## Twin gun barrels attached to the camera so they track the aim.
func _build_guns() -> void:
	var mb := MeshBuilder.new()
	var metal := Color(0.10, 0.10, 0.11)
	for side in [-0.22, 0.22]:
		mb.box(Vector3(0.055, 0.055, 1.05), Vector3(side, -0.34, -0.85), metal)
		mb.box(Vector3(0.12, 0.16, 0.42), Vector3(side, -0.38, -0.22), metal.lightened(0.1))
	mb.box(Vector3(0.56, 0.07, 0.30), Vector3(0, -0.46, -0.30), metal)
	camera.add_child(mb.commit_instance("Guns"))

	# Muzzle flash: a punchy pulse of light + a bright quad at the barrels,
	# both driven by _flash decaying in _process. Makes firing feel like it
	# lands rather than just spawning a distant tracer.
	_muzzle_light = OmniLight3D.new()
	_muzzle_light.position = Vector3(0, -0.36, -1.5)
	_muzzle_light.light_color = Color(1.0, 0.80, 0.45)
	_muzzle_light.light_energy = 0.0
	_muzzle_light.omni_range = 3.5
	camera.add_child(_muzzle_light)

	var flash_mesh := BoxMesh.new()
	flash_mesh.size = Vector3(0.6, 0.22, 0.22)
	_muzzle_flash = MeshInstance3D.new()
	_muzzle_flash.mesh = flash_mesh
	_muzzle_flash.position = Vector3(0, -0.34, -1.55)
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.albedo_color = Color(1.0, 0.85, 0.55, 0.0)
	_muzzle_flash.material_override = fmat
	camera.add_child(_muzzle_flash)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and enabled:
		var sens := mouse_sensitivity * Settings.mouse_scale
		_yaw = clampf(_yaw - event.relative.x * sens, -YAW_LIMIT, YAW_LIMIT)
		_pitch = clampf(_pitch - event.relative.y * sens, -PITCH_DOWN, PITCH_UP)

func _process(delta: float) -> void:
	_t += delta
	trauma = maxf(trauma - delta * 1.3, 0.0)
	var sh := trauma * trauma
	camera.rotation = Vector3(
		_pitch + _noise.get_noise_1d(_t * 85.0 + 57.0) * sh * 0.09,
		_yaw + _noise.get_noise_1d(_t * 85.0) * sh * 0.09,
		_noise.get_noise_1d(_t * 85.0 + 113.0) * sh * 0.06)

	_flash = maxf(_flash - delta * 22.0, 0.0)
	if _muzzle_light:
		_muzzle_light.light_energy = _flash * 2.6
		var fmat: StandardMaterial3D = _muzzle_flash.material_override
		fmat.albedo_color.a = _flash
		_muzzle_flash.scale = Vector3(1.0, 1.0, 1.0) * (0.6 + _flash * 0.7)
		_muzzle_flash.position.x = -0.22 if _gun_left else 0.22

	_cooldown -= delta
	var firing := Input.is_action_pressed("fire")
	if _auto_fire:
		firing = true
	if enabled and firing and _cooldown <= 0.0:
		_cooldown = FIRE_INTERVAL
		_fire()

func _fire() -> void:
	_gun_left = not _gun_left
	var side := -0.22 if _gun_left else 0.22
	var muzzle: Vector3 = camera.global_transform * Vector3(side, -0.34, -1.4)
	var dir := -camera.global_transform.basis.z
	dir = (dir + Vector3(randf_range(-0.008, 0.008), randf_range(-0.008, 0.008),
		randf_range(-0.008, 0.008))).normalized()
	trauma = minf(trauma + 0.06, 0.45)
	_flash = 1.0
	fired.emit(muzzle, dir)

func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)
