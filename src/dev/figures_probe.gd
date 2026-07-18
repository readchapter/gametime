extends Node3D
## Dev-only lineup for eyeballing the Figures builder: villager, hatted coat,
## armed sentry, and a seated figure on a crate. Captured via capture.sh.

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.24, 0.26, 0.30)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 40, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var mb := MeshBuilder.new()
	mb.box(Vector3(12, 0.2, 8), Vector3(0, -0.1, 0), Color(0.32, 0.30, 0.28))
	mb.box(Vector3(0.7, 0.5, 0.7), Vector3(2.4, 0.25, 0), Color(0.35, 0.27, 0.16))
	Figures.seated(mb, Vector3(2.4, 0.5, 0), Color(0.30, 0.24, 0.18), 0.4)
	add_child(mb.commit_instance("Ground"))
	var specs: Array = [
		[Vector3(-2.4, 0, 0), Color(0.28, 0.26, 0.22), false, false],
		[Vector3(-0.8, 0, 0), Color(0.10, 0.10, 0.12), true, false],
		[Vector3(0.8, 0, 0), Color(0.24, 0.26, 0.22), true, true],
	]
	for s: Array in specs:
		var f := Figures.standing(s[1], s[2], s[3])
		f.position = s[0]
		add_child(f)
	var cam := Camera3D.new()
	cam.position = Vector3(0.3, 1.35, 4.6)
	cam.rotation_degrees = Vector3(-4, 0, 0)
	cam.current = true
	add_child(cam)
