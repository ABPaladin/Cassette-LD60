extends Camera3D
## Fixed tabletop pose with small local mouse-look; inspection alone may translate.
@export_range(0.0, 10.0, 0.1) var horizontal_look_degrees := 3.0
@export_range(0.0, 10.0, 0.1) var vertical_look_degrees := 2.0
@export var smoothing := 5.0
@export var inspection_offset := Vector3(0.0, 1.55, 0.55)
@export var zoom_limits := Vector2(0.65, 2.5)
var neutral_pose := Transform3D.IDENTITY
var look_angles := Vector2.ZERO
var inspect_focus := Vector3.ZERO
var inspect_distance := 1.3
var inspecting := false
var returning := false
var controls_enabled := true
var cinematic := false

func _ready() -> void:
	# The saved scene transform defines the composition, independent of cursor input.
	neutral_pose = global_transform

func _process(delta: float) -> void:
	var size := get_viewport().get_visible_rect().size
	step_camera(delta, get_viewport().get_mouse_position() / size)

func step_camera(delta: float, cursor: Vector2) -> void:
	if cinematic: return
	var weight := 1.0 - exp(-smoothing * delta)
	if inspecting:
		var offset := inspection_offset.normalized() * inspect_distance
		var desired := Transform3D(Basis.IDENTITY, inspect_focus + offset).looking_at(inspect_focus)
		global_transform = global_transform.interpolate_with(desired, weight)
		return
	if returning:
		# Restore the fixed position and pre-inspection orientation before resuming look.
		var desired := Transform3D(_table_basis(), neutral_pose.origin)
		global_transform = global_transform.interpolate_with(desired, weight)
		if global_position.distance_to(desired.origin) < .001 and global_basis.get_rotation_quaternion().angle_to(desired.basis.get_rotation_quaternion()) < .001:
			global_transform = desired
			returning = false
		return
	var pointer := (cursor * 2.0 - Vector2.ONE).clamp(-Vector2.ONE, Vector2.ONE)
	var target := Vector2(-pointer.x * deg_to_rad(horizontal_look_degrees), -pointer.y * deg_to_rad(vertical_look_degrees)) if controls_enabled else Vector2.ZERO
	look_angles = look_angles.lerp(target, weight)
	# Only the basis changes in tabletop mode. No accumulated pan, dolly or FOV change.
	global_transform = Transform3D(_table_basis(), neutral_pose.origin)

func _table_basis() -> Basis:
	return neutral_pose.basis * Basis.from_euler(Vector3(look_angles.y, look_angles.x, 0.0))

func inspect_at(point: Vector3, distance: float) -> void:
	inspect_focus = point
	inspect_distance = clampf(distance, zoom_limits.x, zoom_limits.y)
	inspecting = true
	returning = false

func return_to_table() -> void:
	if not inspecting: return
	inspecting = false
	returning = true

func zoom(amount: float) -> void:
	if inspecting:
		inspect_distance = clampf(inspect_distance + amount, zoom_limits.x, zoom_limits.y)
