extends Node2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CREATURE_SCENE := preload("res://scenes/enemies/creature.tscn")
const BATTERY_SCENE := preload("res://scenes/items/battery.tscn")
const AMMO_SCENE := preload("res://scenes/items/ammo.tscn")
const HIDING_SPOT_SCENE := preload("res://scenes/objects/hiding_spot.tscn")
const EXIT_DOOR_SCENE := preload("res://scenes/objects/door_exit.tscn")
const LIGHT_SOURCE_SCENE := preload("res://scenes/objects/light_source.tscn")
const FACILITY_COMPUTERS = preload("res://assets/sci-fi-facility-asset-pack/computer_spritesheet.png")
const FACILITY_CRATES = preload("res://assets/sci-fi-facility-asset-pack/crates_spritesheet.png")
const FACILITY_DOODADS = preload("res://assets/sci-fi-facility-asset-pack/doodads_spritesheet.png")
const FACILITY_SCREEN = preload("res://assets/sci-fi-facility-asset-pack/computer_screen_large.png")
const FACILITY_NOTICE = preload("res://assets/sci-fi-facility-asset-pack/guard_notice.png")

const MAP_WIDTH := 1600.0
const MAP_HEIGHT := 960.0

@onready var world: Node2D = $World
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var decor_layer: TileMapLayer = $DecorLayer
@onready var environment_lights: Node2D = $EnvironmentLights
@onready var enemies_root: Node2D = $Enemies
@onready var items_root: Node2D = $Items
@onready var objects_root: Node2D = $Objects
@onready var camera: Camera2D = $Camera2D

var player: CharacterBody2D
var _camera_trauma: float = 0.0
var _camera_base_offset: Vector2 = Vector2.ZERO
var _tile_size: int = 32
var _tileset: TileSet


func _ready() -> void:
	GameManager.reset_run()
	GameManager.register_level(self)
	GameManager.screen_shake_requested.connect(_on_screen_shake)
	_setup_tile_layers()
	_build_floor()
	_build_walls()
	_spawn_player()
	_spawn_lights()
	_populate_environment()
	_spawn_items()
	_spawn_hiding_spots()
	_spawn_exit()
	_spawn_enemies()
	_camera_base_offset = camera.offset


func _process(delta: float) -> void:
	# Let Camera2D's built-in position_smoothing follow the player.
	# We just update offset for trauma/tension shake.
	if player:
		camera.global_position = camera.global_position.lerp(
			player.global_position, clampf(delta * 6.0, 0.0, 1.0)
		)
	AudioManager.set_tension_level(GameManager.current_detection / 100.0)
	_camera_trauma = maxf(_camera_trauma - delta * 2.2, 0.0)
	# Smooth oscillating shake — not jarring random every frame
	var t := Time.get_ticks_msec() / 1000.0
	var trauma_sq := _camera_trauma * _camera_trauma
	var tension_drift := GameManager.current_detection / 100.0 * 1.4
	camera.offset = _camera_base_offset + Vector2(
		sin(t * 18.0 + 0.3) * trauma_sq * 9.0 + sin(t * 3.1) * tension_drift,
		cos(t * 14.0 - 0.7) * trauma_sq * 7.0 + cos(t * 2.7) * tension_drift
	)


func _build_floor() -> void:
	var full_floor := Rect2(Vector2.ZERO, Vector2(MAP_WIDTH, MAP_HEIGHT))
	_paint_tile_region(ground_layer, full_floor, Vector2i(0, 0))

	for room in [
		Rect2(80, 110, 240, 170),
		Rect2(430, 100, 280, 190),
		Rect2(1080, 110, 270, 170),
		Rect2(280, 580, 240, 180),
		Rect2(640, 460, 270, 220),
		Rect2(1110, 610, 250, 150)
	]:
		_paint_tile_region(ground_layer, room, Vector2i(1, 0))
		_add_room_border(room, Color(0.19, 0.22, 0.26, 0.8))
		_add_room_grime(room)


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
	_paint_tile_region(wall_layer, rect, Vector2i(2, 0))
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

	var trim := Line2D.new()
	trim.width = 3.0
	trim.default_color = Color(0.32, 0.33, 0.37, 0.55)
	trim.points = PackedVector2Array([
		rect.position + Vector2(0.0, 2.0),
		rect.position + Vector2(rect.size.x, 2.0)
	])
	world.add_child(trim)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(120, 200)
	world.add_child(player)
	# Snap camera to player immediately, then let position_smoothing take over
	camera.global_position = player.global_position
	camera.position_smoothing_enabled = true


func _spawn_lights() -> void:
	var light_specs := [
		{
			"position": Vector2(170, 160),
			"color": Color(0.78, 0.88, 1.0, 1.0),
			"energy": 1.75,
			"flicker": false
		},
		{
			"position": Vector2(570, 170),
			"color": Color(0.85, 0.92, 1.0, 1.0),
			"energy": 1.9,
			"flicker": false
		},
		{
			"position": Vector2(1170, 170),
			"color": Color(1.0, 0.2, 0.18, 1.0),
			"energy": 1.75,
			"flicker": false
		},
		{
			"position": Vector2(420, 690),
			"color": Color(0.95, 0.35, 0.2, 1.0),
			"energy": 1.75,
			"flicker": false
		},
		{
			"position": Vector2(820, 580),
			"color": Color(0.8, 0.95, 1.0, 1.0),
			"energy": 1.9,
			"flicker": false
		},
		{
			"position": Vector2(1315, 700),
			"color": Color(0.7, 0.96, 1.0, 1.0),
			"energy": 1.85,
			"flicker": false
		},
		{
			"position": Vector2(700, 760),
			"color": Color(0.68, 0.9, 1.0, 1.0),
			"energy": 1.65,
			"flicker": false
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
	var enemy_specs := [
		{
			"position": Vector2(555, 230),
			"patrol": [Vector2(470, 160), Vector2(650, 165), Vector2(640, 360), Vector2(468, 355)],
			"patrol_speed": 46.0,
			"chase_speed": 132.0,
			"view_distance": 145.0,
			"attack_range": 14.0
		},
		{
			"position": Vector2(905, 625),
			"patrol": [Vector2(800, 630), Vector2(965, 630), Vector2(965, 825), Vector2(800, 825)],
			"patrol_speed": 49.0,
			"chase_speed": 140.0,
			"view_distance": 152.0,
			"attack_range": 15.0
		},
		{
			"position": Vector2(1280, 250),
			"patrol": [Vector2(1100, 180), Vector2(1390, 185), Vector2(1390, 390), Vector2(1100, 390)],
			"patrol_speed": 45.0,
			"chase_speed": 145.0,
			"view_distance": 155.0,
			"attack_range": 14.0
		},
		{
			"position": Vector2(200, 700),
			"patrol": [Vector2(95, 620), Vector2(320, 625), Vector2(310, 820), Vector2(95, 820)],
			"patrol_speed": 42.0,
			"chase_speed": 128.0,
			"view_distance": 140.0,
			"attack_range": 13.0
		}
	]

	for spec in enemy_specs:
		var enemy = CREATURE_SCENE.instantiate()
		enemy.global_position = spec["position"]
		enemy.set("patrol_points", spec["patrol"])
		enemy.set("patrol_speed", spec["patrol_speed"])
		enemy.set("chase_speed", spec["chase_speed"])
		enemy.set("base_view_distance", spec["view_distance"])
		enemy.set("attack_range", spec["attack_range"])
		enemies_root.add_child(enemy)



func _populate_environment() -> void:
	_add_stripe(Rect2(362, 420, 132, 32))
	_add_stripe(Rect2(1084, 300, 160, 32))
	_add_prop(Rect2(125, 136, 56, 26), Color(0.32, 0.34, 0.37, 1.0))
	_add_prop(Rect2(236, 136, 34, 18), Color(0.55, 0.43, 0.12, 1.0))
	_add_prop(Rect2(497, 125, 84, 26), Color(0.24, 0.29, 0.33, 1.0))
	_add_prop(Rect2(615, 120, 24, 60), Color(0.37, 0.23, 0.16, 1.0))
	_add_prop(Rect2(1124, 122, 62, 22), Color(0.29, 0.18, 0.2, 1.0))
	_add_prop(Rect2(1188, 124, 78, 18), Color(0.23, 0.26, 0.31, 1.0))
	_add_prop(Rect2(301, 636, 66, 66), Color(0.3, 0.21, 0.16, 1.0))
	_add_prop(Rect2(408, 642, 58, 28), Color(0.21, 0.24, 0.28, 1.0))
	_add_prop(Rect2(666, 502, 86, 26), Color(0.23, 0.27, 0.31, 1.0))
	_add_prop(Rect2(786, 542, 96, 36), Color(0.27, 0.19, 0.18, 1.0))
	_add_prop(Rect2(1158, 650, 78, 24), Color(0.24, 0.27, 0.33, 1.0))
	_add_prop(Rect2(1236, 730, 42, 64), Color(0.31, 0.2, 0.16, 1.0))
	_add_cable(PackedVector2Array([Vector2(80, 320), Vector2(180, 356), Vector2(295, 330), Vector2(410, 374)]))
	_add_cable(PackedVector2Array([Vector2(688, 810), Vector2(790, 790), Vector2(920, 812), Vector2(1045, 776)]))
	_add_decal(Rect2(548, 312, 62, 28), Color(0.35, 0.08, 0.08, 0.35))
	_add_decal(Rect2(879, 742, 54, 20), Color(0.3, 0.05, 0.05, 0.28))
	_add_decal(Rect2(1312, 190, 40, 18), Color(0.16, 0.2, 0.3, 0.22))
	_add_facility_screen(Vector2(210, 168), Color(0.5, 1.0, 0.92, 0.95))
	_add_facility_screen(Vector2(570, 168), Color(0.48, 0.82, 1.0, 0.92))
	_add_facility_screen(Vector2(1190, 168), Color(1.0, 0.45, 0.3, 0.9))
	_add_facility_notice(Vector2(1092, 156))
	_add_facility_notice(Vector2(690, 516))
	_add_facility_sprite(Vector2(257, 150), FACILITY_COMPUTERS, Rect2i(0, 0, 16, 16), 2.0)
	_add_facility_sprite(Vector2(530, 138), FACILITY_COMPUTERS, Rect2i(16, 0, 16, 16), 2.0)
	_add_facility_sprite(Vector2(1186, 138), FACILITY_COMPUTERS, Rect2i(32, 0, 16, 16), 2.0)
	_add_facility_sprite(Vector2(334, 690), FACILITY_CRATES, Rect2i(0, 0, 16, 16), 2.1)
	_add_facility_sprite(Vector2(442, 660), FACILITY_CRATES, Rect2i(16, 0, 16, 16), 2.1)
	_add_facility_sprite(Vector2(714, 522), FACILITY_CRATES, Rect2i(32, 0, 16, 16), 2.1)
	_add_facility_sprite(Vector2(830, 566), FACILITY_CRATES, Rect2i(48, 0, 16, 16), 2.1)
	_add_facility_sprite(Vector2(1210, 662), FACILITY_COMPUTERS, Rect2i(48, 0, 16, 16), 2.0)
	_add_facility_sprite(Vector2(1262, 752), FACILITY_DOODADS, Rect2i(16, 0, 16, 16), 2.0, Color(1.0, 0.95, 0.95, 0.92))
	_add_facility_sprite(Vector2(854, 744), FACILITY_DOODADS, Rect2i(48, 16, 16, 16), 1.8, Color(0.76, 1.0, 0.78, 0.9))


func _add_room_border(room: Rect2, border_color: Color) -> void:
	var outline := Line2D.new()
	outline.width = 2.0
	outline.default_color = border_color
	outline.closed = true
	outline.points = PackedVector2Array([
		room.position,
		room.position + Vector2(room.size.x, 0.0),
		room.position + room.size,
		room.position + Vector2(0.0, room.size.y)
	])
	world.add_child(outline)


func _add_room_grime(room: Rect2) -> void:
	for i in range(4):
		var stain := Polygon2D.new()
		var stain_size := Vector2(randf_range(20.0, 58.0), randf_range(10.0, 34.0))
		var stain_position := room.position + Vector2(
			randf_range(18.0, room.size.x - 18.0),
			randf_range(18.0, room.size.y - 18.0)
		)
		stain.position = stain_position
		stain.color = Color(0.07, 0.08, 0.09, randf_range(0.18, 0.34))
		stain.polygon = PackedVector2Array([
			Vector2(-stain_size.x * 0.5, -stain_size.y * 0.4),
			Vector2(stain_size.x * 0.5, -stain_size.y * 0.2),
			Vector2(stain_size.x * 0.35, stain_size.y * 0.5),
			Vector2(-stain_size.x * 0.45, stain_size.y * 0.35)
		])
		world.add_child(stain)


func _add_prop(rect: Rect2, color: Color) -> void:
	var prop := StaticBody2D.new()
	prop.collision_layer = 1
	prop.collision_mask = 0
	prop.position = rect.position + rect.size * 0.5

	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	prop.add_child(collision)

	var fill := Polygon2D.new()
	fill.color = color
	fill.polygon = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
		Vector2(-rect.size.x * 0.5, rect.size.y * 0.5)
	])
	prop.add_child(fill)

	world.add_child(prop)
	_paint_tile_region(decor_layer, rect.grow(2.0), Vector2i(3, 0))


func _add_stripe(rect: Rect2) -> void:
	for index in range(6):
		var band := Polygon2D.new()
		var stripe_width := rect.size.x / 6.0
		var x0 := rect.position.x + stripe_width * index
		band.color = Color(0.8, 0.64, 0.15, 0.75) if index % 2 == 0 else Color(0.16, 0.15, 0.15, 0.85)
		band.polygon = PackedVector2Array([
			Vector2(x0, rect.position.y),
			Vector2(x0 + stripe_width, rect.position.y),
			Vector2(x0 + stripe_width, rect.position.y + rect.size.y),
			Vector2(x0, rect.position.y + rect.size.y)
		])
		world.add_child(band)


func _add_cable(points: PackedVector2Array) -> void:
	var cable := Line2D.new()
	cable.width = 4.0
	cable.default_color = Color(0.06, 0.06, 0.07, 0.75)
	cable.points = points
	world.add_child(cable)


func _add_decal(rect: Rect2, color: Color) -> void:
	var decal := Polygon2D.new()
	decal.color = color
	decal.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
	])
	world.add_child(decal)


func _add_facility_screen(position: Vector2, tint: Color) -> void:
	var screen: Sprite2D = Sprite2D.new()
	screen.texture = FACILITY_SCREEN
	screen.position = position
	screen.centered = true
	screen.scale = Vector2.ONE * 0.34
	screen.modulate = tint
	screen.z_index = 1
	world.add_child(screen)


func _add_facility_notice(position: Vector2) -> void:
	var sign: Sprite2D = Sprite2D.new()
	sign.texture = FACILITY_NOTICE
	sign.position = position
	sign.centered = true
	sign.scale = Vector2.ONE * 1.8
	sign.modulate = Color(1.0, 0.92, 0.92, 0.95)
	sign.z_index = 1
	world.add_child(sign)


func _add_facility_sprite(position: Vector2, texture: Texture2D, region_rect: Rect2i, scale_factor: float, tint: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = _create_atlas_texture(texture, region_rect)
	sprite.position = position
	sprite.centered = true
	sprite.scale = Vector2.ONE * scale_factor
	sprite.modulate = tint
	sprite.z_index = 1
	world.add_child(sprite)


func _create_atlas_texture(texture: Texture2D, region_rect: Rect2i) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(region_rect.position, region_rect.size)
	return atlas


func _on_screen_shake(intensity: float) -> void:
	_camera_trauma = minf(_camera_trauma + intensity, 1.6)


func _setup_tile_layers() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(_tile_size, _tile_size)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = PrototypeArt.create_tilesheet(_tile_size)
	atlas.texture_region_size = Vector2i(_tile_size, _tile_size)

	for atlas_x in range(4):
		atlas.create_tile(Vector2i(atlas_x, 0))

	_tileset.add_source(atlas, 0)
	ground_layer.tile_set = _tileset
	wall_layer.tile_set = _tileset
	decor_layer.tile_set = _tileset
	ground_layer.y_sort_enabled = false
	wall_layer.y_sort_enabled = false
	decor_layer.y_sort_enabled = false


func _paint_tile_region(layer: TileMapLayer, rect: Rect2, atlas_coords: Vector2i) -> void:
	var start := Vector2i(floori(rect.position.x / _tile_size), floori(rect.position.y / _tile_size))
	var end := Vector2i(ceili((rect.position.x + rect.size.x) / _tile_size), ceili((rect.position.y + rect.size.y) / _tile_size))

	for tile_x in range(start.x, end.x):
		for tile_y in range(start.y, end.y):
			layer.set_cell(Vector2i(tile_x, tile_y), 0, atlas_coords)
