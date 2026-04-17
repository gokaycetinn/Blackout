extends Node

var tension_level: float = 0.0


func play_sfx(_sound_name: String, _position: Vector2 = Vector2.ZERO) -> void:
	# Placeholder hook for future audio assets.
	pass


func set_tension_level(level: float) -> void:
	tension_level = clampf(level, 0.0, 1.0)


func play_footstep(_movement_mode: String) -> void:
	pass
