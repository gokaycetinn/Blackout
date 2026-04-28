extends Node2D

@export var drain_rate: float = 1.0
@export var low_battery_threshold: float = 20.0
@export var base_energy: float = 1.3

@onready var light: PointLight2D = $PointLight2D
@onready var raycast: RayCast2D = $RayCast2D

var _target_rotation: float = 0.0
var _beam_sprite: Sprite2D


func _ready() -> void:
	# Hide the old static cone if it exists
	var old_cone = get_node_or_null("ConeVisual")
	if old_cone:
		old_cone.queue_free()

	_setup_beautiful_flashlight()
	_apply_state()


func _setup_beautiful_flashlight() -> void:
	# Generate a high-quality procedural cone texture
	var tex = _generate_cone_texture()
	
	# Apply to PointLight2D for environment lighting
	light.texture = tex
	light.texture_scale = 2.0
	light.position = Vector2(0, 0)
	light.offset = Vector2(256, 0) # Center the light projection
	light.shadow_enabled = true
	light.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = 1.5

	# Add a Sprite2D for the volumetric "fog" beam effect
	_beam_sprite = Sprite2D.new()
	_beam_sprite.texture = tex
	_beam_sprite.scale = Vector2(2.0, 2.0)
	_beam_sprite.position = Vector2(0, 0)
	_beam_sprite.offset = Vector2(256, 0)
	# Additive blending for a realistic light beam
	_beam_sprite.material = CanvasItemMaterial.new()
	_beam_sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam_sprite.modulate = Color(1.0, 0.95, 0.85, 0.12)
	_beam_sprite.z_index = 5
	add_child(_beam_sprite)


func _generate_cone_texture() -> ImageTexture:
	var size = 256
	var img = Image.create(size * 2, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, size / 2) # Light source anchor
	var max_dist = 450.0
	
	for y in range(size):
		for x in range(size * 2):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist > max_dist or x < center.x:
				continue
				
			var dir = (pos - center).normalized()
			var angle = abs(dir.angle())
			
			# Wide soft outer cone (28 degrees)
			if angle < deg_to_rad(28.0):
				var dist_att = 1.0 - (dist / max_dist)
				dist_att = pow(dist_att, 1.4) # Smooth falloff
				
				var angle_att = 1.0
				# Soft edge fade starting at 12 degrees
				if angle > deg_to_rad(12.0):
					angle_att = 1.0 - ((angle - deg_to_rad(12.0)) / deg_to_rad(16.0))
					angle_att = smoothstep(0.0, 1.0, angle_att)
				
				# Bright inner core (4 degrees)
				var core_boost = 0.0
				if angle < deg_to_rad(4.0):
					core_boost = 0.6 * (1.0 - (angle / deg_to_rad(4.0)))
				
				var intensity = clampf((dist_att * angle_att) + core_boost, 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, intensity))
				
	return ImageTexture.create_from_image(img)


func aim_at(target: Vector2) -> void:
	_target_rotation = (target - global_position).angle()


func toggle_flashlight() -> void:
	if GameManager.set_flashlight_on(not GameManager.is_flashlight_on):
		_apply_state()


func force_off() -> void:
	GameManager.set_flashlight_on(false)
	_apply_state()


func is_active() -> bool:
	return GameManager.is_flashlight_on and GameManager.battery_level > 0.0


func _process(delta: float) -> void:
	# Smooth flashlight rotation (lags behind slightly like a heavy flashlight)
	rotation = lerp_angle(rotation, _target_rotation, 16.0 * delta)

	if not is_active():
		_apply_state()
		return

	GameManager.consume_battery(drain_rate * delta)
	if GameManager.battery_level <= 0.0:
		force_off()
		return

	var energy := base_energy
	var beam_alpha := 0.12

	# Flicker when low battery
	if GameManager.battery_level <= low_battery_threshold:
		energy = randf_range(0.35, base_energy)
		beam_alpha = randf_range(0.04, 0.15)

	light.enabled = true
	light.energy = energy
	
	if _beam_sprite:
		_beam_sprite.visible = true
		_beam_sprite.modulate = Color(1.0, 0.95, 0.85, beam_alpha)

	raycast.force_raycast_update()
	var hit_distance := 512.0
	if raycast.is_colliding():
		hit_distance = global_position.distance_to(raycast.get_collision_point())
	
	# Shrink beam slightly if hitting a wall to prevent massive bleed-through
	var target_scale = clampf(hit_distance / 256.0, 0.4, 2.0)
	if _beam_sprite:
		_beam_sprite.scale.x = target_scale


func _apply_state() -> void:
	light.enabled = is_active()
	if _beam_sprite:
		_beam_sprite.visible = is_active()
