extends Node
## Player-facing settings, persisted separately from the save game.

const PATH := "user://settings.json"

var mouse_scale := 1.0

func _ready() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY:
		mouse_scale = clampf(float(data.get("mouse_scale", 1.0)), 0.2, 3.0)

func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"mouse_scale": mouse_scale}))
