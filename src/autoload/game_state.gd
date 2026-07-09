extends Node
## Global game state: story flags, inventory, and persistence.
## Thin for Chapter 1, but the schema (flags + inventory + chapter/beat) is
## what the later trust and branching systems will build on — trust is never
## a visible meter, just flags consulted by dialogue conditions.

signal flag_changed(flag: String, value: Variant)

const SAVE_PATH := "user://save.json"

var flags: Dictionary = {}
var inventory: Dictionary = {}
var seen_cutscenes: Dictionary = {}
var chapter: int = 1
var beat: String = ""

func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)

func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)

func add_item(id: String) -> void:
	inventory[id] = true

func has_item(id: String) -> bool:
	return inventory.get(id, false)

func mark_cutscene_seen(id: String) -> void:
	seen_cutscenes[id] = true

func has_seen_cutscene(id: String) -> bool:
	return seen_cutscenes.get(id, false)

func save_game() -> void:
	var data := {
		"flags": flags,
		"inventory": inventory,
		"seen_cutscenes": seen_cutscenes,
		"chapter": chapter,
		"beat": beat,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not open save file for writing")
		return
	f.store_string(JSON.stringify(data, "\t"))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	flags = data.get("flags", {})
	inventory = data.get("inventory", {})
	seen_cutscenes = data.get("seen_cutscenes", {})
	chapter = int(data.get("chapter", 1))
	beat = str(data.get("beat", ""))
	return true
