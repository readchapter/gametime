class_name Interactable
extends StaticBody3D
## Anything the player can use with E. Duck-typed against the FPS
## controller's raycast: get_prompt() feeds the HUD, interact() fires the
## signal the owning scene connects to. Flag gates let scenes sequence
## interactions ("go to bed" only after the table scene) without bespoke code.

signal interacted(player: Node)

@export var prompt := "Use"
@export var required_flag := ""  ## active only while this GameState flag is truthy
@export var blocked_flag := ""   ## hidden while this GameState flag is truthy
@export var one_shot := false

var _used := false

func get_prompt() -> String:
	return "" if not _active() else "E — " + prompt

func interact(player: Node) -> void:
	if not _active():
		return
	if one_shot:
		_used = true
	interacted.emit(player)

func _active() -> bool:
	if _used:
		return false
	if required_flag != "" and not bool(GameState.get_flag(required_flag)):
		return false
	if blocked_flag != "" and bool(GameState.get_flag(blocked_flag)):
		return false
	return true
