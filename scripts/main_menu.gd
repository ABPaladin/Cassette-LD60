extends Node3D
signal start_requested
const UI = preload("res://scripts/ui_style.gd")
var elapsed := 0.0
var start_button: Button
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Camera3D.look_at(Vector3.ZERO)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UI.make_theme()
	layer.add_child(ui)
	var title := UI.label(ui, "C A S S E T T E", 48)
	title.position = Vector2(0, 50)
	title.size.x = 960
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var year := UI.label(ui, "1 9 9 8", 18)
	year.position = Vector2(0,112)
	year.size.x = 960
	year.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_button = UI.button(ui, "START", func(): start_button.disabled = true; start_requested.emit())
	start_button.position = Vector2(380,435)
	start_button.size = Vector2(200,48)
	var quit_button := UI.button(ui, "QUIT", func(): get_tree().quit())
	quit_button.position = Vector2(428,492)
	quit_button.size.x = 104

func _process(delta: float) -> void:
	elapsed += delta
	$Cassette.rotation.y = sin(elapsed * .35) * .18
	$Cassette.position.y = sin(elapsed * .8) * .035
