extends RefCounted
## Swap this shared Theme's font once Vintage Typist is supplied.
static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = preload("res://resources/interface_font.tres")
	theme.default_font_size = 18
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.065, 0.054, 0.044, 0.94)
	normal.border_color = Color(0.38, 0.31, 0.20)
	normal.set_border_width_all(1)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color(0.20, 0.15, 0.09, 0.97)
	for type in ["Button", "PanelContainer"]:
		theme.set_stylebox("normal" if type == "Button" else "panel", type, normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", hover)
	theme.set_color("font_color", "Label", Color(0.83, 0.77, 0.62))
	theme.set_color("font_color", "Button", Color(0.86, 0.79, 0.63))
	return theme

static func label(parent: Node, text: String, size: int = 18) -> Label:
	var control := Label.new()
	control.text = text
	control.add_theme_font_size_override("font_size", size)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	return control

static func button(parent: Node, text: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.focus_mode = Control.FOCUS_NONE
	control.pressed.connect(action)
	parent.add_child(control)
	return control
