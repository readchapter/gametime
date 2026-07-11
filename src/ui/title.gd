extends Node
## Title card. Restrained: black, the name, one key. Continue appears only
## when a save exists. Built on a CanvasLayer with anchored children (a bare
## root Control does not auto-size to the viewport).

var _hint: Label
var _can_continue := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.018)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "T H E   F A L L"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.86, 0.83, 0.78))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "CHAPTER ONE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42))
	box.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 60)
	box.add_child(spacer)

	_can_continue = FileAccess.file_exists(GameState.SAVE_PATH)
	_hint = Label.new()
	_hint.text = "SPACE — BEGIN" + ("        C — CONTINUE" if _can_continue else "")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.60, 0.57, 0.50))
	box.add_child(_hint)

	var tw := create_tween().set_loops()
	tw.tween_property(_hint, "modulate:a", 0.35, 1.4)
	tw.tween_property(_hint, "modulate:a", 1.0, 1.4)

	AudioManager.play_music("title_theme")

	# Clear the fade overlay: a no-op at game start (already clear), and the
	# reveal when we arrive here from the Chapter 1 end card (still black).
	SceneDirector.fade_in(1.5)

	if "--autoplay" in OS.get_cmdline_user_args():
		await get_tree().create_timer(1.5).timeout
		_begin()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		_begin()
	elif _can_continue and event is InputEventKey and event.pressed \
			and event.physical_keycode == KEY_C:
		_continue_game()

func _begin() -> void:
	set_process_input(false)
	GameState.flags.clear()
	GameState.inventory.clear()
	GameState.chapter = 1
	AudioManager.stop_music(1.5)
	SceneDirector.goto_beat("hardstand", 1.2)

func _continue_game() -> void:
	set_process_input(false)
	GameState.load_game()
	AudioManager.stop_music(1.5)
	var beat := GameState.beat if SceneDirector.CH1_BEATS.has(GameState.beat) else "hardstand"
	SceneDirector.goto_beat(beat, 1.2)
