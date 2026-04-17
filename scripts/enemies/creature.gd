extends CharacterBody2D

const EnemyStates = preload("res://scripts/enemies/enemy_states.gd")
const PlayerController = preload("res://scripts/player/player.gd")
const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 50.0
@export var investigate_speed: float = 70.0
@export var chase_speed: float = 180.0
@export var search_speed: float = 60.0
@export var base_view_distance: float = 180.0
@export var detection_gain: float = 55.0
@export var detection_decay: float = 22.0
@export var search_duration: float = 4.0
@export var attack_duration: float = 0.6

@onready var body_visual: Sprite2D = $Body

var player: PlayerController = null
var state: int = EnemyStates.State.PATROL
var detection_level: float = 0.0
var patrol_index: int = 0
var last_known_position: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var search_timer: float = 0.0
var health: int = 2
var hit_flash_timer: float = 0.0
var attack_timer: float = 0.0
var attack_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_visual.texture = PrototypeArt.create_creature_texture()
	player = GameManager.player
	last_known_position = global_position
	GameManager.global_noise_emitted.connect(_on_global_noise_emitted)
	if patrol_points.is_empty():
		state = EnemyStates.State.IDLE
		state_timer = 1.5


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
	_update_detection(delta)
	_update_state(delta)
	move_and_slide()
	_update_visual_feedback()

	if state == EnemyStates.State.CHASING and global_position.distance_to(player.global_position) < 20.0 and not player.is_hidden_state():
		_begin_attack()


func apply_damage(amount: int, _direction: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	detection_level = 100.0
	hit_flash_timer = 0.18
	if player:
		last_known_position = player.global_position
	_set_state(EnemyStates.State.CHASING)
	if health <= 0:
		GameManager.clear_detection_source(self)
		queue_free()


func _update_detection(delta: float) -> void:
	if player == null:
		return

	if state == EnemyStates.State.ATTACK:
		GameManager.report_detection(self, 100.0)
		return

	var sees_player := _can_see_player()
	if sees_player:
		last_known_position = player.global_position
		var visibility: float = player.get_visibility_multiplier()
		var distance_ratio := 1.0 - minf(global_position.distance_to(player.global_position) / (base_view_distance * maxf(visibility, 0.5)), 1.0)
		detection_level += detection_gain * maxf(distance_ratio, 0.15) * visibility * delta
	else:
		var decay_multiplier := 2.0 if player.is_hidden_state() else 1.0
		detection_level -= detection_decay * decay_multiplier * delta

	detection_level = clampf(detection_level, 0.0, 100.0)
	GameManager.report_detection(self, detection_level)

	if detection_level >= 100.0:
		_set_state(EnemyStates.State.CHASING)
	elif detection_level >= 35.0:
		_set_state(EnemyStates.State.INVESTIGATING)
	elif detection_level > 0.0 and state in [EnemyStates.State.PATROL, EnemyStates.State.IDLE]:
		_set_state(EnemyStates.State.SUSPICIOUS)
	elif detection_level <= 0.0 and state in [EnemyStates.State.SUSPICIOUS, EnemyStates.State.INVESTIGATING]:
		_set_state(EnemyStates.State.PATROL if not patrol_points.is_empty() else EnemyStates.State.IDLE)


func _can_see_player() -> bool:
	if player == null or player.is_hidden_state():
		return false

	var to_player: Vector2 = player.global_position - global_position
	var visibility: float = player.get_visibility_multiplier()
	var max_distance := base_view_distance * clampf(visibility, 0.5, 2.4)
	if to_player.length() > max_distance:
		return false

	var facing_direction := Vector2.RIGHT.rotated(rotation)
	if facing_direction.dot(to_player.normalized()) < -0.2 and state != EnemyStates.State.CHASING:
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
				_set_state(EnemyStates.State.INVESTIGATING if detection_level >= 35.0 else (EnemyStates.State.PATROL if not patrol_points.is_empty() else EnemyStates.State.IDLE))
		EnemyStates.State.INVESTIGATING:
			_follow_target(last_known_position, investigate_speed)
			if global_position.distance_to(last_known_position) < 14.0 and detection_level < 35.0:
				_set_state(EnemyStates.State.SEARCHING)
		EnemyStates.State.CHASING:
			if player:
				last_known_position = player.global_position
			_follow_target(last_known_position, chase_speed)
			if not _can_see_player() and global_position.distance_to(last_known_position) < 20.0 and detection_level < 40.0:
				_set_state(EnemyStates.State.SEARCHING)
		EnemyStates.State.SEARCHING:
			search_timer -= delta
			var sweep_target := last_known_position + Vector2(cos(Time.get_ticks_msec() / 350.0), sin(Time.get_ticks_msec() / 470.0)) * 28.0
			_follow_target(sweep_target, search_speed)
			if search_timer <= 0.0:
				_set_state(EnemyStates.State.PATROL if not patrol_points.is_empty() else EnemyStates.State.IDLE)
		EnemyStates.State.ATTACK:
			velocity = Vector2.ZERO
			if player:
				global_position = player.global_position + attack_offset
				_look_toward(player.global_position)
			attack_timer -= delta
			if attack_timer <= 0.0:
				GameManager.request_game_over("The creature latched onto Alex in the dark.")


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
		rotation = to_target.angle()


func _set_state(new_state: int) -> void:
	if new_state == state:
		return
	state = new_state
	match state:
		EnemyStates.State.IDLE:
			state_timer = 1.5
			body_visual.modulate = Color(0.55, 0.15, 0.15, 1.0)
		EnemyStates.State.PATROL:
			body_visual.modulate = Color(0.7, 0.2, 0.2, 1.0)
		EnemyStates.State.SUSPICIOUS:
			state_timer = 0.8
			body_visual.modulate = Color(0.85, 0.35, 0.2, 1.0)
		EnemyStates.State.INVESTIGATING:
			body_visual.modulate = Color(1.0, 0.45, 0.2, 1.0)
		EnemyStates.State.CHASING:
			body_visual.modulate = Color(1.0, 0.1, 0.1, 1.0)
		EnemyStates.State.SEARCHING:
			search_timer = search_duration
			body_visual.modulate = Color(0.95, 0.25, 0.4, 1.0)
		EnemyStates.State.ATTACK:
			attack_timer = attack_duration
			body_visual.modulate = Color(1.0, 0.0, 0.24, 1.0)


func _on_global_noise_emitted(position: Vector2, strength: float) -> void:
	var distance := global_position.distance_to(position)
	if distance > strength:
		return
	last_known_position = position
	detection_level = maxf(detection_level, lerpf(20.0, 70.0, 1.0 - clampf(distance / strength, 0.0, 1.0)))
	if state != EnemyStates.State.CHASING:
		_set_state(EnemyStates.State.INVESTIGATING if detection_level >= 35.0 else EnemyStates.State.SUSPICIOUS)


func _exit_tree() -> void:
	GameManager.clear_detection_source(self)


func _begin_attack() -> void:
	if state == EnemyStates.State.ATTACK or player == null:
		return
	attack_offset = (global_position - player.global_position).normalized() * 12.0
	if attack_offset.length_squared() <= 0.01:
		attack_offset = Vector2(10.0, -6.0)
	_set_state(EnemyStates.State.ATTACK)


func _update_visual_feedback() -> void:
	if state == EnemyStates.State.ATTACK:
		body_visual.scale = Vector2(1.15, 0.88)
	elif hit_flash_timer > 0.0:
		body_visual.modulate = Color(1.0, 0.85, 0.85, 1.0)
		body_visual.scale = Vector2.ONE * 1.08
	else:
		body_visual.scale = Vector2.ONE
