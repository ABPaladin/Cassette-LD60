extends Node
signal selection_changed(object: Node3D)
signal hover_changed(object: Node3D)
@export var camera_path: NodePath
@onready var camera: Camera3D = get_node(camera_path)
var selected: Node3D
var hovered: Node3D
var dragging := false
var enabled := true
var rotation_enabled := true

func _physics_process(_delta: float) -> void:
	if not enabled or selected != null: return
	var hit := pick(get_viewport().get_mouse_position())
	if hit != hovered:
		if is_instance_valid(hovered): hovered.set_hover(false)
		hovered = hit
		if hovered != null: hovered.set_hover(true)
		hover_changed.emit(hovered)

func pick(pixel: Vector2) -> Node3D:
	var origin := camera.project_ray_origin(pixel)
	var end := origin + camera.project_ray_normal(pixel) * 30.0
	var query := PhysicsRayQueryParameters3D.create(origin, end, 2)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return null
	var object: Node = hit.collider
	while object != null:
		if object.has_method("begin_inspection"): return object as Node3D
		object = object.get_parent()
	return null

func select(object: Node3D) -> void:
	if not enabled or object == null: return
	if selected != null: selected.end_inspection()
	if hovered != null: hovered.set_hover(false)
	hovered = null
	selected = object
	dragging = false
	rotation_enabled = true
	camera.inspect_at(object.begin_inspection(), object.inspect_distance)
	selection_changed.emit(object)

func leave() -> void:
	if selected == null: return
	selected.end_inspection()
	selected = null
	dragging = false
	rotation_enabled = true
	camera.return_to_table()
	selection_changed.emit(null)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled: return
	if selected != null and selected.has_method("inspection_input") and selected.inspection_input(event,camera):
		dragging = false
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		leave()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			leave()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if selected == null and event.pressed: select(pick(event.position))
			elif selected != null: dragging = event.pressed
		elif selected != null and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera.zoom(-0.12)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera.zoom(0.12)
	elif event is InputEventMouseMotion and selected != null and dragging and rotation_enabled:
		selected.rotate_model(event.relative)

func _input(event: InputEvent) -> void:
	# Releases and exit gestures must work even over a GUI button or timeline.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
	if not enabled or selected == null: return
	if selected.has_method("inspection_input") and selected.get("page_dragging") == true:
		if event is InputEventMouseMotion or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
			selected.inspection_input(event,camera)
			dragging = false
			get_viewport().set_input_as_handled()
			return
	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		leave()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: dragging = false
