class_name ModelLib
extends RefCounted
## Imported-model drop-in with graceful fallback, mirroring AudioManager.
## Drop a .glb at res://assets/models/<name>.glb and it replaces the
## procedural primitive at the matching call site with no code changes;
## otherwise the procedural builder runs. Wanted list: assets/models/MANIFEST.md.
##
## Chapter 1 currently ships fully procedural by design (the CC0 packs that can
## be auto-fetched are a tonal mismatch for the dark WWII look), so nothing is
## wired in — the capability waits here for tone-appropriate low-poly assets.

static var _warned := {}

static func get_model(model_name: String, fallback: Callable) -> Node3D:
	var override_path := "res://assets/models/%s.glb" % model_name
	if ResourceLoader.exists(override_path):
		var scene: PackedScene = load(override_path)
		if scene:
			var node := scene.instantiate()
			if node is Node3D:
				node.name = model_name
				return node
	if not _warned.has(model_name):
		_warned[model_name] = true
		print("ModelLib: no model for '%s', using procedural fallback" % model_name)
	return fallback.call()
