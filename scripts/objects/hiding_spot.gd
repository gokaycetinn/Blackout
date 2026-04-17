extends Area2D

@onready var hide_anchor: Marker2D = $HideAnchor


func _ready() -> void:
	add_to_group("interactables")


func get_prompt(player = null) -> String:
	if player and player.has_method("is_hidden_state") and player.is_hidden_state() and player.current_hiding_spot == self:
		return "[E] Leave hiding spot"
	return "[E] Hide"


func interact(player) -> void:
	if player.current_hiding_spot == self and player.is_hidden_state():
		player.exit_hide()
	else:
		player.enter_hide(self)


func get_hide_position() -> Vector2:
	return hide_anchor.global_position


func get_exit_offset() -> Vector2:
	return Vector2(0.0, 42.0)
