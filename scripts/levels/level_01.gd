extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CREATURE_SCENE := preload("res://scenes/enemies/creature.tscn")
const BATTERY_SCENE := preload("res://scenes/items/battery.tscn")
const AMMO_SCENE := preload("res://scenes/items/ammo.tscn")
const HIDING_SPOT_SCENE := preload("res://scenes/objects/hiding_spot.tscn")
const EXIT_DOOR_SCENE := preload("res://scenes/objects/door_exit.tscn")
const LIGHT_SOURCE_SCENE := preload("res://scenes/objects/light_source.tscn")

const MAP_WIDTH := 1600.0
const MAP_HEIGHT := 960.0

@onready var world: Node2D = $World
@onready var environment_lights: Node2D = $EnvironmentLights
@onready var enemies_root: Node2D = $Enemies
@onready var items_root: Node2D = $Items
@onready var objects_root: Node2D = $Objects
@onready var camera: Camera2D = $Camera2D

var player: CharacterBody2D


func _ready() -> void:
	GameManager.reset_run()
	GameManager.register_level(self)
	_build_floor()
	_build_walls()
	_spawn_player()
	_spawn_lights()
	_spawn_items()
	_spawn_hiding_spots()
	_spawn_exit()
	_spawn_enemies()


func _process(delta: float) -> void:
	if player:
		camera.global_position = camera.global_position.lerp(player.global_position, minf(delta * 4.0, 1.0))
	AudioManager.set_tension_level(GameManager.current_detection / 100.0)


func _build_floor() -> void:
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(MAP_WIDTH, 0),
		Vector2(MAP_WIDTH, MAP_HEIGHT),
		Vector2(0, MAP_HEIGHT)
	])
	floor_poly.color = Color(0.11, 0.12, 0.15, 1.0)
	world.add_child(floor_poly)

	for room in [
		Rect2(80, 110, 240, 170),
		Rect2(430, 100, 280, 190),
		Rect2(1080, 110, 270, 170),
		Rect2(280, 580, 240, 180),
		Rect2(640, 460, 270, 220),
		Rect2(1110, 610, 250, 150)
	]:
		var highlight := Polygon2D.new()
		highlight.polygon = PackedVector2Array([
			room.position,
			room.position + Vector2(room.size.x, 0),
			room.position + room.size,
			room.position + Vector2(0, room.size.y)
		])
		highlight.color = Color(0.15, 0.17, 0.2, 1.0)
		world.add_child(highlight)


func _build_walls() -> void:
	var wall_rects: Array[Rect2] = [
		Rect2(-32, -32, MAP_WIDTH + 64, 32),
		Rect2(-32, MAP_HEIGHT, MAP_WIDTH + 64, 32),
		Rect2(-32, 0, 32, MAP_HEIGHT),
		Rect2(MAP_WIDTH, 0, 32, MAP_HEIGHT),
		Rect2(340, 0, 32, 420),
		Rect2(340, 560, 32, 400),
		Rect2(710, 0, 32, 260),
		Rect2(710, 420, 32, 540),
		Rect2(1020, 0, 32, 560),
		Rect2(1020, 700, 32, 260),
		Rect2(300, 420, 260, 32),
		Rect2(540, 560, 180, 32),
		Rect2(740, 260, 220, 32),
		Rect2(880, 560, 220, 32),
		Rect2(1080, 300, 280, 32)
	]

	for rect in wall_rects:
		_spawn_wall(rect)


func _spawn_wall(rect: Rect2) -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = rect.position + rect.size * 0.5

	var shape := RectangleShape2D.new()
	shape.size = rect.size

	var collision := CollisionShape2D.new()
	collision.shape = shape
	wall.add_child(collision)

	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
		Vector2(-rect.size.x * 0.5, rect.size.y * 0.5)
	])
	polygon.color = Color(0.22, 0.23, 0.27, 1.0)
	wall.add_child(polygon)

	var occluder_polygon := OccluderPolygon2D.new()
	occluder_polygon.polygon = polygon.polygon

	var occluder := LightOccluder2D.new()
	occluder.occluder = occluder_polygon
	wall.add_child(occluder)

	world.add_child(wall)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(120, 200)
	world.add_child(player)
	camera.global_position = player.global_position


func _spawn_lights() -> void:
	var light_specs := [
		{
			"position": Vector2(170, 160),
			"color": Color(0.78, 0.88, 1.0, 1.0),
			"energy": 0.45,
			"flicker": true
		},
		{
			"position": Vector2(570, 170),
			"color": Color(0.85, 0.92, 1.0, 1.0),
			"energy": 0.7,
			"flicker": true
		},
		{
			"position": Vector2(1170, 170),
			"color": Color(1.0, 0.2, 0.18, 1.0),
			"energy": 0.55,
			"flicker": false
		},
		{
			"position": Vector2(420, 690),
			"color": Color(0.95, 0.35, 0.2, 1.0),
			"energy": 0.55,
			"flicker": true
		},
		{
			"position": Vector2(820, 580),
			"color": Color(0.8, 0.95, 1.0, 1.0),
			"energy": 0.65,
			"flicker": true
		}
	]

	for spec in light_specs:
		var light := LIGHT_SOURCE_SCENE.instantiate()
		light.global_position = spec["position"]
		light.light_color = spec["color"]
		light.light_energy = spec["energy"]
		light.flicker_enabled = spec["flicker"]
		environment_lights.add_child(light)


func _spawn_items() -> void:
	for item_position in [Vector2(605, 188), Vector2(1165, 640)]:
		var battery := BATTERY_SCENE.instantiate()
		battery.global_position = item_position
		items_root.add_child(battery)

	for item_position in [Vector2(404, 650), Vector2(1280, 780)]:
		var ammo := AMMO_SCENE.instantiate()
		ammo.global_position = item_position
		items_root.add_child(ammo)


func _spawn_hiding_spots() -> void:
	for spot_position in [Vector2(365, 710), Vector2(830, 635)]:
		var hiding_spot := HIDING_SPOT_SCENE.instantiate()
		hiding_spot.global_position = spot_position
		objects_root.add_child(hiding_spot)


func _spawn_exit() -> void:
	var exit_door := EXIT_DOOR_SCENE.instantiate()
	exit_door.global_position = Vector2(1480, 804)
	objects_root.add_child(exit_door)


func _spawn_enemies() -> void:
	var enemy_one = CREATURE_SCENE.instantiate()
	enemy_one.global_position = Vector2(555, 230)
	enemy_one.set("patrol_points", [
		Vector2(470, 170),
		Vector2(635, 175),
		Vector2(625, 360),
		Vector2(470, 360)
	])
	enemies_root.add_child(enemy_one)

	var enemy_two = CREATURE_SCENE.instantiate()
	enemy_two.global_position = Vector2(905, 625)
	enemy_two.set("patrol_points", [
		Vector2(805, 635),
		Vector2(960, 635),
		Vector2(960, 820),
		Vector2(805, 820)
	])
	enemies_root.add_child(enemy_two)
