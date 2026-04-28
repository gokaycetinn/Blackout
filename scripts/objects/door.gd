extends StaticBody2D

@onready var left_door: Polygon2D = $LeftDoor
@onready var right_door: Polygon2D = $RightDoor
@onready var light: PointLight2D = $PointLight2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_open: bool = false
var bodies_inside: int = 0

func _ready() -> void:
	$SensorArea.body_entered.connect(_on_sensor_entered)
	$SensorArea.body_exited.connect(_on_sensor_exited)
	light.color = Color(1.0, 0.2, 0.1)

func _on_sensor_entered(body: Node2D) -> void:
	if body is CharacterBody2D: # Player or enemies
		bodies_inside += 1
		if not is_open and bodies_inside > 0:
			open_door()

func _on_sensor_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		bodies_inside = max(0, bodies_inside - 1)
		if is_open and bodies_inside == 0:
			close_door()

func open_door() -> void:
	is_open = true
	light.color = Color(0.2, 1.0, 0.4)
	collision.set_deferred("disabled", true)
	var tw := create_tween().set_parallel(true)
	# Assuming a vertical sliding door for top-down perspective
	tw.tween_property(left_door, "position:y", -66.0, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(right_door, "position:y", 66.0, 0.35).set_trans(Tween.TRANS_SINE)


func close_door() -> void:
	is_open = false
	light.color = Color(1.0, 0.2, 0.1)
	collision.set_deferred("disabled", false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(left_door, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(right_door, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
