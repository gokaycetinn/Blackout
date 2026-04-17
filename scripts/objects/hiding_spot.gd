extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@onready var hide_anchor: Marker2D = $HideAnchor
@onready var table_sprite: Sprite2D = $Table


func _ready() -> void:
	table_sprite.texture = PrototypeArt.create_rect_texture(Vector2i(64, 28), Color(0.28, 0.19, 0.14, 1.0), Color(0.15, 0.1, 0.08, 1.0), 2, Color(0.38, 0.25, 0.16, 1.0), Rect2i(5, 5, 54, 6))
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
