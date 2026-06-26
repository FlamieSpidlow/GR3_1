class_name UIController
extends Control

signal start_new_game_requested
signal back_to_menu_requested

const TILE_SCENE := preload("res://scenes/Tile.tscn")
const MAX_TILE_SIZE := 36
const MIN_TILE_SIZE := 12
const HINT_LETTER_COST := 1
const HINT_WORD_COST := 3
const COLOR_INK := GameUITheme.INK
const COLOR_MUTED := GameUITheme.MUTED
const COLOR_PANEL := GameUITheme.PANEL
const COLOR_PANEL_ALT := GameUITheme.PANEL_ALT
const COLOR_PRIMARY := GameUITheme.PRIMARY
const COLOR_PRIMARY_DARK := GameUITheme.PRIMARY_DARK
const COLOR_SECONDARY := GameUITheme.SECONDARY
const COLOR_SECONDARY_BORDER := GameUITheme.SECONDARY_BORDER
const COLOR_SUCCESS := GameUITheme.SUCCESS
const COLOR_SUCCESS_SOFT := GameUITheme.SUCCESS_SOFT
const COLOR_WARNING := GameUITheme.WARNING
const COLOR_FOCUS := GameUITheme.FOCUS

@onready var margin_container: MarginContainer = $MarginContainer
@onready var root_vbox: VBoxContainer = $MarginContainer/RootVBox
@onready var header_bar: HBoxContainer = $MarginContainer/RootVBox/HeaderBar
@onready var root_hbox: BoxContainer = $MarginContainer/RootVBox/RootHBox
@onready var left_column: VBoxContainer = $MarginContainer/RootVBox/RootHBox/LeftColumn
@onready var right_column: VBoxContainer = $MarginContainer/RootVBox/RootHBox/RightColumn
@onready var board_card: PanelContainer = $MarginContainer/RootVBox/RootHBox/LeftColumn/BoardCard
@onready var control_card: PanelContainer = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard
@onready var board_box: VBoxContainer = $MarginContainer/RootVBox/RootHBox/LeftColumn/BoardCard/BoardBox
@onready var board_grid: GridContainer = $MarginContainer/RootVBox/RootHBox/LeftColumn/BoardCard/BoardBox/BoardGrid
@onready var board_title: Label = $MarginContainer/RootVBox/RootHBox/LeftColumn/BoardCard/BoardBox/BoardHeader/BoardTitle
@onready var clue_title: Label = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/ClueTitle
@onready var clue_list: HFlowContainer = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/ClueList
@onready var replay_button: Button = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/ActionRow/ReplayButton
@onready var menu_button: Button = $PauseOverlay/PausePopup/PauseBox/PauseMenuButton
@onready var hint_letter_button: Button = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/ActionRow/HintLetterButton
@onready var hint_word_button: Button = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/ActionRow/HintWordButton
@onready var guess_title: Label = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/GuessTitle
@onready var guess_input: LineEdit = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/GuessRow/GuessInput
@onready var guess_button: Button = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/GuessRow/GuessButton
@onready var status_label: Label = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/StatusLabel
@onready var stats_label: Label = $MarginContainer/RootVBox/RootHBox/RightColumn/ControlCard/ControlBox/StatsLabel
@onready var time_label: Label = $MarginContainer/RootVBox/HeaderBar/TimeLabel
@onready var star_hud: PanelContainer = $MarginContainer/RootVBox/HeaderBar/StarHud
@onready var star_icon: TextureRect = $MarginContainer/RootVBox/HeaderBar/StarHud/StarBox/StarIcon
@onready var star_count_label: Label = $MarginContainer/RootVBox/HeaderBar/StarHud/StarBox/StarCount
@onready var completion_card: PanelContainer = $MarginContainer/RootVBox/RootHBox/RightColumn/CompletionCard
@onready var completion_box: VBoxContainer = $MarginContainer/RootVBox/RootHBox/RightColumn/CompletionCard/CompletionBox
@onready var completion_title: Label = $MarginContainer/RootVBox/RootHBox/RightColumn/CompletionCard/CompletionBox/StatsTitle
@onready var completion_bar: ProgressBar = $MarginContainer/RootVBox/RootHBox/RightColumn/CompletionCard/CompletionBox/CompletionRow/CompletionBar
@onready var accuracy_bar: ProgressBar = $MarginContainer/RootVBox/RootHBox/RightColumn/CompletionCard/CompletionBox/AccuracyRow/AccuracyBar
@onready var history_list: VBoxContainer = $MarginContainer/RootVBox/RootHBox/RightColumn/CompletionCard/CompletionBox/HistoryList
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var pause_popup: PanelContainer = $PauseOverlay/PausePopup
@onready var pause_title: Label = $PauseOverlay/PausePopup/PauseBox/PauseTitle
@onready var pause_continue_button: Button = $PauseOverlay/PausePopup/PauseBox/PauseContinueButton
@onready var win_overlay: ColorRect = $WinOverlay
@onready var win_popup: PanelContainer = $WinOverlay/WinPopup
@onready var win_title: Label = $WinOverlay/WinPopup/WinBox/WinTitle
@onready var win_summary: Label = $WinOverlay/WinPopup/WinBox/WinSummary
@onready var win_stats: Label = $WinOverlay/WinPopup/WinBox/WinStats
@onready var win_progress: ProgressBar = $WinOverlay/WinPopup/WinBox/WinProgress
@onready var win_replay_button: Button = $WinOverlay/WinPopup/WinBox/WinButtons/WinReplayButton
@onready var win_menu_button: Button = $WinOverlay/WinPopup/WinBox/WinButtons/WinMenuButton
@onready var input_controller: InputController = $InputController

var game_state: GameState
var tile_buttons: Dictionary = {}
var clue_labels: Dictionary = {}
var clue_texts: Dictionary = {}
var last_time_second: int = -1
var completion_revealed: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var best_score: int = 0
var total_stars: int = 0
var layout_scale: float = 1.0
var displayed_stars: int = -1
var is_paused: bool = false

func _ready() -> void:
	replay_button.pressed.connect(_on_replay_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	pause_continue_button.pressed.connect(_on_pause_continue_pressed)
	hint_letter_button.pressed.connect(_on_hint_letter_pressed)
	hint_word_button.pressed.connect(_on_hint_word_pressed)
	guess_button.pressed.connect(_on_guess_pressed)
	guess_input.text_submitted.connect(_on_guess_submitted)
	win_replay_button.pressed.connect(_on_win_replay_pressed)
	win_menu_button.pressed.connect(_on_win_menu_pressed)
	set_process(true)
	hint_letter_button.text = "Lộ 1 chữ (-%d★)" % HINT_LETTER_COST
	hint_word_button.text = "Lộ cả từ (-%d★)" % HINT_WORD_COST
	win_replay_button.text = "Chơi lại"
	_apply_ui_theme()
	_update_star_display(false)
	_apply_responsive_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()
		if game_state != null:
			_apply_board_layout()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and game_state != null and not win_overlay.visible:
		if is_paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()

func setup_with_state(state: GameState) -> void:
	game_state = state
	best_score = SaveManager.load_best_score()
	total_stars = SaveManager.load_total_stars()
	displayed_stars = -1
	_update_star_display(false)
	_apply_responsive_layout()
	_build_board()
	_build_clues()
	_update_board_title()
	_show_play_widgets(false)
	completion_card.visible = false
	win_overlay.visible = false
	pause_overlay.visible = false
	is_paused = false
	completion_revealed = false
	guess_input.text = ""
	input_controller.setup(self, state)
	refresh_all_tiles()
	refresh_clues()
	_update_guess_placeholder()
	_update_status()
	_start_selected_word_timer()
	_update_time_label()
	_refresh_history()
	_play_intro_animation()
	call_deferred("_refresh_responsive_board")

func _process(_delta: float) -> void:
	if game_state == null or is_paused:
		return
	var seconds: int = game_state.get_elapsed_seconds()
	if seconds != last_time_second:
		last_time_second = seconds
		_update_time_label()

func refresh_tile(pos: Vector2i) -> void:
	if not tile_buttons.has(pos):
		return
	var tile_button: TileButton = tile_buttons[pos]
	var is_selected: bool = input_controller.selected_pos == pos
	var cell: Variant = game_state.get_tile(pos)
	var is_active: bool = false
	if cell != null and input_controller.active_word_id >= 0:
		var word_ids: Array = cell.get("word_ids", [])
		if word_ids.has(input_controller.active_word_id):
			is_active = true
	tile_button.update_view(cell, is_selected, is_active)

func refresh_all_tiles() -> void:
	for pos in tile_buttons.keys():
		refresh_tile(pos)

func _build_board() -> void:
	_clear_children(board_grid)
	tile_buttons = {}
	var tile_size: int = _apply_board_layout()
	for y in range(game_state.height):
		for x in range(game_state.width):
			var tile: TileButton = TILE_SCENE.instantiate()
			tile.set_display_size(tile_size)
			tile.grid_pos = Vector2i(x, y)
			tile.tile_pressed.connect(_on_tile_pressed)
			board_grid.add_child(tile)
			var pos: Vector2i = Vector2i(x, y)
			tile_buttons[pos] = tile
			tile.update_view(game_state.get_tile(pos), false, false)

func _apply_board_layout() -> int:
	var tile_size: int = _get_tile_size_for_board(game_state.width, game_state.height)
	var tile_spacing: int = _get_tile_spacing(tile_size)
	board_grid.columns = game_state.width
	board_grid.add_theme_constant_override("h_separation", tile_spacing)
	board_grid.add_theme_constant_override("v_separation", tile_spacing)
	for tile in tile_buttons.values():
		tile.set_display_size(tile_size)
	return tile_size

func _get_tile_size_for_board(width: int, height: int) -> int:
	var viewport_size: Vector2 = get_viewport_rect().size
	var ui_scale: float = _get_ui_scale()
	var board_padding: float = 14.0 * ui_scale
	var title_label_height: float = board_title.size.y
	if title_label_height < 1.0:
		title_label_height = 34.0 * ui_scale
	var title_height: float = title_label_height + float(board_box.get_theme_constant("separation")) + (12.0 * ui_scale)
	var box_width: float = board_box.size.x if is_instance_valid(board_box) else 0.0
	var box_height: float = board_box.size.y if is_instance_valid(board_box) else 0.0
	var board_width: float = board_card.size.x if is_instance_valid(board_card) else 0.0
	var board_height: float = board_card.size.y if is_instance_valid(board_card) else 0.0
	var safety_padding: float = 28.0 * ui_scale
	var edge_margin: float = float(margin_container.get_theme_constant("margin_top")) if is_instance_valid(margin_container) else 20.0
	var header_height: float = header_bar.size.y if is_instance_valid(header_bar) else 44.0
	var root_spacing: float = float(root_vbox.get_theme_constant("separation")) if is_instance_valid(root_vbox) else 10.0
	var viewport_board_height: float = viewport_size.y - (edge_margin * 2.0) - header_height - root_spacing
	var viewport_board_width: float = viewport_size.x - (edge_margin * 2.0)
	if is_instance_valid(right_column) and not root_hbox.vertical and viewport_size.x >= 760.0:
		var column_gap: float = float(root_hbox.get_theme_constant("separation")) if is_instance_valid(root_hbox) else 10.0
		viewport_board_width -= right_column.custom_minimum_size.x + column_gap
	var measured_width: float = board_width if board_width > 1.0 else box_width
	var measured_height: float = board_height if board_height > 1.0 else box_height
	measured_width = minf(measured_width, viewport_board_width)
	measured_height = minf(measured_height, viewport_board_height)
	var available_width: float = measured_width - board_padding - safety_padding
	var available_height: float = measured_height - title_height - board_padding - safety_padding
	if available_width < 180.0:
		if is_instance_valid(root_hbox) and root_hbox.vertical:
			available_width = viewport_size.x - (edge_margin * 2.0) - board_padding - safety_padding
		else:
			var right_width: float = right_column.custom_minimum_size.x if is_instance_valid(right_column) else 300.0
			var fallback_column_gap: float = 18.0 if viewport_size.x >= 960.0 else 10.0
			available_width = minf(board_width, viewport_size.x - (edge_margin * 2.0) - right_width - fallback_column_gap) - board_padding - safety_padding
	if available_height < 180.0:
		var edge_margin_y: float = edge_margin
		available_height = viewport_size.y - (edge_margin_y * 2.0) - 58.0 - title_height - safety_padding
	available_width = maxf(80.0, available_width)
	available_height = maxf(80.0, available_height)
	var spacing: int = _get_tile_spacing(MAX_TILE_SIZE)
	var width_spacing: int = maxi(width - 1, 0) * spacing
	var height_spacing: int = maxi(height - 1, 0) * spacing
	var width_based: int = int(floor((available_width - float(width_spacing)) / float(maxi(width, 1))))
	var height_based: int = int(floor((available_height - float(height_spacing)) / float(maxi(height, 1))))
	var min_tile: int = clampi(_scaled(MIN_TILE_SIZE, ui_scale), 10, 16)
	var max_tile: int = clampi(_scaled(MAX_TILE_SIZE, ui_scale), 24, 38)
	var tile_size: int = clampi(mini(width_based, height_based), min_tile, max_tile)
	var final_spacing: int = _get_tile_spacing(tile_size)
	while tile_size > min_tile:
		var pixel_width: int = (tile_size * width) + (final_spacing * maxi(width - 1, 0))
		var pixel_height: int = (tile_size * height) + (final_spacing * maxi(height - 1, 0))
		if float(pixel_width) <= available_width and float(pixel_height) <= available_height:
			break
		tile_size -= 1
		final_spacing = _get_tile_spacing(tile_size)
	return tile_size

func _get_tile_spacing(tile_size: int) -> int:
	if tile_size <= 24:
		return 1
	if tile_size <= 32:
		return 2
	return 3

func _build_clues() -> void:
	_clear_children(clue_list)
	clue_labels = {}
	clue_texts = {}
	var index: int = 1
	for word_data in game_state.placed_words:
		var entry: WordEntry = word_data["entry"]
		var label: Button = Button.new()
		var hidden_text: String = str(index)
		var hint_text: String = "%d. %s" % [index, entry.meaning]
		label.text = hidden_text
		var clue_size: int = _scaled(40, layout_scale)
		label.custom_minimum_size = Vector2(clue_size, clue_size)
		label.focus_mode = Control.FOCUS_ALL
		_apply_clue_button_base_theme(label)
		label.pressed.connect(_on_clue_pressed.bind(word_data["id"]))
		clue_list.add_child(label)
		clue_labels[word_data["id"]] = label
		clue_texts[word_data["id"]] = {"hidden": hidden_text, "hint": hint_text}
		index += 1
	_update_clue_title()

func _build_keyboard() -> void:
	pass

func _build_diacritics() -> void:
	pass

func _update_status() -> void:
	if game_state == null:
		status_label.text = ""
		return
	var completed: int = game_state.count_completed()
	var total: int = game_state.placed_words.size()
	status_label.text = "Đã đúng %d/%d từ | Điểm: %d | Kỷ lục: %d" % [completed, total, game_state.score, best_score]
	if game_state.is_complete():
		status_label.text = "Hoàn thành!"
		_show_completion_card()
	_update_stats()

func refresh_clues() -> void:
	if game_state == null:
		return
	_update_clue_title()
	for word_data in game_state.placed_words:
		var word_id: int = word_data["id"]
		var label: Button = clue_labels.get(word_id, null)
		if label == null:
			continue
		var text_data: Dictionary = {}
		var raw_text_data: Variant = clue_texts.get(word_id, {})
		if typeof(raw_text_data) == TYPE_DICTIONARY:
			text_data = raw_text_data
		var hidden_text: String = String(text_data.get("hidden", label.text))
		var completed: bool = bool(word_data.get("completed", false))
		if completed:
			label.text = "%s ✓" % hidden_text
			_set_clue_style(label, COLOR_SUCCESS, Color(0.04, 0.27, 0.17, 1))
		elif word_id == input_controller.active_word_id:
			label.text = hidden_text
			_set_clue_style(label, COLOR_PRIMARY, Color(0.02, 0.20, 0.26, 1))
		else:
			label.text = hidden_text
			_clear_clue_style(label)

	if game_state != null and game_state.is_complete() and not completion_revealed:
		_show_completion_card()

func _update_board_title() -> void:
	if game_state == null or game_state.level_title == "":
		board_title.text = "Bảng chữ"
		return
	board_title.text = "Bảng chữ - %s (%s)" % [game_state.level_title, game_state.level_difficulty]

func _on_tile_pressed(pos: Vector2i) -> void:
	if is_paused:
		return
	input_controller.select_tile(pos)
	_start_selected_word_timer()
	refresh_clues()
	_update_guess_placeholder()

func _on_clue_pressed(word_id: int) -> void:
	if is_paused:
		return
	input_controller.select_word(word_id)
	_start_selected_word_timer()
	guess_input.text = ""
	refresh_all_tiles()
	refresh_clues()
	_update_guess_placeholder()

func _on_letter_button_pressed(letter: String) -> void:
	input_controller.apply_letter(letter)

func _on_tone_pressed(tone: int) -> void:
	input_controller.apply_tone(tone)

func _on_check_pressed() -> void:
	game_state.check_all_words()
	refresh_all_tiles()
	refresh_clues()
	_update_status()

func _on_replay_pressed() -> void:
	emit_signal("start_new_game_requested")

func _on_menu_pressed() -> void:
	if is_paused:
		pause_overlay.visible = false
		is_paused = false
	emit_signal("back_to_menu_requested")

func _on_pause_continue_pressed() -> void:
	_resume_game()

func _on_win_replay_pressed() -> void:
	emit_signal("start_new_game_requested")

func _on_win_menu_pressed() -> void:
	emit_signal("back_to_menu_requested")

func _on_hint_letter_pressed() -> void:
	if is_paused:
		return
	if not _apply_hint("letter"):
		status_label.text = "Hãy chọn gợi ý"

func _on_hint_word_pressed() -> void:
	if is_paused:
		return
	if not _apply_hint("word"):
		status_label.text = "Hãy chọn gợi ý"

func _on_guess_submitted(_text: String) -> void:
	_on_guess_pressed()

func _on_guess_pressed() -> void:
	if game_state == null or is_paused:
		return
	var word_id: int = input_controller.active_word_id
	if word_id < 0:
		status_label.text = "Hãy chọn gợi ý"
		return
	var guess: String = guess_input.text.strip_edges()
	if guess == "":
		status_label.text = "Hãy nhập từ đoán"
		guess_input.grab_focus()
		return
	var word_data: Variant = game_state.get_word_data(word_id)
	if word_data == null:
		status_label.text = "Không tìm thấy gợi ý đang chọn"
		return
	var entry: WordEntry = word_data["entry"]
	var correct: bool = VietnameseNormalizer.matches_answer(guess, entry.word)
	if correct:
		var earned_score: int = game_state.award_score_for_word(word_id)
		game_state.record_guess(word_id, guess, correct, earned_score)
		game_state.reveal_word(word_id)
		game_state.pause_active_word_timer()
		guess_input.text = ""
		refresh_all_tiles()
		refresh_clues()
		_update_status()
		status_label.text = "Đúng rồi! +%d điểm" % earned_score
		_refresh_history()
	else:
		game_state.record_guess(word_id, guess, correct)
		status_label.text = "Chưa đúng, thử lại"
		_update_stats()
		_update_time_label()
		_refresh_history()

func _update_guess_placeholder() -> void:
	if game_state == null:
		return
	var word_id: int = input_controller.active_word_id
	if word_id < 0:
		guess_input.placeholder_text = "Nhập từ đoán"
		return
	var word_data: Variant = game_state.get_word_data(word_id)
	if word_data == null:
		guess_input.placeholder_text = "Nhập từ đoán"
		return
	var entry: WordEntry = word_data["entry"]
	guess_input.placeholder_text = "Nhập từ (%d chữ)" % entry.length

func _apply_hint(kind: String) -> bool:
	if game_state == null:
		return false
	var word_id: int = input_controller.active_word_id
	if word_id < 0:
		return false
	var cost: int = _get_hint_cost(kind)
	if total_stars < cost:
		status_label.text = "Không đủ sao để dùng gợi ý (%d sao)" % cost
		return false
	if not SaveManager.spend_stars(cost):
		status_label.text = "Không đủ sao để dùng gợi ý (%d sao)" % cost
		return false
	total_stars -= cost
	_update_star_display(true)
	var changed: bool = false
	var hint_message: String = ""
	if kind == "letter":
		var letter_result: Dictionary = _apply_letter_hint(word_id)
		changed = bool(letter_result.get("changed", false))
		hint_message = String(letter_result.get("message", ""))
		if changed:
			game_state.mark_hinted_letter(word_id)
	elif kind == "word":
		changed = game_state.reveal_word(word_id)
		if changed:
			game_state.mark_hinted_word(word_id)
			game_state.pause_active_word_timer()
	if not changed:
		SaveManager.add_stars(cost)
		total_stars += cost
		_update_star_display(true)
		return false
	refresh_all_tiles()
	refresh_clues()
	_update_status()
	if hint_message != "":
		status_label.text = hint_message
	return true

func _get_hint_cost(kind: String) -> int:
	if kind == "word":
		return HINT_WORD_COST
	return HINT_LETTER_COST

func _apply_letter_hint(word_id: int) -> Dictionary:
	var word_data: Variant = game_state.get_word_data(word_id)
	if word_data == null:
		return {"changed": false, "message": ""}
	var entry: WordEntry = word_data["entry"]
	var start: Vector2i = Vector2i(word_data["start"])
	var dir: Vector2i = Vector2i(word_data["dir"])
	var positions: Array[Vector2i] = []
	for i in range(entry.length):
		var pos: Vector2i = start + dir * i
		var cell: Variant = game_state.get_tile(pos)
		if cell == null:
			continue
		if String(cell.get("input_char", "")) == cell["original_char"]:
			continue
		positions.append(pos)
	if positions.is_empty():
		return {"changed": false, "message": ""}
	rng.randomize()
	var reveal_pos: Vector2i = positions[0]
	var mode: int = rng.randi_range(0, 2)
	var message: String = ""
	if mode == 0:
		reveal_pos = positions[0]
		message = "Đã mở chữ đầu"
	elif mode == 1:
		reveal_pos = positions[rng.randi_range(0, positions.size() - 1)]
		message = "Đã mở một chữ ngẫu nhiên"
	else:
		var middle_index: int = int(positions.size() / 2)
		reveal_pos = positions[middle_index]
		message = "Đã mở chữ ở giữa"
	var cell_to_reveal: Variant = game_state.get_tile(reveal_pos)
	if cell_to_reveal == null:
		return {"changed": false, "message": ""}
	cell_to_reveal["input_char"] = cell_to_reveal["original_char"]
	cell_to_reveal["is_filled"] = true
	cell_to_reveal["is_correct"] = true
	game_state.check_word(word_id)
	return {"changed": true, "message": message}

func _update_clue_title() -> void:
	if game_state == null:
		return
	var word_id: int = input_controller.active_word_id
	if word_id < 0:
		clue_title.text = "Chọn số để xem gợi ý (%d)" % game_state.placed_words.size()
		return
	var text_data: Dictionary = {}
	var raw_text_data: Variant = clue_texts.get(word_id, {})
	if typeof(raw_text_data) == TYPE_DICTIONARY:
		text_data = raw_text_data
	clue_title.text = String(text_data.get("hint", "Gợi ý (%d)" % game_state.placed_words.size()))

func _update_stats() -> void:
	if game_state == null:
		stats_label.text = ""
		return
	if not completion_revealed:
		stats_label.text = _get_mission_summary_text()
		completion_bar.value = 0
		accuracy_bar.value = 0
		return
	var completed: int = game_state.count_completed()
	var total: int = game_state.placed_words.size()
	var attempts: int = game_state.guess_attempts
	var correct: int = game_state.guess_correct
	var accuracy: String = "--"
	if attempts > 0:
		var percent: int = int(round(float(correct) / float(attempts) * 100.0))
		accuracy = "%d%% (%d/%d)" % [percent, correct, attempts]
	stats_label.text = "Hoàn thành: %d/%d | Tỉ lệ đúng: %s\n%s" % [completed, total, accuracy, _get_mission_summary_text()]
	var completion_percent: int = 0
	if total > 0:
		completion_percent = int(round(float(completed) / float(total) * 100.0))
	completion_bar.value = completion_percent
	accuracy_bar.value = 0 if attempts == 0 else int(round(float(correct) / float(attempts) * 100.0))

func _update_time_label() -> void:
	if game_state == null:
		time_label.text = ""
		return
	var seconds: int = game_state.get_elapsed_seconds()
	var minutes: int = int(seconds / 60)
	var remain: int = int(seconds % 60)
	time_label.text = "Thời gian: %02d:%02d" % [minutes, remain]

func _show_play_widgets(visible_state: bool) -> void:
	if not visible_state:
		stats_label.text = ""
		time_label.text = ""
		completion_card.visible = false

func _pause_game() -> void:
	if is_paused or game_state == null or win_overlay.visible:
		return
	is_paused = true
	game_state.pause_clock()
	_update_time_label()
	pause_overlay.visible = true
	pause_popup.scale = Vector2(0.96, 0.96)
	pause_popup.pivot_offset = pause_popup.size * 0.5
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(pause_popup, "scale", Vector2.ONE, 0.16)
	pause_continue_button.grab_focus()

func _resume_game() -> void:
	if not is_paused or game_state == null:
		return
	is_paused = false
	pause_overlay.visible = false
	game_state.resume_clock()
	_start_selected_word_timer()
	last_time_second = -1
	_update_time_label()

func _apply_ui_theme() -> void:
	board_card.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL, 20))
	control_card.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_ALT, 20))
	completion_card.add_theme_stylebox_override("panel", _make_panel_style(COLOR_PANEL_ALT, 18))
	win_popup.add_theme_stylebox_override("panel", GameUITheme.make_menu_panel_style())
	pause_popup.add_theme_stylebox_override("panel", _make_pause_popup_style())
	star_hud.add_theme_stylebox_override("panel", _make_star_hud_style())
	star_icon.texture = _make_star_texture(30)

	for label in [board_title, clue_title, guess_title, status_label, stats_label, completion_title, win_title, win_summary, win_stats, pause_title, star_count_label]:
		label.add_theme_color_override("font_color", COLOR_INK)
	board_title.add_theme_font_size_override("font_size", 23)
	clue_title.add_theme_font_size_override("font_size", 19)
	guess_title.add_theme_font_size_override("font_size", 14)
	guess_title.add_theme_color_override("font_color", COLOR_MUTED)
	stats_label.add_theme_color_override("font_color", COLOR_MUTED)
	stats_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", COLOR_PRIMARY_DARK)
	status_label.add_theme_font_size_override("font_size", 15)
	time_label.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1))
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pause_title.add_theme_font_size_override("font_size", 23)
	star_count_label.add_theme_font_size_override("font_size", 20)
	star_count_label.add_theme_color_override("font_color", Color(0.98, 0.55, 0.04, 1))
	win_title.add_theme_font_size_override("font_size", 26)
	win_summary.add_theme_font_size_override("font_size", 16)

	var primary_button: StyleBoxFlat = _make_button_style(COLOR_PRIMARY, COLOR_PRIMARY_DARK)
	var secondary_button: StyleBoxFlat = _make_button_style(COLOR_SECONDARY, COLOR_SECONDARY_BORDER)
	var warning_button: StyleBoxFlat = GameUITheme.make_warning_button_style()
	_apply_button_theme(guess_button, primary_button, Color(1, 1, 1, 1))
	_apply_button_theme(win_replay_button, primary_button, Color(1, 1, 1, 1))
	_apply_button_theme(pause_continue_button, primary_button, Color(1, 1, 1, 1))
	for button in [replay_button, menu_button, win_menu_button]:
		_apply_button_theme(button, secondary_button, COLOR_INK)
	for button in [hint_letter_button, hint_word_button]:
		_apply_button_theme(button, warning_button, Color(0.25, 0.14, 0.02, 1))

	var input_style: StyleBoxFlat = GameUITheme.make_input_style()
	guess_input.add_theme_stylebox_override("normal", input_style)
	var input_focus_style: StyleBoxFlat = input_style.duplicate() as StyleBoxFlat
	input_focus_style.set_border_width_all(2)
	input_focus_style.border_color = COLOR_FOCUS
	guess_input.add_theme_stylebox_override("focus", input_focus_style)
	guess_input.add_theme_color_override("font_color", COLOR_INK)
	guess_input.add_theme_color_override("font_placeholder_color", Color(0.45, 0.53, 0.60, 1))
	guess_input.add_theme_font_size_override("font_size", 16)

	var progress_fill: StyleBoxFlat = _make_bar_style(COLOR_SUCCESS)
	var progress_bg: StyleBoxFlat = _make_bar_style(Color(0.78, 0.84, 0.86, 1))
	for bar in [completion_bar, accuracy_bar, win_progress]:
		bar.add_theme_stylebox_override("fill", progress_fill)
		bar.add_theme_stylebox_override("background", progress_bg)

	for button in [menu_button, replay_button, hint_letter_button, hint_word_button, guess_button, win_replay_button, win_menu_button, pause_continue_button]:
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size.y = 44
	guess_button.custom_minimum_size.x = 74
	time_label.custom_minimum_size.x = 118
	guess_input.custom_minimum_size.y = 44
	completion_bar.custom_minimum_size.y = 10
	accuracy_bar.custom_minimum_size.y = 10
	win_progress.custom_minimum_size.y = 10
	clue_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _make_panel_style(color: Color, radius: int = 18) -> StyleBoxFlat:
	return GameUITheme.make_panel_style(color, radius)

func _make_button_style(color: Color, border_color: Color, radius: int = 14) -> StyleBoxFlat:
	return GameUITheme.make_button_style(color, border_color, radius)

func _make_bar_style(color: Color) -> StyleBoxFlat:
	return GameUITheme.make_bar_style(color)

func _make_pause_popup_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = GameUITheme.make_menu_panel_style()
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style

func _make_star_hud_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = GameUITheme.make_button_style(Color(0.95, 0.98, 0.93, 0.92), Color(0.74, 0.86, 0.81, 1), 10)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _apply_button_theme(button: Button, normal_style: StyleBoxFlat, text_color: Color) -> void:
	GameUITheme.apply_button_theme(button, normal_style, text_color, 14)

func _apply_responsive_layout() -> void:
	if not is_instance_valid(margin_container):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	layout_scale = _get_ui_scale()
	var edge_margin: int = 16
	if viewport_size.x >= 1000:
		edge_margin = _scaled(28, layout_scale)
	elif viewport_size.x <= 760:
		edge_margin = _scaled(10, layout_scale)
	else:
		edge_margin = _scaled(16, layout_scale)
	margin_container.add_theme_constant_override("margin_left", edge_margin)
	margin_container.add_theme_constant_override("margin_top", edge_margin)
	margin_container.add_theme_constant_override("margin_right", edge_margin)
	margin_container.add_theme_constant_override("margin_bottom", edge_margin)
	root_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var is_narrow: bool = viewport_size.x <= 760.0
	root_hbox.vertical = is_narrow
	root_vbox.add_theme_constant_override("separation", _scaled(14 if viewport_size.y >= 680 else 10, layout_scale))
	root_hbox.add_theme_constant_override("separation", _scaled(18 if viewport_size.x >= 960 else 12, layout_scale))
	left_column.add_theme_constant_override("separation", _scaled(12, layout_scale))
	right_column.add_theme_constant_override("separation", _scaled(12, layout_scale))
	if is_narrow:
		left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		board_card.custom_minimum_size.y = _scaled(230, layout_scale)
		right_column.custom_minimum_size.x = 0
	else:
		left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		board_card.custom_minimum_size.y = 0
		var min_right_width: float = 280.0 if viewport_size.x < 900.0 else 320.0
		right_column.custom_minimum_size.x = clampf(viewport_size.x * 0.30, min_right_width * layout_scale, 390.0 * layout_scale)
	board_box.add_theme_constant_override("separation", _scaled(14 if not is_narrow else 10, layout_scale))
	clue_list.add_theme_constant_override("h_separation", _scaled(8, layout_scale))
	clue_list.add_theme_constant_override("v_separation", _scaled(8, layout_scale))
	board_title.add_theme_font_size_override("font_size", _scaled(23, layout_scale))
	clue_title.add_theme_font_size_override("font_size", _scaled(19, layout_scale))
	guess_title.add_theme_font_size_override("font_size", _scaled(14, layout_scale))
	status_label.add_theme_font_size_override("font_size", _scaled(15, layout_scale))
	stats_label.add_theme_font_size_override("font_size", _scaled(14, layout_scale))
	time_label.add_theme_font_size_override("font_size", _scaled(16, layout_scale))
	star_hud.custom_minimum_size = Vector2(_scaled(72, layout_scale), _scaled(44, layout_scale))
	star_icon.custom_minimum_size = Vector2(_scaled(22, layout_scale), _scaled(22, layout_scale))
	star_count_label.add_theme_font_size_override("font_size", _scaled(20, layout_scale))
	pause_title.add_theme_font_size_override("font_size", _scaled(23, layout_scale))
	win_title.add_theme_font_size_override("font_size", _scaled(26, layout_scale))
	win_summary.add_theme_font_size_override("font_size", _scaled(16, layout_scale))
	for button in [menu_button, replay_button, hint_letter_button, hint_word_button, guess_button, win_replay_button, win_menu_button, pause_continue_button]:
		button.custom_minimum_size.y = _scaled(44, layout_scale)
	guess_button.custom_minimum_size.x = _scaled(74, layout_scale)
	time_label.custom_minimum_size.x = _scaled(118, layout_scale)
	guess_input.custom_minimum_size.y = _scaled(44, layout_scale)
	completion_bar.custom_minimum_size.y = _scaled(10, layout_scale)
	accuracy_bar.custom_minimum_size.y = _scaled(10, layout_scale)
	win_progress.custom_minimum_size.y = _scaled(10, layout_scale)

func _refresh_responsive_board() -> void:
	_apply_responsive_layout()
	if game_state != null:
		_apply_board_layout()

func _get_ui_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	var width_scale: float = viewport_size.x / 1280.0
	var height_scale: float = viewport_size.y / 720.0
	return clampf(minf(width_scale, height_scale), 0.78, 1.20)

func _scaled(value: int, ui_scale: float) -> int:
	return int(round(float(value) * ui_scale))

func _show_completion_card() -> void:
	if completion_revealed:
		return
	completion_revealed = true
	_update_best_score()
	var earned_stars: int = _award_mission_stars()
	completion_card.visible = false
	_show_play_widgets(true)
	_update_stats()
	win_overlay.visible = true
	win_summary.text = "Bạn đạt %d/3 sao nhiệm vụ." % game_state.get_mission_star_count()
	var completed: int = game_state.count_completed()
	var total: int = game_state.placed_words.size()
	var attempts: int = game_state.guess_attempts
	var correct: int = game_state.guess_correct
	var accuracy: int = 0
	if attempts > 0:
		accuracy = int(round(float(correct) / float(attempts) * 100.0))
	win_stats.text = "Điểm %d | +%d sao | Tổng sao %d | Kỷ lục %d | Đúng %d/%d từ | Tỉ lệ đúng %d%% | Thời gian %s\n%s" % [game_state.score, earned_stars, total_stars, best_score, completed, total, accuracy, time_label.text.replace("Thời gian: ", ""), _get_mission_summary_text()]
	win_progress.value = 100.0
	win_overlay.modulate = Color(1, 1, 1, 0)
	win_popup.scale = Vector2(0.92, 0.92)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(win_overlay, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.parallel().tween_property(win_popup, "scale", Vector2(1, 1), 0.22)

func _play_intro_animation() -> void:
	modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)

func _set_clue_style(button: Button, border_color: Color, text_color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = border_color.lightened(0.68)
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = border_color
	style.shadow_color = Color(0.01, 0.08, 0.09, 0.10)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover_style.bg_color = style.bg_color.lightened(0.05)
	var pressed_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = style.bg_color.darkened(0.05)
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 1)
	var focus_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	focus_style.border_color = COLOR_FOCUS
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus_style)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)

func _clear_clue_style(button: Button) -> void:
	_apply_clue_button_base_theme(button)

func _apply_clue_button_base_theme(button: Button) -> void:
	var style: StyleBoxFlat = _make_button_style(Color(0.98, 1.0, 0.96, 1), Color(0.64, 0.73, 0.78, 1), 10)
	_apply_button_theme(button, style, COLOR_INK)

func _refresh_history() -> void:
	if game_state == null:
		return
	_clear_children(history_list)
	var history: Array[Dictionary] = game_state.guess_history
	for i in range(history.size() - 1, -1, -1):
		var item: Variant = history[i]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var time_sec: int = int(item.get("time", 0))
		var minutes: int = int(time_sec / 60)
		var remain: int = int(time_sec % 60)
		var time_text: String = "%02d:%02d" % [minutes, remain]
		var word: String = String(item.get("word", ""))
		var guess: String = String(item.get("guess", ""))
		var correct: bool = bool(item.get("correct", false))
		var result_text: String = "Đúng" if correct else "Sai"
		var earned_score: int = int(item.get("score", 0))
		var label: Label = Label.new()
		label.text = "%s | %s | %s | %s | +%d" % [time_text, word, guess, result_text, earned_score]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", Color(0.18, 0.25, 0.30, 1))
		label.add_theme_font_size_override("font_size", 13)
		history_list.add_child(label)

func _start_selected_word_timer() -> void:
	if game_state == null:
		return
	game_state.select_word_timer(input_controller.active_word_id)

func _update_best_score() -> void:
	if game_state == null or game_state.score <= best_score:
		return
	best_score = game_state.score
	SaveManager.save_best_score(best_score)

func _award_mission_stars() -> int:
	if game_state == null or game_state.stars_awarded:
		return 0
	var earned: int = game_state.get_mission_star_count()
	if earned > 0:
		SaveManager.add_stars(earned)
		total_stars += earned
		_update_star_display(true)
	SaveManager.add_played_game()
	game_state.stars_awarded = true
	SaveManager.record_level_completion(game_state.level_id, earned, game_state.score, game_state.get_elapsed_seconds())
	return earned

func _update_star_display(animate: bool = true) -> void:
	if not is_instance_valid(star_count_label):
		return
	star_count_label.text = str(total_stars)
	if not animate or displayed_stars == total_stars or not is_instance_valid(star_hud):
		displayed_stars = total_stars
		return
	displayed_stars = total_stars
	star_hud.pivot_offset = star_hud.size * 0.5
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(star_hud, "scale", Vector2(1.08, 1.08), 0.10)
	tween.tween_property(star_hud, "scale", Vector2.ONE, 0.16)

func _make_star_texture(size: int) -> Texture2D:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center: Vector2 = Vector2(size * 0.5, size * 0.5)
	var outline: PackedVector2Array = _make_star_points(center, size * 0.47, size * 0.21)
	var fill: PackedVector2Array = _make_star_points(center, size * 0.40, size * 0.18)
	for y in range(size):
		for x in range(size):
			var point: Vector2 = Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(point, outline):
				image.set_pixel(x, y, Color(0.82, 0.43, 0.02, 1))
			if Geometry2D.is_point_in_polygon(point, fill):
				var shine: float = 1.0 - clampf(point.distance_to(Vector2(size * 0.34, size * 0.32)) / float(size), 0.0, 0.45)
				image.set_pixel(x, y, Color(1.0, 0.70 + shine * 0.18, 0.10, 1))
	return ImageTexture.create_from_image(image)

func _make_star_points(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(10):
		var radius: float = outer_radius if i % 2 == 0 else inner_radius
		var angle: float = -PI * 0.5 + float(i) * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _get_mission_summary_text() -> String:
	if game_state == null or game_state.missions.is_empty():
		return ""
	var lines: Array[String] = []
	for mission in game_state.missions:
		var mark: String = "✓" if game_state.is_mission_complete(mission) else "•"
		var text: String = String(mission.get("text", ""))
		var progress: String = game_state.get_mission_progress_text(mission)
		if progress != "":
			lines.append("%s %s (%s)" % [mark, text, progress])
		else:
			lines.append("%s %s" % [mark, text])
	return "\n".join(lines)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
