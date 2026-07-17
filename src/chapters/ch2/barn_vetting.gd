extends Node3D
## Chapter 2 — the vetting. STUB (CH2-M4 builds this): fades in, holds a
## card, returns to title.

func _ready() -> void:
	SceneDirector.fade_in(1.0)
	await CutscenePlayer.caption("— THE VETTING —", 3.0)
	await SceneDirector.fade_out(1.0)
	get_tree().change_scene_to_file("res://src/ui/title.tscn")
