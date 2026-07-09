extends Node
## Data-driven cutscene timeline runner. Cutscenes are short and deliberate
## (see the brief): a JSON list of steps, skippable with Esc after first
## viewing. Scenes must set up their own post-cutscene state so a skip can
## simply stop the timeline.
##
## Schema (data/cutscenes/**.json):
##   {"id": "farmhouse_intro", "steps": [
##     {"type": "fade_out", "duration": 1.0},
##     {"type": "fade_in", "duration": 1.0},
##     {"type": "wait", "seconds": 2.0},
##     {"type": "caption", "text": "...", "seconds": 3.0},
##     {"type": "dialogue", "path": "res://data/dialogue/..."},
##     {"type": "camera_cut", "node": "PathFromRoot"},
##     {"type": "camera_move", "node": "PathFromRoot", "seconds": 2.0},
##     {"type": "call", "node": "PathFromRoot", "method": "some_method"}
##   ]}

signal finished(id: String)

var playing := false

var _skippable := false
var _skip := false
var _caption: Label

func _ready() -> void:
	var layer := CanvasLayer.new()
	# Above SceneDirector's fade (100): captions must read over black.
	layer.layer = 110
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size", 30)
	_caption.add_theme_color_override("font_color", Color(0.88, 0.85, 0.80))
	_caption.modulate.a = 0.0
	layer.add_child(_caption)
	add_child(layer)

func play(path: String, root: Node) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cutscene file not found: " + path)
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Malformed cutscene JSON: " + path)
		return
	var id := str(data.get("id", path.get_file().get_basename()))
	_skippable = GameState.has_seen_cutscene(id)
	_skip = false
	playing = true
	for step: Dictionary in data.get("steps", []):
		if _skip:
			break
		await _do_step(step, root)
	GameState.mark_cutscene_seen(id)
	playing = false
	_caption.modulate.a = 0.0
	finished.emit(id)

func _do_step(step: Dictionary, root: Node) -> void:
	match str(step.get("type", "")):
		"fade_out":
			await SceneDirector.fade_out(float(step.get("duration", 1.0)))
		"fade_in":
			await SceneDirector.fade_in(float(step.get("duration", 1.0)))
		"wait":
			await get_tree().create_timer(float(step.get("seconds", 1.0))).timeout
		"caption":
			await _show_caption(str(step.get("text", "")), float(step.get("seconds", 3.0)))
		"dialogue":
			DialogueManager.start(str(step.get("path", "")))
			if DialogueManager.active:
				await DialogueManager.dialogue_ended
		"camera_cut":
			var cam := root.get_node_or_null(str(step.get("node", "")))
			if cam is Camera3D:
				cam.make_current()
		"camera_move":
			await _camera_move(root, step)
		"call":
			var target := root.get_node_or_null(str(step.get("node", "")))
			if target:
				target.call(str(step.get("method", "")))
		_:
			push_warning("Unknown cutscene step: " + str(step))

func _show_caption(text: String, seconds: float) -> void:
	_caption.text = text
	var tw := create_tween()
	tw.tween_property(_caption, "modulate:a", 1.0, 0.8)
	tw.tween_interval(seconds)
	tw.tween_property(_caption, "modulate:a", 0.0, 0.8)
	await tw.finished

func _camera_move(root: Node, step: Dictionary) -> void:
	var target := root.get_node_or_null(str(step.get("node", "")))
	var cam := root.get_viewport().get_camera_3d()
	if target is Node3D and cam:
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(cam, "global_transform", target.global_transform,
			float(step.get("seconds", 2.0)))
		await tw.finished

func _input(event: InputEvent) -> void:
	if playing and _skippable and event.is_action_pressed("ui_cancel"):
		_skip = true
