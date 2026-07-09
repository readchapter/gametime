extends CharacterBody3D
## First-person ground movement: walk, mouse-look, interaction raycast.
## Deliberately weighty and unhurried per the game's grounded tone.
## Ch2 stealth extends from here (crouch state, noise emission) — keep this
## the single ground-movement entry point.

@export var walk_speed := 3.2
@export var acceleration := 12.0
@export var mouse_sensitivity := 0.0022

@onready var camera: Camera3D = $Camera3D
@onready var interactor: RayCast3D = $Camera3D/Interactor

var look_enabled := true
var move_enabled := true

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and look_enabled:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x, -PI / 2.2, PI / 2.2)
	elif event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if move_enabled:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	velocity.x = move_toward(velocity.x, wish.x * walk_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, wish.z * walk_speed, acceleration * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()

func _try_interact() -> void:
	if not interactor.is_colliding():
		return
	var hit: Object = interactor.get_collider()
	if hit and hit.has_method("interact"):
		hit.interact(self)
