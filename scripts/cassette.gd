extends "res://scripts/interactable.gd"
@onready var tape = $TapeAudioController
var last_position := 0.0
var manual_rewind := false
var reel_seconds_per_turn := 12.0

func _process(delta: float) -> void:
	super._process(delta)
	var movement_seconds: float = tape.position_seconds - last_position
	last_position = tape.position_seconds
	if not manual_rewind:
		var angle := -movement_seconds * TAU / reel_seconds_per_turn
		$Visual/ReelLeft.rotate_y(angle)
		$Visual/ReelRight.rotate_y(angle)
