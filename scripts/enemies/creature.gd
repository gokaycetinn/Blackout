extends CharacterBody2D

const EnemyStates = preload("res://scripts/enemies/enemy_states.gd")
const PlayerController = preload("res://scripts/player/player.gd")
const ENEMY_SPRITESHEET = preload("res://assets/sci-fi-facility-asset-pack/guard_orange_spritesheet.png")
const AmmoScene = preload("res://scenes/items/ammo.tscn")
const BatteryScene = preload("res://scenes/items/battery.tscn")
const MedkitScene = preload("res://scenes/items/medkit.tscn")
const ProjectileScene = preload("res://scenes/objects/projectile.tscn")

@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 50.0
@export var investigate_speed: float = 74.0
@export var chase_speed: float = 165.0
@export var search_speed: float = 75.0
@export var base_view_distance: float = 185.0
@export var fov_degrees: float = 82.0
@export var detection_gain: float = 48.0
@export var detection_decay: float = 20.0
@export var search_duration: float = 7.0
@export var idle_wait_time: float = 1.5
# Ranged attack
@export var shoot_range: float = 240.0
@export var shoot_min_range: float = 80.0
@export var shoot_cooldown: float = 1.6
# Contact damage (temas hasari)
@export var contact_range: float = 26.0
@export var contact_cooldown: float = 1.2

@onready var body_visual: Sprite2D = $Body
@onready var fov_cone: Polygon2D = $FOVCone

var player: PlayerController = null
var state: int = EnemyStates.State.PATROL
var detection_level: float = 0.0
var patrol_index: int = 0
var last_known_position: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var search_timer: float = 0.0
var health: int = 2
var hit_flash_timer: float = 0.0
var _shoot_cooldown_left: float = 0.0
var _contact_cooldown_left: float = 0.0
var _search_angle: float = 0.0
var _idle_variance: float = 0.0
var _base_body_scale: Vector2 = Vector2.ONE * 2.25


func _ready() -> void:
	body_visual.texture = _create_frame_texture(ENEMY_SPRITESHEET, Rect2i(16, 0, 16, 16))
	body_visual.scale = _base_body_scale
	player = GameManager.player
	last_known_position = global_position
	_idle_variance = randf_range(0.5, 1.8)
	GameManager.global_noise_emitted.connect(_on_global_noise_emitted)
	if patrol_points.is_empty():
		state = EnemyStates.State.IDLE
		state_timer = idle_wait_time + _idle_variance
	_setup_fov_cone()


func _setup_fov_cone() -> void:
	if not fov_cone:
		return
	var half_angle := deg_to_rad(fov_degrees * 0.5)
	var segments := 10
	var cone_length := base_view_distance * 0.72
	var pts := PackedVector2Array()
	pts.append(Vector2.ZERO)
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(-half_angle, half_angle, t)
		pts.append(Vector2(cos(angle), sin(angle)) * cone_length)
	fov_cone.polygon = pts
	fov_cone.color = Color(1.0, 0.18, 0.1, 0.0)
	fov_cone.z_index = -1


func _physics_process(delta: float) -> void:
	if GameManager.run_state != "playing":
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player == null:
		player = GameManager.player
		if player == null:
			return

	hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
	_shoot_cooldown_left = maxf(_shoot_cooldown_left - delta, 0.0)
	_contact_cooldown_left = maxf(_contact_cooldown_left - delta, 0.0)

	_update_detection(delta)
	_update_state(delta)
	move_and_slide()

	_update_visual_feedback()
	_update_fov_cone()




func apply_damage(amount: int, _direction: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	detection_level = 100.0
	hit_flash_timer = 0.22
	GameManager.request_hit_stop(0.06, 0.1)
	_spawn_blood_splatter()

	if player:
		last_known_position = player.global_position
	if health <= 0:
		GameManager.clear_detection_source(self)
		_spawn_death_particles()
		_drop_loot()
		queue_free()
		return
	_set_state(EnemyStates.State.CHASING)

func _spawn_blood_splatter() -> void:
	for i in range(4):
		var p := Polygon2D.new()
		var s := randf_range(2.0, 6.0)
		p.polygon = PackedVector2Array([
			Vector2(-s, -s*0.5), Vector2(s, -s*0.5), Vector2(s*0.8, s), Vector2(-s*0.8, s)
		])
		p.color = Color(0.85, 0.15, 0.05, 0.8) # Red blood
		p.global_position = global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
		p.rotation = randf_range(0.0, TAU)
		p.z_index = -5 # Paint on the floor
		
		# Add to World node so it persists after enemy death
		var world = get_tree().current_scene.get_node_or_null("World")
		if world:
			world.add_child(p)
		else:
			get_tree().current_scene.add_child(p)


func _spawn_death_particles() -> void:
	for i in range(6):
		var p := Polygon2D.new()
		var s := randf_range(3.0, 8.0)
		p.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s),
			Vector2(s, s), Vector2(-s, s)
		])
		p.color = Color(0.75, 0.08, 0.08, 0.9)
		p.global_position = global_position + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
		get_tree().current_scene.add_child(p)
		var tw := create_tween()
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0)), 0.45)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.45)
		tw.finished.connect(p.queue_free)


func _drop_loot() -> void:
	# Rastgele bir item düşür: %40 mermi, %30 batarya, %20 can, %10 hiçbir şey
	var roll := randf()
	var scene_to_spawn = null
	if roll < 0.40:
		scene_to_spawn = AmmoScene
	elif roll < 0.70:
		scene_to_spawn = BatteryScene
	elif roll < 0.90:
		scene_to_spawn = MedkitScene
	if scene_to_spawn == null:
		return
	var item: Node2D = scene_to_spawn.instantiate() as Node2D
	item.global_position = global_position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
	get_tree().current_scene.add_child(item)
	# Drop animasyonu — item'ın kendi tween'i üzerinden çalıştır
	item.modulate = Color(1, 1, 1, 0.0)
	var spawn_offset := Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	var tw: Tween = item.create_tween()
	tw.tween_property(item, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(item, "position", item.position + spawn_offset, 0.35)


func _update_detection(delta: float) -> void:
	if player == null:
		return

	var sees_player := _can_see_player()
	if sees_player:
		last_known_position = player.global_position
		var visibility: float = player.get_visibility_multiplier()
		var distance_to_player := global_position.distance_to(player.global_position)
		var dist_ratio := 1.0 - minf(distance_to_player / (base_view_distance * maxf(visibility, 0.55)), 1.0)
		var detection_push := maxf(dist_ratio - 0.2, 0.0)
		detection_level += detection_gain * detection_push * maxf(visibility, 0.7) * delta
		if distance_to_player < 72.0:
			detection_level += 10.0 * delta
	else:
		var decay_mult := 2.5 if player.is_hidden_state() else 1.0
		detection_level -= detection_decay * decay_mult * delta

	detection_level = clampf(detection_level, 0.0, 100.0)
	GameManager.report_detection(self, detection_level)

	if detection_level >= 100.0:
		_set_state(EnemyStates.State.CHASING)
	elif detection_level >= 60.0:
		_set_state(EnemyStates.State.INVESTIGATING)
	elif detection_level >= 12.0 and state in [EnemyStates.State.PATROL, EnemyStates.State.IDLE]:
		_set_state(EnemyStates.State.SUSPICIOUS)
	elif detection_level <= 0.0 and state in [EnemyStates.State.SUSPICIOUS, EnemyStates.State.INVESTIGATING]:
		_set_state(EnemyStates.State.PATROL if not patrol_points.is_empty() else EnemyStates.State.IDLE)


func _can_see_player() -> bool:
	if player == null or player.is_hidden_state():
		return false

	var to_player: Vector2 = player.global_position - global_position
	var visibility: float = player.get_visibility_multiplier()
	var max_dist := base_view_distance * clampf(visibility, 0.5, 2.0)

	if to_player.length() > max_dist:
		return false

	if state != EnemyStates.State.CHASING:
		var facing := Vector2.RIGHT.rotated(rotation)
		var half_angle := deg_to_rad(fov_degrees * 0.5)
		var angle_to_player := facing.angle_to(to_player.normalized())
		if abs(angle_to_player) > half_angle:
			return false

	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self]
	query.collision_mask = 1 | 2
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player


func _update_state(delta: float) -> void:
	match state:
		EnemyStates.State.IDLE:
			velocity = Vector2.ZERO
			state_timer -= delta
			if state_timer <= 0.0 and not patrol_points.is_empty():
				_set_state(EnemyStates.State.PATROL)

		EnemyStates.State.PATROL:
			_follow_target(patrol_points[patrol_index], patrol_speed)
			if global_position.distance_to(patrol_points[patrol_index]) < 10.0:
				patrol_index = (patrol_index + 1) % patrol_points.size()
				_set_state(EnemyStates.State.IDLE)

		EnemyStates.State.SUSPICIOUS:
			velocity = Vector2.ZERO
			state_timer -= delta
			_look_toward(last_known_position)
			if state_timer <= 0.0:
				if detection_level >= 60.0:
					_set_state(EnemyStates.State.INVESTIGATING)
				else:
					_set_state(EnemyStates.State.PATROL if not patrol_points.is_empty() else EnemyStates.State.IDLE)

		EnemyStates.State.INVESTIGATING:
			_follow_target(last_known_position, investigate_speed)
			if global_position.distance_to(last_known_position) < 14.0 and detection_level < 60.0:
				_set_state(EnemyStates.State.SEARCHING)

		EnemyStates.State.CHASING:
			if player:
				last_known_position = player.global_position
			if player and not player.is_hidden_state():
				var dist := global_position.distance_to(player.global_position)
				# Temas hasarı: fiziksel temas
				if dist < contact_range and _contact_cooldown_left <= 0.0:
					player.apply_damage()
					_contact_cooldown_left = contact_cooldown
				# Uzak mesafe ateşi
				if dist >= shoot_min_range and dist <= shoot_range and _shoot_cooldown_left <= 0.0:
					_shoot_projectile()
				# Hareket mantığı
				if dist < shoot_min_range:
					# Çok yakın — geri çekil
					var away := (global_position - player.global_position).normalized()
					velocity = away * chase_speed * 1.1
					_look_toward(player.global_position)
				elif dist <= shoot_range:
					# Ateş menzilinde — yana kayarak pozisyon al
					var strafe := (player.global_position - global_position).normalized().rotated(PI * 0.5)
					velocity = strafe * patrol_speed * 2.0
					_look_toward(player.global_position)
				else:
					# Çok uzak — yaklaş
					_follow_target(last_known_position, chase_speed)
			else:
				_follow_target(last_known_position, chase_speed)
				if not _can_see_player() and global_position.distance_to(last_known_position) < 20.0 and detection_level < 45.0:
					_set_state(EnemyStates.State.SEARCHING)

		EnemyStates.State.SEARCHING:
			search_timer -= delta
			_search_angle += delta * 1.4
			var sweep_radius := minf((_search_duration_ref() - search_timer) / _search_duration_ref() * 55.0, 55.0)
			var sweep_target := last_known_position + Vector2(cos(_search_angle), sin(_search_angle)) * sweep_radius
			_follow_target(sweep_target, search_speed)
			if search_timer <= 0.0:
				_set_state(EnemyStates.State.PATROL if not patrol_points.is_empty() else EnemyStates.State.IDLE)


func _search_duration_ref() -> float:
	return search_duration


func _shoot_projectile() -> void:
	if player == null:
		return
	_shoot_cooldown_left = shoot_cooldown
	var proj: Node2D = ProjectileScene.instantiate() as Node2D
	var fire_dir := (player.global_position - global_position).normalized()
	proj.global_position = global_position + fire_dir * 18.0
	proj.set("direction", fire_dir)
	proj.rotation = fire_dir.angle()
	get_tree().current_scene.add_child(proj)
	# Ateş geri tepme animasyonu
	var tw: Tween = create_tween()
	tw.tween_property(body_visual, "scale", _base_body_scale * 0.85, 0.07)
	tw.tween_property(body_visual, "scale", _base_body_scale, 0.13)


func _follow_target(target: Vector2, speed: float) -> void:
	var direction := target - global_position
	if direction.length() < 2.0:
		velocity = Vector2.ZERO
	else:
		velocity = direction.normalized() * speed
		_look_toward(target)


func _look_toward(target: Vector2) -> void:
	var to_target := target - global_position
	if to_target.length_squared() > 0.0001:
		var target_angle := to_target.angle()
		rotation = lerp_angle(rotation, target_angle, 0.22)


func _set_state(new_state: int) -> void:
	if new_state == state:
		return
	state = new_state
	match state:
		EnemyStates.State.IDLE:
			state_timer = idle_wait_time + _idle_variance
		EnemyStates.State.PATROL:
			pass
		EnemyStates.State.SUSPICIOUS:
			state_timer = 1.0
		EnemyStates.State.INVESTIGATING:
			pass
		EnemyStates.State.CHASING:
			pass
		EnemyStates.State.SEARCHING:
			search_timer = search_duration
			_search_angle = randf_range(0.0, TAU)


func _on_global_noise_emitted(position: Vector2, strength: float) -> void:
	var distance := global_position.distance_to(position)
	if distance > strength:
		return
	last_known_position = position
	detection_level = maxf(detection_level, lerpf(12.0, 58.0, 1.0 - clampf(distance / strength, 0.0, 1.0)))
	if state != EnemyStates.State.CHASING:
		_set_state(EnemyStates.State.INVESTIGATING if detection_level >= 60.0 else EnemyStates.State.SUSPICIOUS)


func _exit_tree() -> void:
	GameManager.clear_detection_source(self)


func _update_fov_cone() -> void:
	if not fov_cone:
		return
	match state:
		EnemyStates.State.PATROL, EnemyStates.State.IDLE:
			fov_cone.color = Color(0.9, 0.9, 0.9, 0.03)
		EnemyStates.State.SUSPICIOUS:
			fov_cone.color = Color(1.0, 0.85, 0.2, 0.08)
		EnemyStates.State.INVESTIGATING:
			fov_cone.color = Color(1.0, 0.5, 0.15, 0.12)
		EnemyStates.State.CHASING, EnemyStates.State.SEARCHING:
			fov_cone.color = Color(1.0, 0.1, 0.1, 0.17)


func _update_visual_feedback() -> void:
	if _shoot_cooldown_left > shoot_cooldown - 0.15:
		body_visual.modulate = Color(1.0, 0.55, 0.2, 1.0)
	elif hit_flash_timer > 0.0:
		body_visual.modulate = Color(1.0, 0.9, 0.9, 1.0)
		body_visual.scale = _base_body_scale * 1.08
	else:
		body_visual.scale = body_visual.scale.lerp(_base_body_scale, 0.25)
		match state:
			EnemyStates.State.IDLE:
				body_visual.modulate = Color(0.72, 0.72, 0.8, 1.0)
			EnemyStates.State.PATROL:
				body_visual.modulate = Color(0.86, 0.86, 0.92, 1.0)
			EnemyStates.State.SUSPICIOUS:
				body_visual.modulate = Color(1.0, 0.84, 0.42, 1.0)
			EnemyStates.State.INVESTIGATING:
				body_visual.modulate = Color(1.0, 0.62, 0.35, 1.0)
			EnemyStates.State.CHASING:
				body_visual.modulate = Color(1.0, 0.34, 0.28, 1.0)
			EnemyStates.State.SEARCHING:
				body_visual.modulate = Color(0.94, 0.44, 0.7, 1.0)


func _create_frame_texture(texture: Texture2D, region_rect: Rect2i) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(region_rect.position, region_rect.size)
	return atlas
