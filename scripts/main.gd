extends Control

@onready var start_menu: Control = $StartMenu
@onready var game_board: UIController = $GameBoard
@onready var menu_card: PanelContainer = $StartMenu/CenterContainer/Card
@onready var menu_content_margin: MarginContainer = $StartMenu/CenterContainer/Card/ContentMargin
@onready var menu_vbox: VBoxContainer = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer
@onready var menu_title: Label = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/TitleLabel
@onready var menu_subtitle: Label = get_node_or_null("StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/SubtitleLabel") as Label
@onready var account_row: HBoxContainer = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/AccountRow
@onready var account_label: Label = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/AccountRow/AccountLabel
@onready var account_option: OptionButton = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/AccountRow/AccountOption
@onready var add_account_button: Button = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/AccountRow/AddAccountButton
@onready var delete_account_button: Button = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/AccountRow/DeleteAccountButton
@onready var topic_row: HBoxContainer = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/TopicRow
@onready var menu_topic_label: Label = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/TopicRow/TopicLabel
@onready var topic_option: OptionButton = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/TopicRow/TopicOption
@onready var button_container: VBoxContainer = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/ButtonContainer
@onready var quit_button: Button = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/ButtonContainer/QuitButton
@onready var play_button: Button = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/ButtonContainer/StartButton
@onready var help_button: Button = $StartMenu/CenterContainer/Card/ContentMargin/VBoxContainer/ButtonContainer/HelpButton
@onready var top_back_button: Button = $StartMenu/TopBackButton

const FONT_PATH := "res://assets/fonts/NotoSans-Regular.ttf"
const COLOR_INK := GameUITheme.INK
const COLOR_MUTED := GameUITheme.MUTED
const COLOR_PRIMARY := GameUITheme.PRIMARY
const COLOR_PRIMARY_DARK := GameUITheme.PRIMARY_DARK
const COLOR_SECONDARY := GameUITheme.SECONDARY
const COLOR_SECONDARY_BORDER := GameUITheme.SECONDARY_BORDER
const COLOR_PANEL := GameUITheme.PANEL
const COLOR_PANEL_ALT := GameUITheme.PANEL_ALT
const COLOR_DANGER := GameUITheme.DANGER
const COLOR_SUCCESS := GameUITheme.SUCCESS
const COLOR_SUCCESS_SOFT := GameUITheme.SUCCESS_SOFT

enum MenuMode { MAIN, TOPICS }

var board_generator: BoardGenerator = BoardGenerator.new()
var themed_level_provider: ThemedLevelProvider = ThemedLevelProvider.new()
var mode: int = MenuMode.MAIN
var selected_topic_index: int = 0
var selected_stage_index: int = 0
var stage_overlay: Control
var stage_card: PanelContainer
var stage_title: Label
var stage_summary: Label
var stage_list: VBoxContainer
var stage_close_button: Button
var help_overlay: Control
var help_card: PanelContainer
var help_title: Label
var help_body: Label
var help_close_button: Button
var account_manager_overlay: Control
var account_manager_option: OptionButton
var account_manager_add_button: Button
var account_manager_delete_button: Button
var account_manager_close_button: Button
var account_overlay: Control
var account_name_input: LineEdit
var account_error_label: Label
var account_create_button: Button
var account_cancel_button: Button
var delete_account_overlay: Control
var delete_account_message: Label
var delete_account_confirm_button: Button
var delete_account_cancel_button: Button

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	help_button.pressed.connect(_show_help_popup)
	quit_button.pressed.connect(_on_secondary_pressed)
	top_back_button.pressed.connect(_on_back_menu_pressed)
	account_option.item_selected.connect(_on_account_selected)
	add_account_button.pressed.connect(_show_account_manager_popup)
	delete_account_button.pressed.connect(_show_delete_account_popup)
	topic_option.item_selected.connect(_on_topic_selected)
	game_board.start_new_game_requested.connect(_on_replay_requested)
	game_board.back_to_menu_requested.connect(_on_back_to_menu_requested)
	top_back_button.text = "Quay lại"
	start_menu.visible = true
	game_board.visible = false
	_create_stage_popup()
	_create_help_popup()
	_create_account_manager_popup()
	_create_account_popup()
	_create_delete_account_popup()
	_setup_theme_options()
	_refresh_account_options()
	_apply_menu_theme()
	_apply_optional_font()
	_show_main_menu()
	_apply_responsive_layout()
	_setup_focus_navigation()
	play_button.grab_focus()
	call_deferred("_play_menu_intro")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()

func _on_play_pressed() -> void:
	if mode == MenuMode.MAIN:
		_show_topic_picker()
		return
	_show_stage_popup(topic_option.get_selected_id())

func _on_secondary_pressed() -> void:
	get_tree().quit()

func _on_back_menu_pressed() -> void:
	_show_main_menu()

func _on_account_selected(index: int) -> void:
	SaveManager.select_profile(String(account_option.get_item_metadata(index)))
	_refresh_account_options()
	_refresh_topic_options()

func _on_account_manager_selected(index: int) -> void:
	if not is_instance_valid(account_manager_option):
		return
	SaveManager.select_profile(String(account_manager_option.get_item_metadata(index)))
	_refresh_account_options()
	_refresh_topic_options()

func _on_topic_selected(index: int) -> void:
	selected_topic_index = index
	_refresh_topic_subtitle()

func _on_replay_requested() -> void:
	_start_stage_game(selected_topic_index, selected_stage_index)

func _on_back_to_menu_requested() -> void:
	start_menu.visible = true
	game_board.visible = false
	_show_topic_picker()
	_refresh_topic_options()
	topic_option.select(clampi(selected_topic_index, 0, maxi(topic_option.get_item_count() - 1, 0)))
	selected_topic_index = topic_option.get_selected_id()
	_refresh_topic_subtitle()
	call_deferred("_play_menu_intro")

func _start_stage_game(topic_index: int, stage_index: int) -> void:
	var result: Dictionary = themed_level_provider.create_stage_level(topic_index, stage_index, board_generator)
	if result.is_empty():
		push_error("No playable stage selected")
		return
	var board: Dictionary = {}
	var level: Dictionary = {}
	var raw_board: Variant = result.get("board", {})
	var raw_level: Variant = result.get("level", {})
	if typeof(raw_board) == TYPE_DICTIONARY:
		board = raw_board
	if typeof(raw_level) == TYPE_DICTIONARY:
		level = raw_level
	if board.is_empty() or level.is_empty():
		push_error("Invalid stage data")
		return
	selected_topic_index = topic_index
	selected_stage_index = stage_index
	var state: GameState = GameState.new()
	state.set_board(board)
	state.set_level_info(String(level["id"]), String(level["title"]), String(level["difficulty"]))
	game_board.setup_with_state(state)
	stage_overlay.visible = false
	start_menu.visible = false
	game_board.visible = true
	game_board.call_deferred("_refresh_responsive_board")

func _show_main_menu() -> void:
	mode = MenuMode.MAIN
	account_row.visible = true
	topic_row.visible = false
	stage_overlay.visible = false
	if is_instance_valid(account_manager_overlay):
		account_manager_overlay.visible = false
	top_back_button.visible = false
	menu_title.text = "Word Crossing Tiếng Việt"
	play_button.text = "Chơi"
	quit_button.text = "Thoát game"
	quit_button.visible = true
	_setup_focus_navigation()

func _show_topic_picker() -> void:
	mode = MenuMode.TOPICS
	account_row.visible = false
	topic_row.visible = true
	stage_overlay.visible = false
	if is_instance_valid(account_manager_overlay):
		account_manager_overlay.visible = false
	top_back_button.visible = true
	top_back_button.text = "Quay lại"
	start_menu.move_child(top_back_button, start_menu.get_child_count() - 1)
	menu_title.text = "Chọn chủ đề"
	play_button.text = "Chọn màn"
	quit_button.visible = false
	_refresh_topic_options()
	_refresh_topic_subtitle()
	_setup_focus_navigation()
	topic_option.grab_focus()

func _refresh_account_options() -> void:
	account_option.clear()
	if is_instance_valid(account_manager_option):
		account_manager_option.clear()
	var profiles: Array[Dictionary] = SaveManager.get_profiles()
	var selected_index: int = 0
	for i in range(profiles.size()):
		var profile: Dictionary = profiles[i]
		account_option.add_item(String(profile.get("name", "Người chơi")), i)
		account_option.set_item_metadata(i, String(profile.get("id", "")))
		if is_instance_valid(account_manager_option):
			account_manager_option.add_item(String(profile.get("name", "Người chơi")), i)
			account_manager_option.set_item_metadata(i, String(profile.get("id", "")))
		if bool(profile.get("current", false)):
			selected_index = i
	if profiles.is_empty():
		account_option.add_item("Người chơi", 0)
		account_option.set_item_metadata(0, SaveManager.DEFAULT_PROFILE_ID)
		if is_instance_valid(account_manager_option):
			account_manager_option.add_item("Người chơi", 0)
			account_manager_option.set_item_metadata(0, SaveManager.DEFAULT_PROFILE_ID)
	account_option.select(selected_index)
	if is_instance_valid(account_manager_option):
		account_manager_option.select(selected_index)
	if is_instance_valid(account_manager_delete_button):
		account_manager_delete_button.disabled = profiles.size() <= 1
	delete_account_button.disabled = profiles.size() <= 1

func _refresh_topic_options() -> void:
	var previous_id: int = topic_option.get_selected_id()
	topic_option.clear()
	var levels: Array[Dictionary] = themed_level_provider.build_levels(board_generator)
	for i in range(levels.size()):
		var level: Dictionary = levels[i]
		var stages: Array[Dictionary] = themed_level_provider.get_topic_stages(i)
		var summary: Dictionary = _get_topic_progress_summary(stages)
		topic_option.add_item("%s  %d/%d" % [String(level["title"]), int(summary.get("completed", 0)), stages.size()], i)
	if levels.is_empty():
		topic_option.add_item("Không có chủ đề hợp lệ", 0)
		topic_option.disabled = true
		play_button.disabled = true
		return
	topic_option.disabled = false
	play_button.disabled = false
	var select_id: int = previous_id if previous_id >= 0 else selected_topic_index
	topic_option.select(clampi(select_id, 0, levels.size() - 1))
	selected_topic_index = topic_option.get_selected_id()

func _refresh_topic_subtitle() -> void:
	var topic_index: int = topic_option.get_selected_id()
	var stages: Array[Dictionary] = themed_level_provider.get_topic_stages(topic_index)
	var summary: Dictionary = _get_topic_progress_summary(stages)

func _get_topic_progress_summary(stages: Array[Dictionary]) -> Dictionary:
	var completed_count: int = 0
	var star_count: int = 0
	for stage in stages:
		var progress: Dictionary = _get_stage_progress(stage)
		if bool(progress.get("completed", false)):
			completed_count += 1
		star_count += int(progress.get("stars", 0))
	return {"completed": completed_count, "stars": star_count}

func _get_stage_progress(stage: Dictionary) -> Dictionary:
	return SaveManager.get_level_progress(String(stage.get("id", "")))

func _create_stage_popup() -> void:
	stage_overlay = Control.new()
	stage_overlay.name = "StageOverlay"
	stage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_overlay.visible = false
	start_menu.add_child(stage_overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.03, 0.13, 0.15, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_overlay.add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_overlay.add_child(center)

	stage_card = PanelContainer.new()
	stage_card.custom_minimum_size = Vector2(420, 0)
	center.add_child(stage_card)

	var margin: MarginContainer = MarginContainer.new()
	stage_card.add_child(margin)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	stage_title = Label.new()
	stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_title.add_theme_font_size_override("font_size", 24)
	box.add_child(stage_title)

	stage_summary = Label.new()
	stage_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(stage_summary)

	stage_list = VBoxContainer.new()
	stage_list.add_theme_constant_override("separation", 10)
	box.add_child(stage_list)

	stage_close_button = Button.new()
	stage_close_button.text = "Đóng"
	stage_close_button.pressed.connect(_hide_stage_popup)
	box.add_child(stage_close_button)

func _create_help_popup() -> void:
	help_overlay = Control.new()
	help_overlay.name = "HelpOverlay"
	help_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_overlay.visible = false
	start_menu.add_child(help_overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.03, 0.13, 0.15, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_overlay.add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_overlay.add_child(center)

	help_card = PanelContainer.new()
	help_card.custom_minimum_size = Vector2(460, 0)
	center.add_child(help_card)

	var margin: MarginContainer = MarginContainer.new()
	help_card.add_child(margin)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 26)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	help_title = Label.new()
	help_title.text = "Hướng dẫn chơi"
	help_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help_title)

	help_body = Label.new()
	help_body.text = "1. Bấm Chơi, chọn chủ đề rồi chọn màn.\n2. Bấm số gợi ý để chọn câu hỏi đang giải.\n3. Nhập đáp án vào ô Từ đoán và bấm Đoán.\n4. Dùng sao để Lộ 1 chữ hoặc Lộ cả từ khi cần.\n5. Hoàn thành nhiệm vụ để nhận thêm sao."
	help_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(help_body)

	help_close_button = Button.new()
	help_close_button.text = "Đóng"
	help_close_button.pressed.connect(_hide_help_popup)
	box.add_child(help_close_button)

func _create_account_manager_popup() -> void:
	account_manager_overlay = Control.new()
	account_manager_overlay.name = "AccountManagerOverlay"
	account_manager_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	account_manager_overlay.visible = false
	start_menu.add_child(account_manager_overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.03, 0.13, 0.15, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	account_manager_overlay.add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	account_manager_overlay.add_child(center)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 0)
	card.add_theme_stylebox_override("panel", GameUITheme.make_menu_panel_style())
	center.add_child(card)

	var margin: MarginContainer = MarginContainer.new()
	card.add_child(margin)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = "Tài khoản"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_INK)
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	var description: Label = Label.new()
	description.text = "Chọn người chơi local để lưu tiến trình riêng."
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(description)

	account_manager_option = OptionButton.new()
	account_manager_option.custom_minimum_size.y = 44
	account_manager_option.item_selected.connect(_on_account_manager_selected)
	box.add_child(account_manager_option)

	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	box.add_child(action_row)

	account_manager_add_button = Button.new()
	account_manager_add_button.text = "Thêm"
	account_manager_add_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_manager_add_button.pressed.connect(_show_account_popup)
	action_row.add_child(account_manager_add_button)

	account_manager_delete_button = Button.new()
	account_manager_delete_button.text = "Xóa"
	account_manager_delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_manager_delete_button.pressed.connect(_show_delete_account_popup)
	action_row.add_child(account_manager_delete_button)

	account_manager_close_button = Button.new()
	account_manager_close_button.text = "Đóng"
	account_manager_close_button.pressed.connect(_hide_account_manager_popup)
	box.add_child(account_manager_close_button)

func _create_account_popup() -> void:
	account_overlay = Control.new()
	account_overlay.name = "AccountOverlay"
	account_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	account_overlay.visible = false
	start_menu.add_child(account_overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.03, 0.13, 0.15, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	account_overlay.add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	account_overlay.add_child(center)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 0)
	card.add_theme_stylebox_override("panel", GameUITheme.make_menu_panel_style())
	center.add_child(card)

	var margin: MarginContainer = MarginContainer.new()
	card.add_child(margin)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = "Thêm tài khoản"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_INK)
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	account_name_input = LineEdit.new()
	account_name_input.placeholder_text = "Tên người chơi"
	account_name_input.custom_minimum_size.y = 42
	account_name_input.text_submitted.connect(_on_account_name_submitted)
	box.add_child(account_name_input)

	account_error_label = Label.new()
	account_error_label.add_theme_color_override("font_color", Color(0.66, 0.16, 0.12, 1))
	account_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(account_error_label)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)

	account_cancel_button = Button.new()
	account_cancel_button.text = "Hủy"
	account_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_cancel_button.pressed.connect(_hide_account_popup)
	buttons.add_child(account_cancel_button)

	account_create_button = Button.new()
	account_create_button.text = "Tạo"
	account_create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	account_create_button.pressed.connect(_create_account_from_input)
	buttons.add_child(account_create_button)

func _create_delete_account_popup() -> void:
	delete_account_overlay = Control.new()
	delete_account_overlay.name = "DeleteAccountOverlay"
	delete_account_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	delete_account_overlay.visible = false
	start_menu.add_child(delete_account_overlay)

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.03, 0.13, 0.15, 0.48)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	delete_account_overlay.add_child(dim)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	delete_account_overlay.add_child(center)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 0)
	card.add_theme_stylebox_override("panel", GameUITheme.make_menu_panel_style())
	center.add_child(card)

	var margin: MarginContainer = MarginContainer.new()
	card.add_child(margin)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title: Label = Label.new()
	title.text = "Xóa tài khoản"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_INK)
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	delete_account_message = Label.new()
	delete_account_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	delete_account_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_account_message.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(delete_account_message)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)

	delete_account_cancel_button = Button.new()
	delete_account_cancel_button.text = "Hủy"
	delete_account_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_account_cancel_button.pressed.connect(_hide_delete_account_popup)
	buttons.add_child(delete_account_cancel_button)

	delete_account_confirm_button = Button.new()
	delete_account_confirm_button.text = "Xóa"
	delete_account_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_account_confirm_button.pressed.connect(_delete_selected_account)
	buttons.add_child(delete_account_confirm_button)

func _show_account_manager_popup() -> void:
	_refresh_account_options()
	account_manager_overlay.visible = true
	account_manager_option.grab_focus()

func _hide_account_manager_popup() -> void:
	account_manager_overlay.visible = false

func _show_account_popup() -> void:
	account_name_input.text = ""
	account_error_label.text = ""
	account_overlay.visible = true
	account_name_input.grab_focus()

func _hide_account_popup() -> void:
	account_overlay.visible = false

func _create_account_from_input() -> void:
	var profile_id: String = SaveManager.create_profile(account_name_input.text)
	if profile_id == "":
		account_error_label.text = "Nhập tên tài khoản trước."
		return
	_hide_account_popup()
	_refresh_account_options()
	_refresh_topic_options()

func _on_account_name_submitted(_text: String) -> void:
	_create_account_from_input()

func _show_delete_account_popup() -> void:
	var selected_index: int = account_option.get_selected_id()
	if delete_account_button.disabled or selected_index < 0:
		return
	delete_account_message.text = "Xóa tài khoản \"%s\" và toàn bộ tiến trình đã lưu?" % account_option.get_item_text(selected_index)
	delete_account_overlay.visible = true
	delete_account_cancel_button.grab_focus()

func _hide_delete_account_popup() -> void:
	delete_account_overlay.visible = false

func _show_help_popup() -> void:
	help_overlay.visible = true
	help_close_button.grab_focus()

func _hide_help_popup() -> void:
	help_overlay.visible = false
	if mode == MenuMode.TOPICS:
		topic_option.grab_focus()
	else:
		help_button.grab_focus()

func _delete_selected_account() -> void:
	var selected_index: int = account_option.get_selected_id()
	if selected_index < 0:
		_hide_delete_account_popup()
		return
	var profile_id: String = String(account_option.get_item_metadata(selected_index))
	if not SaveManager.delete_profile(profile_id):
		_hide_delete_account_popup()
		return
	_hide_delete_account_popup()
	_refresh_account_options()
	_refresh_topic_options()

func _hide_stage_popup() -> void:
	stage_overlay.visible = false
	top_back_button.visible = mode == MenuMode.TOPICS

func _show_stage_popup(topic_index: int) -> void:
	selected_topic_index = topic_index
	_clear_children(stage_list)
	var ui_scale: float = _get_ui_scale()
	var topic: Dictionary = themed_level_provider.get_topic(topic_index)
	var stages: Array[Dictionary] = themed_level_provider.get_topic_stages(topic_index)
	stage_title.text = String(topic.get("title", "Chủ đề"))
	for i in range(stages.size()):
		var stage: Dictionary = stages[i]
		var progress: Dictionary = _get_stage_progress(stage)
		var completed: bool = bool(progress.get("completed", false))
		var stars: int = int(progress.get("stars", 0))
		var button: Button = Button.new()
		button.custom_minimum_size.y = _scaled(48, ui_scale)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "Màn %d  •  %d từ  •  %s  %s" % [
			i + 1,
			int(stage.get("word_count", 0)),
			_get_star_text(stars),
			"Đã hoàn thành" if completed else "Chưa hoàn thành",
		]
		var stage_style: StyleBoxFlat = _make_button_style(COLOR_PANEL_ALT, COLOR_SECONDARY_BORDER)
		var stage_text_color: Color = COLOR_INK
		if completed:
			stage_style = _make_button_style(COLOR_SUCCESS_SOFT, COLOR_SUCCESS)
			stage_text_color = Color(0.04, 0.27, 0.17, 1)
		_apply_button_theme(button, stage_style, stage_text_color)
		button.pressed.connect(_start_stage_game.bind(topic_index, i))
		stage_list.add_child(button)
	top_back_button.visible = false
	stage_overlay.visible = true
	stage_close_button.grab_focus()

func _get_star_text(stars: int) -> String:
	var filled: String = ""
	for i in range(3):
		filled += "★" if i < stars else "☆"
	return filled

func _apply_optional_font() -> void:
	if not FileAccess.file_exists(FONT_PATH):
		return
	var font_res: Variant = load(FONT_PATH)
	if font_res == null:
		return
	if font_res is FontFile:
		var theme: Theme = Theme.new()
		theme.set_default_font(font_res)
		self.theme = theme

func _apply_menu_theme() -> void:
	menu_card.add_theme_stylebox_override("panel", _make_panel_style())
	menu_content_margin.add_theme_constant_override("margin_left", 30)
	menu_content_margin.add_theme_constant_override("margin_top", 30)
	menu_content_margin.add_theme_constant_override("margin_right", 30)
	menu_content_margin.add_theme_constant_override("margin_bottom", 30)
	menu_vbox.add_theme_constant_override("separation", 18)
	button_container.add_theme_constant_override("separation", 10)

	menu_title.add_theme_color_override("font_color", COLOR_INK)
	menu_title.add_theme_font_size_override("font_size", 36)
	account_label.text = "Tài khoản"
	account_label.add_theme_color_override("font_color", COLOR_INK)
	account_label.custom_minimum_size.x = 78
	menu_topic_label.text = "Chủ đề"
	menu_topic_label.add_theme_color_override("font_color", COLOR_INK)
	menu_topic_label.custom_minimum_size.x = 78

	var primary_button: StyleBoxFlat = _make_button_style(COLOR_PRIMARY, COLOR_PRIMARY_DARK)
	var secondary_button: StyleBoxFlat = _make_button_style(COLOR_SECONDARY, COLOR_SECONDARY_BORDER)
	var danger_button: StyleBoxFlat = GameUITheme.make_danger_button_style()
	_apply_button_theme(play_button, primary_button, Color(1, 1, 1, 1))
	_apply_button_theme(help_button, secondary_button, COLOR_INK)
	_apply_button_theme(quit_button, secondary_button, COLOR_INK)
	top_back_button.text = "Quay lại"
	_apply_button_theme(top_back_button, secondary_button, COLOR_INK)
	add_account_button.text = "Quản lý"
	delete_account_button.visible = false
	_apply_button_theme(add_account_button, secondary_button, COLOR_INK)
	_apply_button_theme(delete_account_button, danger_button, COLOR_DANGER)
	_apply_button_theme(account_option, secondary_button, COLOR_INK)
	_apply_button_theme(topic_option, secondary_button, COLOR_INK)
	_apply_option_popup_theme(account_option)
	_apply_option_popup_theme(topic_option)
	if is_instance_valid(account_manager_option):
		_apply_button_theme(account_manager_option, secondary_button, COLOR_INK)
		_apply_option_popup_theme(account_manager_option)
	if is_instance_valid(account_manager_add_button):
		_apply_button_theme(account_manager_add_button, primary_button, Color(1, 1, 1, 1))
	if is_instance_valid(account_manager_delete_button):
		_apply_button_theme(account_manager_delete_button, danger_button, COLOR_DANGER)
	if is_instance_valid(account_manager_close_button):
		_apply_button_theme(account_manager_close_button, secondary_button, COLOR_INK)
	account_option.custom_minimum_size.y = 44
	topic_option.custom_minimum_size.y = 44
	add_account_button.custom_minimum_size = Vector2(96, 44)
	delete_account_button.custom_minimum_size.y = 44
	play_button.custom_minimum_size.y = 48
	help_button.custom_minimum_size.y = 48
	quit_button.custom_minimum_size.y = 48
	top_back_button.custom_minimum_size = Vector2(112, 44)
	stage_card.add_theme_stylebox_override("panel", GameUITheme.make_menu_panel_style())
	stage_title.add_theme_color_override("font_color", COLOR_INK)
	stage_summary.add_theme_color_override("font_color", COLOR_MUTED)
	_apply_button_theme(stage_close_button, secondary_button, COLOR_INK)
	help_card.add_theme_stylebox_override("panel", GameUITheme.make_menu_panel_style())
	help_title.add_theme_color_override("font_color", COLOR_INK)
	help_title.add_theme_font_size_override("font_size", 24)
	help_body.add_theme_color_override("font_color", COLOR_MUTED)
	help_body.add_theme_font_size_override("font_size", 15)
	_apply_button_theme(help_close_button, secondary_button, COLOR_INK)
	_apply_button_theme(account_cancel_button, secondary_button, COLOR_INK)
	_apply_button_theme(account_create_button, primary_button, Color(1, 1, 1, 1))
	_apply_button_theme(delete_account_cancel_button, secondary_button, COLOR_INK)
	_apply_button_theme(delete_account_confirm_button, danger_button, COLOR_DANGER)
	_apply_line_edit_theme(account_name_input)
	_apply_responsive_layout()

func _make_panel_style() -> StyleBoxFlat:
	return GameUITheme.make_menu_panel_style()

func _make_button_style(color: Color, border_color: Color, radius: int = 14) -> StyleBoxFlat:
	var style: StyleBoxFlat = GameUITheme.make_menu_button_style(color, border_color)
	style.set_corner_radius_all(radius)
	return style

func _apply_button_theme(button: Button, normal_style: StyleBoxFlat, text_color: Color) -> void:
	GameUITheme.apply_button_theme(button, normal_style, text_color, 16)

func _apply_option_popup_theme(option: OptionButton) -> void:
	var popup: PopupMenu = option.get_popup()
	if not is_instance_valid(popup):
		return
	var panel_style: StyleBoxFlat = GameUITheme.make_panel_style(Color(0.93, 0.98, 0.95, 1), 14)
	panel_style.shadow_size = 14
	panel_style.shadow_offset = Vector2(0, 6)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	var hover_style: StyleBoxFlat = GameUITheme.make_button_style(Color(0.80, 0.91, 0.89, 1), COLOR_SECONDARY_BORDER, 10)
	hover_style.shadow_size = 0
	hover_style.content_margin_left = 8
	hover_style.content_margin_right = 8
	hover_style.content_margin_top = 5
	hover_style.content_margin_bottom = 5
	popup.add_theme_stylebox_override("panel", panel_style)
	popup.add_theme_stylebox_override("hover", hover_style)
	popup.add_theme_color_override("font_color", COLOR_INK)
	popup.add_theme_color_override("font_hover_color", COLOR_PRIMARY_DARK)
	popup.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_constant_override("v_separation", 6)
	popup.add_theme_constant_override("item_start_padding", 12)
	popup.add_theme_constant_override("item_end_padding", 16)
	popup.max_size = Vector2i(520, 360)

func _apply_line_edit_theme(input: LineEdit) -> void:
	var normal_style: StyleBoxFlat = GameUITheme.make_input_style()
	var focus_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	focus_style.set_border_width_all(2)
	focus_style.border_color = GameUITheme.FOCUS
	input.add_theme_stylebox_override("normal", normal_style)
	input.add_theme_stylebox_override("focus", focus_style)
	input.add_theme_color_override("font_color", COLOR_INK)
	input.add_theme_color_override("font_placeholder_color", COLOR_MUTED)
	input.add_theme_font_size_override("font_size", 16)
	input.custom_minimum_size.y = 44

func _apply_responsive_layout() -> void:
	if not is_instance_valid(menu_card):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var viewport_width: float = viewport_size.x
	var viewport_height: float = viewport_size.y
	var ui_scale: float = _get_ui_scale()
	var horizontal_padding: float = 32.0 * ui_scale
	menu_card.custom_minimum_size.x = clampf(viewport_width - horizontal_padding, 320.0, 620.0 * ui_scale)
	if is_instance_valid(stage_card):
		stage_card.custom_minimum_size.x = clampf(viewport_width - horizontal_padding, 330.0, 600.0 * ui_scale)
	if is_instance_valid(help_card):
		help_card.custom_minimum_size.x = clampf(viewport_width - horizontal_padding, 330.0, 560.0 * ui_scale)
	var margin: int = _scaled(26, ui_scale)
	if viewport_width >= 1100.0:
		margin = _scaled(34, ui_scale)
	elif viewport_width <= 620.0 or viewport_height <= 560.0:
		margin = _scaled(20, ui_scale)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		menu_content_margin.add_theme_constant_override(side, margin)
	menu_vbox.add_theme_constant_override("separation", _scaled(18, ui_scale))
	button_container.add_theme_constant_override("separation", _scaled(10, ui_scale))
	account_row.add_theme_constant_override("separation", _scaled(10, ui_scale))
	topic_row.add_theme_constant_override("separation", _scaled(10, ui_scale))
	menu_title.add_theme_font_size_override("font_size", _scaled(34, ui_scale))
	if is_instance_valid(menu_subtitle):
		menu_subtitle.add_theme_font_size_override("font_size", _scaled(15, ui_scale))
	if is_instance_valid(stage_title):
		stage_title.add_theme_font_size_override("font_size", _scaled(24, ui_scale))
	account_option.custom_minimum_size.y = _scaled(44, ui_scale)
	topic_option.custom_minimum_size.y = _scaled(44, ui_scale)
	add_account_button.custom_minimum_size = Vector2(_scaled(96, ui_scale), _scaled(44, ui_scale))
	delete_account_button.custom_minimum_size = Vector2(_scaled(48, ui_scale), _scaled(44, ui_scale))
	if is_instance_valid(account_manager_option):
		account_manager_option.custom_minimum_size.y = _scaled(44, ui_scale)
	if is_instance_valid(account_manager_add_button):
		account_manager_add_button.custom_minimum_size.y = _scaled(44, ui_scale)
	if is_instance_valid(account_manager_delete_button):
		account_manager_delete_button.custom_minimum_size.y = _scaled(44, ui_scale)
	if is_instance_valid(account_manager_close_button):
		account_manager_close_button.custom_minimum_size.y = _scaled(44, ui_scale)
	play_button.custom_minimum_size.y = _scaled(48, ui_scale)
	help_button.custom_minimum_size.y = _scaled(48, ui_scale)
	quit_button.custom_minimum_size.y = _scaled(48, ui_scale)
	if is_instance_valid(help_title):
		help_title.add_theme_font_size_override("font_size", _scaled(24, ui_scale))
	if is_instance_valid(help_body):
		help_body.add_theme_font_size_override("font_size", _scaled(15, ui_scale))
	if is_instance_valid(help_close_button):
		help_close_button.custom_minimum_size.y = _scaled(44, ui_scale)
	top_back_button.custom_minimum_size = Vector2(_scaled(112, ui_scale), _scaled(44, ui_scale))

func _get_ui_scale() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	var width_scale: float = viewport_size.x / 1280.0
	var height_scale: float = viewport_size.y / 720.0
	return clampf(minf(width_scale, height_scale), 0.82, 1.18)

func _scaled(value: int, ui_scale: float) -> int:
	return int(round(float(value) * ui_scale))

func _setup_focus_navigation() -> void:
	if mode == MenuMode.TOPICS:
		top_back_button.focus_neighbor_bottom = topic_option.get_path()
		topic_option.focus_neighbor_top = top_back_button.get_path()
		topic_option.focus_neighbor_bottom = play_button.get_path()
		play_button.focus_neighbor_top = topic_option.get_path()
		play_button.focus_neighbor_bottom = help_button.get_path()
		help_button.focus_neighbor_top = play_button.get_path()
		help_button.focus_neighbor_bottom = NodePath("")
		return
	account_option.focus_neighbor_right = add_account_button.get_path()
	account_option.focus_neighbor_bottom = play_button.get_path()
	add_account_button.focus_neighbor_left = account_option.get_path()
	add_account_button.focus_neighbor_bottom = play_button.get_path()
	play_button.focus_neighbor_top = account_option.get_path()
	play_button.focus_neighbor_bottom = help_button.get_path()
	help_button.focus_neighbor_top = play_button.get_path()
	help_button.focus_neighbor_bottom = quit_button.get_path()
	quit_button.focus_neighbor_top = help_button.get_path()
	quit_button.focus_neighbor_bottom = NodePath("")

func _play_menu_intro() -> void:
	if not is_instance_valid(menu_card):
		return
	menu_card.modulate = Color(1, 1, 1, 0)
	menu_card.scale = Vector2(0.98, 0.98)
	menu_card.pivot_offset = menu_card.size * 0.5
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(menu_card, "modulate", Color(1, 1, 1, 1), 0.20)
	tween.parallel().tween_property(menu_card, "scale", Vector2.ONE, 0.24)

func _setup_theme_options() -> void:
	themed_level_provider.build_levels(board_generator)
	_refresh_topic_options()

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
