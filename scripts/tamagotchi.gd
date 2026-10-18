extends "res://scripts/interactable.gd"
signal value_changed(value: String)
signal value_selected(value: String)
@export var sequence: Resource = preload("res://resources/pet_sequence.tres")
var sequence_index := 0
var screen_state := "NUMBER"
var press_count := 0
var button_tweens: Dictionary = {}

func _ready() -> void:
	super._ready()
	_update_screen()

func press_button(index: int) -> void:
	if not inspected or index < 0 or index > 2 or sequence.values.is_empty(): return
	press_count += 1
	var cap: Node3D = get_node("Visual/Button%d/Cap" % index)
	if button_tweens.has(index): button_tweens[index].kill()
	var tween := create_tween()
	button_tweens[index] = tween
	tween.tween_property(cap, "position:y", -.025, .06)
	tween.tween_property(cap, "position:y", 0.0, .12)
	if index == 1:
		screen_state = "SELECTED" if screen_state == "NUMBER" else "NUMBER"
		value_selected.emit(current_value())
	else:
		screen_state = "NUMBER"
		var next := sequence_index + (-1 if index == 0 else 1)
		sequence_index = posmod(next, sequence.values.size()) if sequence.repeat_sequence else clampi(next,0,sequence.values.size()-1)
		value_changed.emit(current_value())
	_update_screen()

func current_value() -> String:
	return "--" if sequence.values.is_empty() else sequence.values[sequence_index]

func _update_screen() -> void:
	$Visual/Screen.text = ("[" + current_value() + "]") if screen_state == "SELECTED" else current_value()

func button_at(pixel: Vector2, camera: Camera3D) -> int:
	var origin := camera.project_ray_origin(pixel)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(pixel) * 20.0, 6)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return -1
	if is_ancestor_of(hit.collider): return int(hit.collider.get_meta("button_index", -1))
	return -1

func _input(event: InputEvent) -> void:
	if not inspected: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_viewport().gui_get_hovered_control() is Button: return
		var index := button_at(event.position, get_viewport().get_camera_3d())
		if index >= 0:
			press_button(index)
			get_viewport().set_input_as_handled()
