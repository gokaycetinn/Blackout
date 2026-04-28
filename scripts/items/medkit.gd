extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var heal_amount: int = 1

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	# Kırmızı medkit görünümü (beyaz artı işareti accent)
	visual.texture = PrototypeArt.create_rect_texture(
		Vector2i(22, 22),
		Color(0.85, 0.15, 0.15, 1.0),
		Color(0.5, 0.06, 0.06, 1.0),
		2,
		Color(1.0, 1.0, 1.0, 0.95),
		Rect2i(8, 4, 6, 14)
	)
	add_to_group("interactables")
	# Pulsing glow animasyonu
	var tw := create_tween().set_loops()
	tw.tween_property(visual, "modulate", Color(1.6, 0.8, 0.8, 1.0), 0.6)
	tw.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.7)


func get_prompt(_player: Node = null) -> String:
	return "[E] Pick up medkit (+1 HP)"


func interact(_player: Node) -> void:
	GameManager.add_health(heal_amount)
	AudioManager.play_sfx("battery_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
