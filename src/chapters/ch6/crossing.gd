extends Node3D
## Chapter 6 — crossing. STUB (built in a later CH6 milestone).

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE CROSSING —", 3.0)
	await SceneDirector.fade_out(1.0)
	get_tree().change_scene_to_file("res://src/ui/title.tscn")
