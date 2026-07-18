extends Node3D
## Chapter 3 — the checkpoint. STUB (CH3-M4 builds this).

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE CHECKPOINT —", 3.0)
	await SceneDirector.fade_out(1.0)
	get_tree().change_scene_to_file("res://src/ui/title.tscn")
