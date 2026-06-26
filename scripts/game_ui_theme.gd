class_name GameUITheme
extends RefCounted

const INK := Color(0.06, 0.12, 0.15, 1)
const MUTED := Color(0.30, 0.43, 0.46, 1)
const BACKGROUND := Color(0.06, 0.24, 0.30, 1)
const BACKGROUND_TOP := Color(0.17, 0.50, 0.58, 0.36)
const BACKGROUND_BOTTOM := Color(0.15, 0.39, 0.30, 0.62)
const PANEL := Color(0.95, 0.98, 0.93, 0.98)
const PANEL_ALT := Color(0.86, 0.93, 0.91, 0.98)
const SURFACE := Color(0.99, 0.97, 0.90, 1)
const PRIMARY := Color(0.05, 0.45, 0.55, 1)
const PRIMARY_DARK := Color(0.03, 0.27, 0.34, 1)
const SECONDARY := Color(0.84, 0.93, 0.91, 1)
const SECONDARY_BORDER := Color(0.43, 0.63, 0.64, 1)
const SUCCESS := Color(0.10, 0.57, 0.35, 1)
const SUCCESS_SOFT := Color(0.82, 0.93, 0.86, 1)
const WARNING := Color(0.91, 0.69, 0.22, 1)
const WARNING_SOFT := Color(1.0, 0.91, 0.62, 1)
const DANGER := Color(0.74, 0.22, 0.18, 1)
const DANGER_SOFT := Color(0.98, 0.86, 0.82, 1)
const FOCUS := Color(1.0, 0.80, 0.30, 1)

static func make_panel_style(color: Color, radius: int = 18) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = Color(0.68, 0.83, 0.79, 1)
	style.shadow_color = Color(0.01, 0.08, 0.09, 0.14)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

static func make_menu_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = make_panel_style(PANEL, 24)
	style.shadow_color = Color(0.01, 0.08, 0.09, 0.22)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

static func make_button_style(color: Color, border_color: Color, radius: int = 14) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1)
	style.border_color = border_color
	style.shadow_color = Color(0.01, 0.08, 0.09, 0.10)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func make_input_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = make_button_style(Color(1, 1, 1, 1), Color(0.54, 0.68, 0.70, 1), 12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.01, 0.08, 0.09, 0.12)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style

static func make_danger_button_style() -> StyleBoxFlat:
	return make_menu_button_style(DANGER_SOFT, DANGER)

static func make_warning_button_style() -> StyleBoxFlat:
	return make_button_style(WARNING_SOFT, WARNING, 14)

static func make_menu_button_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = make_button_style(color, border_color, 14)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func make_bar_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	return style

static func make_tile_style(color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(9)
	style.set_border_width_all(border_width)
	style.border_color = border_color
	style.shadow_color = Color(0.01, 0.08, 0.09, 0.16)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 2
	style.content_margin_right = 2
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

static func apply_button_theme(button: Button, normal_style: StyleBoxFlat, text_color: Color, font_size: int = 14) -> void:
	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = normal_style.bg_color.lightened(0.07)
	hover_style.shadow_size = normal_style.shadow_size + 2
	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = normal_style.bg_color.darkened(0.08)
	pressed_style.shadow_size = maxi(0, normal_style.shadow_size - 2)
	pressed_style.shadow_offset = Vector2(0, 1)
	var focus_style: StyleBoxFlat = hover_style.duplicate() as StyleBoxFlat
	focus_style.set_border_width_all(2)
	focus_style.border_color = FOCUS
	var disabled_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.78, 0.84, 0.82, 0.72)
	disabled_style.border_color = Color(0.62, 0.70, 0.69, 0.72)

	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_hover_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color(0.40, 0.48, 0.48, 1))
	button.add_theme_font_size_override("font_size", font_size)
