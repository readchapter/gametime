extends Node3D
## Throwaway verification probe: watches the tail turret from outside so the
## ejected .50 casings are visible (the gunner's own view looks past them).

func _ready() -> void:
	var floor_mb := MeshBuilder.new()
	floor_mb.box(Vector3(4.0, 0.08, 6.0), Vector3(0, -1.02, 0), Color(0.25, 0.25, 0.28))
	add_child(floor_mb.commit_instance("Floor"))

	var turret := TurretController.new()
	add_child(turret)
	# Force auto-fire regardless of args, then steal the view.
	turret.set("_auto_fire", true)

	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(1.6, -0.2, -1.4)
	cam.look_at(Vector3(0, -0.6, -0.6))
	cam.make_current()

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.4, 0.45, 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.55)
	e.ambient_light_energy = 0.8
	env.environment = e
	add_child(env)

	# make_current in TurretController._ready ran first; ours ran after, wins.
