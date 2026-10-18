extends "res://scripts/interactable.gd"
@onready var tape = $TapeAudioController
var last_position := 0.0
var manual_rewind := false

func _process(delta: float) -> void:
	super._process(delta)
	var movement_seconds: float = tape.position_seconds - last_position
	last_position = tape.position_seconds
	if not manual_rewind: $Visual/ReelLeft.rotate_y(movement_seconds * 0.45)
	$Visual/ReelRight.rotate_y(movement_seconds * 0.45)
