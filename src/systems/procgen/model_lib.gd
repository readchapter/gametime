class_name ModelLib
extends RefCounted
## Imported-model drop-in with graceful fallback, mirroring AudioManager:
## if res://assets/models/<name>.glb exists it's instantiated, otherwise the
## procedural builder runs. Drop a .glb in and the primitive disappears with
## no code changes. Wanted list: assets/models/MANIFEST.md.

static var _warned := {}

static func get_model(model_name: String, fallback: Callable) -> Node3D:
	var path := "res://assets/models/%s.glb" % model_name
	if ResourceLoader.exists(path):
		var scene: PackedScene = load(path)
		if scene:
			var node := scene.instantiate()
			if node is Node3D:
				node.name = model_name
				return node
	if not _warned.has(model_name):
		_warned[model_name] = true
		print("ModelLib: no model yet for '%s', using procedural fallback" % model_name)
	return fallback.call()
