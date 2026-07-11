class_name Kit
extends RefCounted
## Loads curated CC0 low-poly models (assets/models/kit/, Kenney) with a
## cohesion tint. Kenney models carry a color-atlas texture; StandardMaterial3D
## albedo_color MULTIPLIES that texture, so a desaturated tint darkens the
## model into our dusk/night palette while preserving its internal color
## variation (trunk vs foliage, etc.). This is what makes the textured packs
## sit inside the vertex-color world instead of popping bright.

const DIR := "res://assets/models/kit/"

static func model(name: String, tint := Color.WHITE, scale := 1.0) -> Node3D:
	var path := DIR + name + ".glb"
	if not ResourceLoader.exists(path):
		push_warning("Kit: missing " + path)
		return null
	var node: Node3D = (load(path) as PackedScene).instantiate()
	if scale != 1.0:
		node.scale = Vector3.ONE * scale
	if tint != Color.WHITE:
		tint_node(node, tint)
	return node

static func tint_node(node: Node, tint: Color) -> void:
	if node is MeshInstance3D and node.mesh:
		for s in node.mesh.get_surface_count():
			var m: Material = node.mesh.surface_get_material(s)
			if m is StandardMaterial3D:
				var m2: StandardMaterial3D = m.duplicate()
				m2.albedo_color = tint
				m2.roughness = 1.0
				m2.metallic = 0.0
				node.set_surface_override_material(s, m2)
	for c in node.get_children():
		tint_node(c, tint)
