class_name TileButton
extends Button

signal tile_pressed(pos: Vector2i)

@export var grid_pos: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	pressed.connect(_on_pressed)
	focus_mode = Control.FOCUS_ALL

func _on_pressed() -> void:
	tile_pressed.emit(grid_pos)

func set_display_size(size: int) -> void:
	custom_minimum_size = Vector2(size, size)
	add_theme_font_size_override("font_size", maxi(12, int(size * 0.55)))

func update_view(cell: Variant, is_selected: bool, is_active_word: bool) -> void:
	if cell == null:
		visible = true
		text = ""
		disabled = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_clear_border()
		_clear_text_color()
		modulate = Color(1, 1, 1, 0)
		return
	visible = true
	disabled = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var display: String = String(cell.get("input_char", ""))
	text = display
	var is_correct: bool = bool(cell.get("is_correct", false))
	modulate = Color(1, 1, 1, 1)
	_clear_border()
	_clear_text_color()
	_set_tile_style(Color(0.98, 1.0, 0.96, 1), GameUITheme.SECONDARY_BORDER, 1)
	_set_text_color(GameUITheme.INK)
	if is_correct and display != "":
		_set_text_color(Color(0.04, 0.27, 0.17, 1))
		_set_tile_style(GameUITheme.SUCCESS_SOFT, GameUITheme.SUCCESS, 2)
	if is_active_word:
		_set_tile_style(GameUITheme.SECONDARY, GameUITheme.PRIMARY, 2)
		_set_text_color(Color(0.03, 0.21, 0.26))
		modulate = Color(1, 1, 1, 1)
	if is_selected:
		_set_tile_style(GameUITheme.WARNING_SOFT, GameUITheme.FOCUS, 3)
		_set_text_color(Color(0.26, 0.16, 0.02))

func _set_tile_style(bg_color: Color, border_color: Color, border_width: int) -> void:
	var style: StyleBoxFlat = GameUITheme.make_tile_style(bg_color, border_color, border_width)
	var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover_style.bg_color = bg_color.lightened(0.06)
	var pressed_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = bg_color.darkened(0.05)
	var focus_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	focus_style.set_border_width_all(maxi(border_width, 2))
	focus_style.border_color = GameUITheme.FOCUS
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("focus", focus_style)

func _set_border(color: Color) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.draw_center = false
	style.set_border_width_all(2)
	style.border_color = color
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)

func _clear_border() -> void:
	remove_theme_stylebox_override("normal")
	remove_theme_stylebox_override("hover")
	remove_theme_stylebox_override("pressed")
	remove_theme_stylebox_override("focus")

func _set_text_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_hover_color", color)
	add_theme_color_override("font_pressed_color", color)
	add_theme_color_override("font_focus_color", color)

func _clear_text_color() -> void:
	remove_theme_color_override("font_color")
	remove_theme_color_override("font_hover_color")
	remove_theme_color_override("font_pressed_color")
	remove_theme_color_override("font_focus_color")
