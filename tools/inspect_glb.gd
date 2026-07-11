extends SceneTree
## Dev tool: dump a glb's node tree, animations, and bounds.
##   engine/godot --headless --path . -s tools/inspect_glb.gd -- <res_path>

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: -s tools/inspect_glb.gd -- <res://path.glb>")
		quit(1)
		return
	var scene: PackedScene = load(args[0])
	if scene == null:
		printerr("cannot load " + args[0])
		quit(1)
		return
	var node := scene.instantiate()
	_dump(node, 0)
	var aabb := _bounds(node)
	print("AABB: pos=%s size=%s" % [aabb.position, aabb.size])
	quit(0)

func _dump(n: Node, depth: int) -> void:
	var extra := ""
	if n is AnimationPlayer:
		extra = " anims=" + str(n.get_animation_list())
	if n is MeshInstance3D and n.mesh:
		extra = " surfaces=%d" % n.mesh.get_surface_count()
	print("%s%s (%s)%s" % ["  ".repeat(depth), n.name, n.get_class(), extra])
	for c in n.get_children():
		_dump(c, depth + 1)

func _bounds(n: Node) -> AABB:
	var total := AABB()
	var first := true
	var stack: Array[Node] = [n]
	while stack.size() > 0:
		var cur: Node = stack.pop_back()
		if cur is MeshInstance3D and cur.mesh:
			var ab: AABB = cur.get_aabb()
			if cur is Node3D:
				ab = cur.transform * ab
			if first:
				total = ab
				first = false
			else:
				total = total.merge(ab)
		for c in cur.get_children():
			stack.append(c)
	return total
