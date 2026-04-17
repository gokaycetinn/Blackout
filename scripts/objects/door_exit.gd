extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@onready var door_sprite: Sprite2D = $Door


func _ready() -> void:
	door_sprite.texture = PrototypeArt.create_rect_texture(Vector2i(48, 78), Color(0.13, 0.19, 0.26, 1.0), Color(0.42, 0.72, 0.92, 1.0), 2, Color(0.62, 0.89, 1.0, 1.0), Rect2i(34, 32, 6, 6))
	add_to_group("interactables")


func get_prompt(_player: Node = null) -> String:
	return "[E] Escape"


func interact(_player: Node) -> void:
	GameManager.request_level_complete()
