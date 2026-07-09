extends Node3D
## Dev-only: opens the farm table dialogue and advances to the first choice
## node so the DialogueBox UI can be captured/inspected without playing
## through the farmhouse scene.

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	add_child(cam)
	cam.make_current()

	await get_tree().create_timer(0.4).timeout
	DialogueManager.start("res://data/dialogue/ch1/farm_table.json")
	DialogueManager.advance()  # eat -> thin
	DialogueManager.advance()  # thin -> how_many
	DialogueManager.advance()  # show choices
