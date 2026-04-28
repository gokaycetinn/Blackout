extends Node2D

@export var cooldown: float = 0.20
@export var bullet_range: float = 480.0
@export var damage: int = 1
@export var spread_degrees: float = 0.8

@onready var muzzle_flash: PointLight2D = $MuzzleFlash

var _cooldown_left: float = 0.0
var _flash_timer: float = 0.0
var _energy_bar_node: Polygon2D = null


func _ready() -> void:
	muzzle_flash.enabled = false
	_build_weapon_visual()


func _build_weapon_visual() -> void:
	# --- Gun body (main frame) ---
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-6, -3.5), Vector2(16, -3.5),
		Vector2(16, 3.5),  Vector2(-6, 3.5)
	])
	body.color = Color(0.18, 0.22, 0.28, 1.0)
	add_child(body)

	# --- Barrel ---
	var barrel := Polygon2D.new()
	barrel.polygon = PackedVector2Array([
		Vector2(16, -2.2), Vector2(28, -2.2),
		Vector2(28, 2.2),  Vector2(16, 2.2)
	])
	barrel.color = Color(0.12, 0.15, 0.20, 1.0)
	add_child(barrel)

	# --- Barrel tip accent ---
	var tip := Polygon2D.new()
	tip.polygon = PackedVector2Array([
		Vector2(26, -3), Vector2(30, -3),
		Vector2(30, 3),  Vector2(26, 3)
	])
	tip.color = Color(0.42, 0.85, 0.92, 0.9)
	add_child(tip)

	# --- Grip ---
	var grip := Polygon2D.new()
	grip.polygon = PackedVector2Array([
		Vector2(-3, 3.5), Vector2(4, 3.5),
		Vector2(3, 11),   Vector2(-4, 11)
	])
	grip.color = Color(0.24, 0.20, 0.18, 1.0)
	add_child(grip)

	# --- Scope rail ---
	var rail := Polygon2D.new()
	rail.polygon = PackedVector2Array([
		Vector2(3, -5.5), Vector2(14, -5.5),
		Vector2(14, -3.5), Vector2(3, -3.5)
	])
	rail.color = Color(0.30, 0.35, 0.42, 1.0)
	add_child(rail)

	# --- Scope lens ---
	var lens := Polygon2D.new()
	lens.polygon = PackedVector2Array([
		Vector2(6, -5.5), Vector2(12, -5.5),
		Vector2(12, -3.5), Vector2(6, -3.5)
	])
	lens.color = Color(0.42, 0.85, 0.92, 0.75)
	add_child(lens)

	# --- Energy cell (cyan glow accent on body) ---
	var cell := Polygon2D.new()
	cell.polygon = PackedVector2Array([
		Vector2(1, -2.5), Vector2(10, -2.5),
		Vector2(10, 2.5), Vector2(1, 2.5)
	])
	cell.color = Color(0.35, 0.78, 0.88, 0.4)
	add_child(cell)
	_energy_bar_node = cell

	# Subtle pulse animation on energy cell
	var tw: Tween = create_tween().set_loops()
	tw.tween_property(cell, "color", Color(0.55, 0.95, 1.0, 0.7), 0.55)
	tw.tween_property(cell, "color", Color(0.35, 0.78, 0.88, 0.3), 0.55)

	# --- Magazine bump ---
	var mag := Polygon2D.new()
	mag.polygon = PackedVector2Array([
		Vector2(0, 3.5), Vector2(6, 3.5),
		Vector2(6, 7),   Vector2(0, 7)
	])
	mag.color = Color(0.20, 0.24, 0.30, 1.0)
	add_child(mag)


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
	_flash_timer = 0.10
	muzzle_flash.enabled = true
	AudioManager.play_sfx("gunshot", global_position)
	GameManager.emit_gunshot(global_position)

	# Recoil animation
	var tw: Tween = create_tween()
	tw.tween_property(self, "position", Vector2(-3, 0), 0.05)
	tw.tween_property(self, "position", Vector2(0, 0), 0.10)

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
		_spawn_hit_spark(end_point)
	elif not hit.is_empty():
		end_point = hit.position
		_spawn_hit_spark(end_point)

	_spawn_tracer(origin, end_point)
	return true


func _spawn_tracer(start_point: Vector2, end_point: Vector2) -> void:
	# Glow layer (wide, soft)
	var glow := Line2D.new()
	glow.top_level = true
	glow.z_index = 10
	glow.default_color = Color(0.42, 0.88, 1.0, 0.22)
	glow.width = 10.0
	glow.points = PackedVector2Array([start_point, end_point])
	get_tree().current_scene.add_child(glow)

	# Core beam (sharp, bright)
	var tracer := Line2D.new()
	tracer.top_level = true
	tracer.z_index = 12
	tracer.default_color = Color(0.75, 0.97, 1.0, 0.95)
	tracer.width = 2.2
	tracer.points = PackedVector2Array([start_point, end_point])
	get_tree().current_scene.add_child(tracer)

	var tw: Tween = glow.create_tween()
	tw.tween_property(glow, "modulate:a", 0.0, 0.11)
	tw.finished.connect(glow.queue_free)

	var tw2: Tween = tracer.create_tween()
	tw2.tween_property(tracer, "modulate:a", 0.0, 0.11)
	tw2.finished.connect(tracer.queue_free)


func _spawn_hit_spark(pos: Vector2) -> void:
	for i in range(6):
		var p := Polygon2D.new()
		var s := randf_range(1.5, 4.5)
		p.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s), Vector2(s, s), Vector2(-s, s)
		])
		p.color = Color(0.6, 0.95, 1.0, 0.95)
		p.global_position = pos + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0))
		p.top_level = true
		get_tree().current_scene.add_child(p)
		var tw: Tween = p.create_tween()
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-22.0, 22.0), randf_range(-22.0, 22.0)), 0.22)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.22)
		tw.finished.connect(p.queue_free)
