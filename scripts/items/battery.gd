extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var charge_amount: float = 40.0

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	visual.texture = null
	
	# Battery Body (Metallic)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-6, -10), Vector2(6, -10),
		Vector2(6, 10), Vector2(-6, 10)
	])
	body.color = Color(0.15, 0.16, 0.18)
	visual.add_child(body)

	# Battery Terminals (Top)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-3, -12), Vector2(3, -12),
		Vector2(3, -10), Vector2(-3, -10)
	])
	top.color = Color(0.4, 0.4, 0.45)
	visual.add_child(top)

	# Glowing Energy Core
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(-3, -6), Vector2(3, -6),
		Vector2(3, 6), Vector2(-3, 6)
	])
	core.color = Color(0.1, 0.8, 0.9, 0.9) # Cyan glow
	visual.add_child(core)

	# Glow aura (soft)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-5, -8), Vector2(5, -8),
		Vector2(5, 8), Vector2(-5, 8)
	])
	glow.color = Color(0.1, 0.8, 0.9, 0.15)
	visual.add_child(glow)

	# Floating Animation
	var tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(visual, "position:y", -4.0, 1.2)
	tw.tween_property(visual, "position:y", 0.0, 1.2)
	
	# Glow Pulse
	var tw2 = create_tween().set_loops()
	tw2.tween_property(core, "color", Color(0.4, 1.0, 1.0, 1.0), 0.6)
	tw2.tween_property(core, "color", Color(0.1, 0.8, 0.9, 0.7), 0.6)

	add_to_group("interactables")


func get_prompt(_player: Node = null) -> String:
	return "[E] Pick up battery"


func interact(_player: Node) -> void:
	GameManager.add_battery(charge_amount)
	AudioManager.play_sfx("battery_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
