extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var charge_amount: float = 40.0

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	visual.texture = PrototypeArt.create_rect_texture(Vector2i(18, 26), Color(0.9, 0.84, 0.24, 1.0), Color(0.4, 0.32, 0.08, 1.0), 2, Color(0.2, 0.16, 0.05, 1.0), Rect2i(5, 2, 8, 5))
	add_to_group("interactables")


func get_prompt(_player: Node = null) -> String:
	return "[E] Pick up battery"


func interact(_player: Node) -> void:
	GameManager.add_battery(charge_amount)
	AudioManager.play_sfx("battery_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
