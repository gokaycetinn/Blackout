extends Area2D

@export var ammo_amount: int = 3


func _ready() -> void:
	add_to_group("interactables")


func get_prompt(_player: Node = null) -> String:
	return "[E] Pick up ammo"


func interact(_player: Node) -> void:
	GameManager.add_ammo(ammo_amount)
	AudioManager.play_sfx("ammo_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
