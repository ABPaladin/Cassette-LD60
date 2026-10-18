extends Node3D
const UI = preload("res://scripts/ui_style.gd")
@onready var inspector = $InspectController
@onready var camera = $TabletopCamera
var ui: Control
var title: Label
var instructions: Label
var actions: HBoxContainer
var pencil_selected := false
var operation := "inspect"
var timeline: PanelContainer
var rewinder: Node

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	rewinder = preload("res://scripts/pencil_rewind.gd").new()
	add_child(rewinder)
	inspector.selection_changed.connect(_selection_changed)
	inspector.hover_changed.connect(func(object): title.text = object.display_name if object != null else "GLORIA'S BELONGINGS / 1998")

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UI.make_theme()
	layer.add_child(ui)
	title = UI.label(ui, "GLORIA'S BELONGINGS / 1998", 20)
	title.position = Vector2(24, 18)
	instructions = UI.label(ui, "Move cursor to screen edges to explore. Click an object.", 16)
	instructions.position = Vector2(24, 506)
	actions = HBoxContainer.new()
	actions.position = Vector2(24, 454)
	actions.add_theme_constant_override("separation", 10)
	ui.add_child(actions)
	timeline = preload("res://scripts/tape_timeline.gd").new()
	timeline.position = Vector2(420, 330)
	ui.add_child(timeline)
	timeline.bind($Objects/Cassette/TapeAudioController)
	timeline.hide()

func _selection_changed(object: Node3D) -> void:
	if rewinder != null and rewinder.active:
		rewinder.finish()
		$Objects/Cassette.manual_rewind = false
	operation = "inspect"
	timeline.visible = object != null and object.object_id == "cassette"
	for child in actions.get_children(): child.queue_free()
	if object == null:
		title.text = "GLORIA'S BELONGINGS / 1998"
		instructions.text = "Move cursor to screen edges to explore. Click an object."
		return
	title.text = object.display_name
	instructions.text = "Drag to rotate / wheel to zoom / ESC or right-click to return"
	UI.button(actions, "RETURN", inspector.leave)
	if object.object_id == "pencil":
		UI.button(actions, "USE ON CASSETTE", _use_pencil)
	if object.object_id == "cassette" and pencil_selected:
		UI.button(actions, "INSERT PENCIL", _begin_rewind)

func _use_pencil() -> void:
	pencil_selected = true
	inspector.select($Objects/Cassette)
	_begin_rewind()

func _begin_rewind() -> void:
	if rewinder.active: return
	operation = "rewind"
	inspector.rotation_enabled = false
	$Objects/Cassette.manual_rewind = true
	rewinder.begin($Objects/Cassette, $Objects/Pencil, camera)
	instructions.text = "Hold LMB and circle the reel: clockwise rewinds / opposite advances. ESC returns."
	title.text = "PENCIL REWIND"

func _process(_delta: float) -> void:
	timeline.manual_mode = rewinder != null and rewinder.active
	if rewinder != null and rewinder.active:
		var center: Vector2 = rewinder.center_on_screen()
		# Keep the analog strip close to the tool without covering its circular gesture.
		timeline.position = Vector2(clampf(center.x - 255, 14, 430), clampf(center.y + 110, 260, 336))
	else:
		timeline.position = Vector2(420, 330)
