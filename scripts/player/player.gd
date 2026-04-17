extends CharacterBody2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var walk_speed: float = 120.0
@export var run_speed: float = 200.0
@export var crouch_speed: float = 60.0

@onready var body_visual: Sprite2D = $Body
@onready var facing_marker: Sprite2D = $FacingMarker
@onready var flashlight = $Flashlight
@onready var weapon_mount = $WeaponMount
@onready var interact_area: Area2D = $InteractArea
@onready var stealth_indicator: Polygon2D = $StealthIndicator

var is_crouching: bool = false
var is_hidden: bool = false
var current_hiding_spot = null
var _interaction_candidates: Array[Area2D] = []
var _footstep_timer: float = 0.0


func _ready() -> void:
	body_visual.texture = PrototypeArt.create_player_texture()
	facing_marker.texture = PrototypeArt.create_rect_texture(Vector2i(12, 6), Color(0.92, 0.66, 0.28, 0.95))
	GameManager.register_player(self)
	interact_area.area_entered.connect(_on_interact_area_entered)
	interact_area.area_exited.connect(_on_interact_area_exited)
	_update_visual_state()


func _physics_process(delta: float) -> void:
	if GameManager.run_state != "playing":
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var mouse_world := get_global_mouse_position()
	var aim_direction := mouse_world - global_position
	if aim_direction.length_squared() > 0.0001:
		var aim_rotation := aim_direction.angle()
		body_visual.rotation = aim_rotation
		facing_marker.rotation = aim_rotation
		stealth_indicator.rotation = aim_rotation
		flashlight.aim_at(mouse_world)
		weapon_mount.aim_at(mouse_world)

	if Input.is_action_just_pressed("toggle_flashlight"):
		flashlight.toggle_flashlight()
	if Input.is_action_just_pressed("crouch") and not is_hidden:
		is_crouching = not is_crouching
		_update_visual_state()
	if Input.is_action_just_pressed("interact"):
		_use_interactable()
	if Input.is_action_just_pressed("fire"):
		weapon_mount.try_fire()

	if is_hidden:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var movement_mode := "idle"
	var speed := walk_speed
	if input_vector.length() > 0.0:
		if is_crouching:
			speed = crouch_speed
			movement_mode = "crouch"
		elif Input.is_action_pressed("run"):
			speed = run_speed
			movement_mode = "run"
		else:
			movement_mode = "walk"

	velocity = input_vector * speed
	move_and_slide()
	_handle_footsteps(delta, movement_mode)
	_refresh_interact_prompt()


func _handle_footsteps(delta: float, movement_mode: String) -> void:
	if movement_mode == "idle":
		_footstep_timer = 0.0
		return

	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return

	match movement_mode:
		"run":
			_footstep_timer = 0.3
			GameManager.emit_noise(global_position, 320.0)
		"crouch":
			_footstep_timer = 0.8
			GameManager.emit_noise(global_position, 60.0)
		_:
			_footstep_timer = 0.5
			GameManager.emit_noise(global_position, 140.0)

	AudioManager.play_footstep(movement_mode)


func get_visibility_multiplier() -> float:
	if is_hidden:
		return 0.05

	var visibility := 1.0
	if is_crouching:
		visibility *= 0.5
	if flashlight.is_active():
		visibility *= 2.0
	else:
		visibility *= 0.7
	if velocity.length() < 1.0 and not flashlight.is_active():
		visibility *= 0.3
	return visibility


func is_hidden_state() -> bool:
	return is_hidden


func enter_hide(hiding_spot) -> void:
	current_hiding_spot = hiding_spot
	is_hidden = true
	velocity = Vector2.ZERO
	global_position = hiding_spot.get_hide_position()
	flashlight.force_off()
	GameManager.set_hidden(true)
	_update_visual_state()
	GameManager.set_interact_prompt("[E] Leave hiding spot")


func exit_hide() -> void:
	if current_hiding_spot == null:
		return
	global_position = current_hiding_spot.get_hide_position() + current_hiding_spot.get_exit_offset()
	current_hiding_spot = null
	is_hidden = false
	GameManager.set_hidden(false)
	_update_visual_state()
	_refresh_interact_prompt()


func apply_damage() -> void:
	GameManager.request_game_over("A creature tore through the darkness.")


func _use_interactable() -> void:
	if is_hidden and current_hiding_spot:
		exit_hide()
		return

	var nearest := _get_nearest_interactable()
	if nearest and nearest.has_method("interact"):
		nearest.interact(self)


func _get_nearest_interactable() -> Area2D:
	var nearest: Area2D = null
	var nearest_distance := INF
	for candidate in _interaction_candidates:
		if not is_instance_valid(candidate):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _on_interact_area_entered(area: Area2D) -> void:
	if area.has_method("interact"):
		_interaction_candidates.append(area)
	_refresh_interact_prompt()


func _on_interact_area_exited(area: Area2D) -> void:
	_interaction_candidates.erase(area)
	_refresh_interact_prompt()


func _refresh_interact_prompt() -> void:
	if is_hidden and current_hiding_spot:
		GameManager.set_interact_prompt("[E] Leave hiding spot")
		return

	var nearest: Area2D = _get_nearest_interactable()
	if nearest == null:
		GameManager.set_interact_prompt("")
		return

	if nearest.has_method("get_prompt"):
		GameManager.set_interact_prompt(nearest.get_prompt(self))
	else:
		GameManager.set_interact_prompt("[E] Interact")


func _update_visual_state() -> void:
	var body_modulate := Color(0.78, 0.92, 0.82, 0.25 if is_hidden else 1.0)
	body_visual.modulate = body_modulate

	var marker_modulate := Color(0.95, 0.72, 0.32, 0.3 if is_hidden else 1.0)
	facing_marker.modulate = marker_modulate

	stealth_indicator.visible = is_crouching or is_hidden
	stealth_indicator.color = Color(0.4, 0.9, 0.6, 0.8) if is_hidden else Color(1.0, 0.9, 0.35, 0.75)
