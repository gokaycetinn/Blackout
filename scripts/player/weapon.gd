extends Node2D

@export var cooldown: float = 1.2
@export var bullet_range: float = 420.0
@export var damage: int = 1
@export var spread_degrees: float = 1.75

@onready var muzzle_flash: PointLight2D = $MuzzleFlash

var _cooldown_left: float = 0.0
var _flash_timer: float = 0.0


func _ready() -> void:
	muzzle_flash.enabled = false


func aim_at(target: Vector2) -> void:
	look_at(target)


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	muzzle_flash.enabled = _flash_timer > 0.0


func try_fire() -> bool:
	if GameManager.run_state != "playing":
		return false
	if _cooldown_left > 0.0:
		return false
	if GameManager.player and GameManager.player.has_method("is_hidden_state") and GameManager.player.is_hidden_state():
		return false
	if not GameManager.consume_ammo(1):
		return false

	_cooldown_left = cooldown
	_flash_timer = 0.1
	muzzle_flash.enabled = true
	AudioManager.play_sfx("gunshot", global_position)
	GameManager.emit_gunshot(global_position)

	var origin := global_position
	var aim_vector := get_global_mouse_position() - origin
	var direction := aim_vector.normalized() if aim_vector.length_squared() > 0.001 else Vector2.RIGHT.rotated(global_rotation)
	direction = direction.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees)))
	var query := PhysicsRayQueryParameters2D.create(origin, origin + direction * bullet_range)
	query.exclude = [get_parent()]
	query.collision_mask = 1 | 4

	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	var end_point := origin + direction * bullet_range
	if not hit.is_empty() and hit.collider and hit.collider.has_method("apply_damage"):
		end_point = hit.position
		hit.collider.apply_damage(damage, direction)
	elif not hit.is_empty():
		end_point = hit.position

	_spawn_tracer(origin, end_point)

	return true


func _spawn_tracer(start_point: Vector2, end_point: Vector2) -> void:
	var tracer := Line2D.new()
	tracer.top_level = true
	tracer.z_index = 12
	tracer.default_color = Color(1.0, 0.72, 0.38, 0.9)
	tracer.width = 2.4
	tracer.points = PackedVector2Array([start_point, end_point])
	get_tree().current_scene.add_child(tracer)

	var tween := create_tween()
	tween.tween_property(tracer, "modulate:a", 0.0, 0.08)
	tween.finished.connect(tracer.queue_free)
