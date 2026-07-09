extends Node
## Screenshot harness for the headless verification loop. Inert in normal
## play; activates only when the run has user args after `++`, e.g.:
##   godot --path . src/dev/graybox.tscn ++ --capture 0.5,2.0 --out /abs/dir
## Saves shot_NN.png at each timestamp (seconds since scene start), then quits.

var _times: Array[float] = []
var _out_dir := ""

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		match args[i]:
			"--capture":
				i += 1
				for part in args[i].split(",", false):
					_times.append(float(part))
			"--out":
				i += 1
				_out_dir = args[i]
		i += 1
	if _times.is_empty():
		return
	if _out_dir.is_empty():
		_out_dir = OS.get_environment("PWD").path_join("artifacts")
	_times.sort()
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run()

func _run() -> void:
	var start := Time.get_ticks_msec()
	for j in _times.size():
		var target_ms := int(_times[j] * 1000.0)
		while Time.get_ticks_msec() - start < target_ms:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := "%s/shot_%02d.png" % [_out_dir, j]
		var err := img.save_png(path)
		print("capture_harness: %s (%s)" % [path, error_string(err)])
	get_tree().quit()
