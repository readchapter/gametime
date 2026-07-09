extends Node
## Registers input actions in code so the input map stays version-portable
## (project.godot is hand-maintained; no editor-serialized InputEvent blobs).

const KEY_ACTIONS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"interact": KEY_E,
	"advance": KEY_SPACE,
}

func _init() -> void:
	for action: String in KEY_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_ACTIONS[action]
		InputMap.action_add_event(action, ev)

	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var fire_ev := InputEventMouseButton.new()
		fire_ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", fire_ev)

	# Left click also advances dialogue.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("advance", click)
