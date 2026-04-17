extends Area2D


func _ready() -> void:
	add_to_group("interactables")


func get_prompt(_player: Node = null) -> String:
	return "[E] Escape"


func interact(_player: Node) -> void:
	GameManager.request_level_complete()
