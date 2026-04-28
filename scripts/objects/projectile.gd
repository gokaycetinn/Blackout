extends CharacterBody2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 230.0
var _lifetime: float = 2.8

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	var tw: Tween = create_tween().set_loops()
	tw.tween_property(visual, "modulate", Color(2.0, 0.6, 0.4, 1.0), 0.18)
	tw.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)


func _physics_process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return

	velocity = direction * speed
	move_and_slide()
	_spawn_trail()

	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var collider := col.get_collider()
		if collider != null and collider.has_method("apply_damage"):
			collider.apply_damage()
		_spawn_impact()
		queue_free()
		return

func _spawn_trail() -> void:
	var p := Polygon2D.new()
	var s := randf_range(1.5, 3.5)
	p.polygon = PackedVector2Array([
		Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
	])
	p.color = Color(1.0, 0.4, 0.1, 0.6)
	p.global_position = global_position + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	p.top_level = true
	get_tree().current_scene.add_child(p)
	var tw: Tween = p.create_tween()
	tw.tween_property(p, "modulate:a", 0.0, 0.15)
	tw.finished.connect(p.queue_free)


func _spawn_impact() -> void:
	for i in range(5):
		var p := Polygon2D.new()
		var s := randf_range(2.5, 6.0)
		p.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
		])
		p.color = Color(1.0, 0.35, 0.1, 0.9)
		p.global_position = global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
		get_tree().current_scene.add_child(p)
		var tw: Tween = p.create_tween()
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-28.0, 28.0), randf_range(-28.0, 28.0)), 0.32)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.32)
		tw.finished.connect(p.queue_free)
