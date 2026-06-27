extends SceneTree

# Capture screenshots of the running game by driving the real Main scene.
# Run (with a window, NOT headless):
#   godot --path <project> --script res://tools/shot.gd

var _out_dir := "user://shots"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.size = Vector2i(1280, 720)
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	_run(main)

func _run(main: Node) -> void:
	await _wait(30)
	await _capture("01_menu")

	# Topic picker
	if main.has_method("_show_topic_picker"):
		main.call("_show_topic_picker")
	await _wait(20)
	await _capture("02_chon_chu_de")

	# Stage list popup for first topic
	if main.has_method("_show_stage_popup"):
		main.call("_show_stage_popup", 0)
	await _wait(20)
	await _capture("03_chon_man")

	# Enter gameplay (topic 0, stage 0)
	if main.has_method("_start_stage_game"):
		main.call("_start_stage_game", 0, 0)
	await _wait(40)
	await _capture("04_man_choi")

	var ui: Node = main.get("game_board")
	var state: GameState = ui.get("game_state")

	# Mid-game: solve roughly half the words as correct guesses
	var words: Array = state.placed_words
	var half: int = int(ceil(float(words.size()) / 2.0))
	for i in range(half):
		_solve_word(state, words[i])
	_refresh_ui(ui)
	await _wait(15)
	await _capture("05_dang_choi")

	# Finish the rest -> completion/win screen
	for i in range(half, words.size()):
		_solve_word(state, words[i])
	_refresh_ui(ui)
	if ui.has_method("_update_status"):
		ui.call("_update_status")
	await _wait(30)
	await _capture("06_ket_qua")

	quit()

func _solve_word(state: GameState, word_data: Dictionary) -> void:
	var id: int = int(word_data["id"])
	var entry: WordEntry = word_data["entry"]
	state.select_word_timer(id)
	var earned: int = state.award_score_for_word(id)
	state.record_guess(id, entry.word, true, earned)
	state.reveal_word(id)

func _refresh_ui(ui: Node) -> void:
	if ui.has_method("_build_board"):
		ui.call("_build_board")
	if ui.has_method("refresh_clues"):
		ui.call("refresh_clues")
	if ui.has_method("_update_stats"):
		ui.call("_update_stats")

func _wait(frames: int) -> void:
	for i in range(frames):
		await process_frame

func _capture(name: String) -> void:
	await process_frame
	var img: Image = root.get_texture().get_image()
	var path := "%s/%s.png" % [_out_dir, name]
	var err := img.save_png(path)
	print("SHOT %s err=%d size=%dx%d" % [path, err, img.get_width(), img.get_height()])
