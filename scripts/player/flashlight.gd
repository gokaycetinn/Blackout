extends Node2D

@export var drain_rate: float = 1.0
@export var low_battery_threshold: float = 20.0
@export var base_energy: float = 1.15

@onready var light: PointLight2D = $PointLight2D
@onready var cone_visual: Polygon2D = $ConeVisual
@onready var raycast: RayCast2D = $RayCast2D


func _ready() -> void:
	_apply_state()


func aim_at(target: Vector2) -> void:
	look_at(target)


func toggle_flashlight() -> void:
	if GameManager.set_flashlight_on(not GameManager.is_flashlight_on):
		_apply_state()


func force_off() -> void:
	GameManager.set_flashlight_on(false)
	_apply_state()


func is_active() -> bool:
	return GameManager.is_flashlight_on and GameManager.battery_level > 0.0


func _process(delta: float) -> void:
	if not is_active():
		_apply_state()
		return

	GameManager.consume_battery(drain_rate * delta)
	if GameManager.battery_level <= 0.0:
		force_off()
		return

	var energy := base_energy
	var cone_alpha := 0.12
	if GameManager.battery_level <= low_battery_threshold:
		energy = randf_range(0.35, base_energy)
		cone_alpha = randf_range(0.05, 0.16)

	light.enabled = true
	light.energy = energy
	cone_visual.visible = true
	var cone_color := cone_visual.color
	cone_color.a = cone_alpha
	cone_visual.color = cone_color

	raycast.force_raycast_update()
	var hit_distance := 240.0
	if raycast.is_colliding():
		hit_distance = global_position.distance_to(raycast.get_collision_point())
	light.position = Vector2(clampf(hit_distance * 0.45, 72.0, 120.0), 0.0)


func _apply_state() -> void:
	light.enabled = is_active()
	cone_visual.visible = is_active()
