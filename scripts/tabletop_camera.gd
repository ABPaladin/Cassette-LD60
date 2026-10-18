extends Camera3D
## Screen-edge exploration with a separate inspection target and saved return pose.
@export var pan_speed := 1.15
@export var movement_strength := 1.0
@export_range(0.01, 0.48) var edge_margin := 0.18
@export var movement_limits := Vector2(2.15, 1.35)
@export var smoothing := 5.0
# Close, nearly overhead framing: the table fills the view and the tape anchors it.
@export var home_focus := Vector3(-2.15, 0.0, -1.05)
@export var table_offset := Vector3(0.0, 1.85, 0.65)
@export var inspection_offset := Vector3(0.0, 1.55, 0.55)
@export var zoom_limits := Vector2(0.65, 2.5)
var focus := Vector3.ZERO
var saved_focus := Vector3.ZERO
var inspect_focus := Vector3.ZERO
var inspect_distance := 1.3
var inspecting := false
var controls_enabled := true
var cinematic := false
var return_cooldown := 0.0

func _ready() -> void:
	focus = home_focus
	focus.x = clampf(focus.x, -movement_limits.x, movement_limits.x)
	focus.z = clampf(focus.z, -movement_limits.y, movement_limits.y)
	position = focus + table_offset
	look_at(focus)

func _process(delta: float) -> void:
	if cinematic: return
	var size := get_viewport().get_visible_rect().size
	step_camera(delta, get_viewport().get_mouse_position() / size)

func step_camera(delta: float, cursor: Vector2) -> void:
	return_cooldown = maxf(0.0, return_cooldown - delta)
	if controls_enabled and not inspecting and return_cooldown <= 0.0:
		var motion := Vector2(_edge(cursor.x), _edge(cursor.y)).limit_length()
		focus += Vector3(motion.x, 0.0, motion.y) * delta * pan_speed * movement_strength
		focus.x = clampf(focus.x, -movement_limits.x, movement_limits.x)
		focus.z = clampf(focus.z, -movement_limits.y, movement_limits.y)
	var aim := inspect_focus if inspecting else focus
	var offset := inspection_offset.normalized() * inspect_distance if inspecting else table_offset
	var desired := Transform3D(Basis.IDENTITY, aim + offset).looking_at(aim)
	global_transform = global_transform.interpolate_with(desired, 1.0 - exp(-smoothing * delta))

func inspect_at(point: Vector3, distance: float) -> void:
	if not inspecting: saved_focus = focus
	inspect_focus = point
	inspect_distance = clampf(distance, zoom_limits.x, zoom_limits.y)
	inspecting = true

func return_to_table() -> void:
	focus = saved_focus
	inspecting = false
	return_cooldown = .65

func zoom(amount: float) -> void:
	inspect_distance = clampf(inspect_distance + amount, zoom_limits.x, zoom_limits.y)

func _edge(value: float) -> float:
	value = clampf(value, 0.0, 1.0)
	if value < edge_margin: return (value - edge_margin) / edge_margin
	if value > 1.0 - edge_margin: return (value - (1.0 - edge_margin)) / edge_margin
	return 0.0
