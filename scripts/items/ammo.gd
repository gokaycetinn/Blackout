extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var ammo_amount: int = 3

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	visual.texture = null
	
	# Ammo Box Base
	var box := Polygon2D.new()
	box.polygon = PackedVector2Array([
		Vector2(-10, -6), Vector2(10, -6),
		Vector2(10, 6), Vector2(-10, 6)
	])
	box.color = Color(0.25, 0.35, 0.2) # Military Green
	visual.add_child(box)
	
	# Box Lid details
	var lid := Polygon2D.new()
	lid.polygon = PackedVector2Array([
		Vector2(-11, -8), Vector2(11, -8),
		Vector2(11, -4), Vector2(-11, -4)
	])
	lid.color = Color(0.15, 0.25, 0.1) # Darker green lid
	visual.add_child(lid)

	# Latch / Buckle
	var latch := Polygon2D.new()
	latch.polygon = PackedVector2Array([
		Vector2(-2, -5), Vector2(2, -5),
		Vector2(2, -2), Vector2(-2, -2)
	])
	latch.color = Color(0.6, 0.6, 0.6) # Metal latch
	visual.add_child(latch)
	
	# Yellow Ammo decal
	var decal := Polygon2D.new()
	decal.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(-3, 0),
		Vector2(-3, 4), Vector2(-6, 4)
	])
	decal.color = Color(0.9, 0.8, 0.2)
	visual.add_child(decal)

	# Floating Animation
	var tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(visual, "position:y", -4.0, 1.0)
	tw.tween_property(visual, "position:y", 0.0, 1.0)

	add_to_group("interactables")


func get_prompt(_player: Node = null) -> String:
	return "[E] Pick up ammo"


func interact(_player: Node) -> void:
	GameManager.add_ammo(ammo_amount)
	AudioManager.play_sfx("ammo_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
