extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var ammo_amount: int = 3

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	visual.texture = PrototypeArt.create_rect_texture(Vector2i(20, 12), Color(0.9, 0.56, 0.18, 1.0), Color(0.46, 0.22, 0.08, 1.0), 2)
	add_to_group("interactables")


func get_prompt(_player: Node = null) -> String:
	return "[E] Pick up ammo"


func interact(_player: Node) -> void:
	GameManager.add_ammo(ammo_amount)
	AudioManager.play_sfx("ammo_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
