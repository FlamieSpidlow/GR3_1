class_name InputController
extends Node

var ui: UIController
var state: GameState
var selected_pos: Vector2i = Vector2i(-1, -1)
var active_word_id: int = -1
var active_dir: Vector2i = Vector2i(1, 0)

func setup(ui_controller: UIController, game_state: GameState) -> void:
	ui = ui_controller
	state = game_state
	selected_pos = state.get_first_filled_pos()
	if selected_pos.x >= 0:
		_set_active_word_from_tile(selected_pos)
		ui.refresh_all_tiles()
		ui.refresh_clues()

func select_tile(pos: Vector2i) -> void:
	if state == null:
		return
	var cell: Variant = state.get_tile(pos)
	if cell == null:
		return
	selected_pos = pos
	_set_active_word_from_tile(pos)
	ui.refresh_all_tiles()
	ui.refresh_clues()

func select_word(word_id: int) -> void:
	if state == null:
		return
	var word_data: Variant = state.get_word_data(word_id)
	if word_data == null:
		return
	active_word_id = word_id
	active_dir = Vector2i(word_data["dir"])
	selected_pos = Vector2i(word_data["start"])

func apply_letter(_letter: String) -> void:
	pass

func apply_tone(_tone: int) -> void:
	pass

func clear_selected() -> void:
	pass

func _set_active_word_from_tile(pos: Vector2i) -> void:
	if state == null:
		active_word_id = -1
		return
	var cell: Variant = state.get_tile(pos)
	if cell == null:
		active_word_id = -1
		return
	var word_ids: Array = cell.get("word_ids", [])
	if word_ids.is_empty():
		active_word_id = -1
		return
	if word_ids.has(active_word_id):
		var idx: int = word_ids.find(active_word_id)
		active_word_id = word_ids[(idx + 1) % word_ids.size()]
	else:
		active_word_id = word_ids[0]
	var word_data: Variant = state.get_word_data(active_word_id)
	if word_data != null:
		active_dir = Vector2i(word_data["dir"])

func _unhandled_input(_event: InputEvent) -> void:
	pass
