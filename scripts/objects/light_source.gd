extends Node2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var light_color: Color = Color(0.85, 0.9, 1.0, 1.0)
@export var light_energy: float = 0.8
@export var flicker_enabled: bool = false

@onready var light: PointLight2D = $PointLight2D
@onready var fixture: Sprite2D = $Fixture

var _flicker_timer: float = 0.0


func _ready() -> void:
	fixture.texture = PrototypeArt.create_rect_texture(Vector2i(24, 10), Color(0.58, 0.6, 0.68, 1.0), Color(0.24, 0.26, 0.3, 1.0), 1)
	light.color = light_color
	light.energy = light_energy


func _process(delta: float) -> void:
	if not flicker_enabled:
		return
	_flicker_timer -= delta
	if _flicker_timer > 0.0:
		return
	light.energy = randf_range(light_energy * 0.25, light_energy)
	_flicker_timer = randf_range(0.03, 0.22)
