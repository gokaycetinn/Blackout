extends Area2D

@export var charge_amount: float = 40.0


func _ready() -> void:
	add_to_group("interactables")


func get_prompt(_player: Node = null) -> String:
	return "[E] Pick up battery"


func interact(_player: Node) -> void:
	GameManager.add_battery(charge_amount)
	AudioManager.play_sfx("battery_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
