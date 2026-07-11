extends Node
## Esc pause menu: resume, mouse sensitivity, restart the current beat,
## quit to title. Esc still skips a seen cutscene (CutscenePlayer wins);
## the title screen never pauses.

var _layer: CanvasLayer
var _slider: HSlider
var _sens_label: Label
var _prev_mouse := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 120
	add_child(_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.74)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(center)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.86, 0.83, 0.78))
	box.add_child(title)

	_sens_label = Label.new()
	_sens_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sens_label.add_theme_font_size_override("font_size", 17)
	_sens_label.add_theme_color_override("font_color", Color(0.62, 0.59, 0.52))
	box.add_child(_sens_label)

	_slider = HSlider.new()
	_slider.min_value = 0.3
	_slider.max_value = 2.5
	_slider.step = 0.05
	_slider.custom_minimum_size = Vector2(340, 24)
	_slider.value_changed.connect(_on_sensitivity)
	box.add_child(_slider)

	box.add_child(_button("RESUME", _resume))
	box.add_child(_button("RESTART THIS PART", _restart_beat))
	box.add_child(_button("QUIT TO TITLE", _quit_to_title))
	_layer.hide()

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	b.add_theme_color_override("font_hover_color", Color(0.95, 0.82, 0.58))
	b.pressed.connect(action)
	return b

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var scene := get_tree().current_scene
	if scene and scene.name == "Title":
		return
	if CutscenePlayer.playing and not get_tree().paused:
		return  # Esc is the cutscene skip there
	if get_tree().paused:
		_resume()
	else:
		_pause()

func _pause() -> void:
	_prev_mouse = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_slider.set_value_no_signal(Settings.mouse_scale)
	_update_label()
	get_tree().paused = true
	_layer.show()

func _resume() -> void:
	_layer.hide()
	get_tree().paused = false
	Input.mouse_mode = _prev_mouse

func _on_sensitivity(v: float) -> void:
	Settings.mouse_scale = v
	Settings.save_settings()
	_update_label()

func _update_label() -> void:
	_sens_label.text = "MOUSE SENSITIVITY  ×%.2f" % Settings.mouse_scale

func _restart_beat() -> void:
	_resume()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var beat: String = GameState.beat if SceneDirector.CH1_BEATS.has(GameState.beat) else "hardstand"
	SceneDirector.goto_beat(beat, 0.4)

func _quit_to_title() -> void:
	_resume()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_ambient(0.5)
	SceneDirector.fade_to_scene("res://src/ui/title.tscn", 0.5)
