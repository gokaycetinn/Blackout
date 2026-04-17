extends RefCounted

## Programmatic art generator — used as fallback when real assets aren't loaded.
## When you add real sprites from your sci-fi asset pack, update the
## create_player_texture() / create_creature_texture() functions to point
## to the real asset paths.


static func create_rect_texture(size: Vector2i, fill: Color, border: Color = Color(0, 0, 0, 0), border_size: int = 2, accent: Color = Color(0, 0, 0, 0), accent_rect: Rect2i = Rect2i()) -> Texture2D:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(fill)

	if border.a > 0.0 and border_size > 0:
		for x in range(size.x):
			for y in range(size.y):
				if x < border_size or y < border_size or x >= size.x - border_size or y >= size.y - border_size:
					image.set_pixel(x, y, border)

	if accent.a > 0.0 and accent_rect.size.x > 0 and accent_rect.size.y > 0:
		for x in range(accent_rect.position.x, accent_rect.position.x + accent_rect.size.x):
			for y in range(accent_rect.position.y, accent_rect.position.y + accent_rect.size.y):
				if x >= 0 and y >= 0 and x < size.x and y < size.y:
					image.set_pixel(x, y, accent)

	return ImageTexture.create_from_image(image)


static func create_circle_texture(size: Vector2i, fill: Color, ring: Color = Color(0, 0, 0, 0), ring_width: float = 2.0) -> Texture2D:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size.x, size.y) * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 1.0

	for x in range(size.x):
		for y in range(size.y):
			var pixel_position := Vector2(x + 0.5, y + 0.5)
			var distance := pixel_position.distance_to(center)
			if distance <= radius:
				image.set_pixel(x, y, fill)
			if ring.a > 0.0 and distance >= radius - ring_width and distance <= radius:
				image.set_pixel(x, y, ring)

	return ImageTexture.create_from_image(image)


## ─── Player ────────────────────────────────────────────────────────────────
## Replace this path with your sci-fi asset pack sprite when ready:
## e.g.  return load("res://assets/sprites/player/player_idle.png")
static func create_player_texture() -> Texture2D:
	var real_path: String = "res://assets/sprites/player/player.png"
	if ResourceLoader.exists(real_path):
		return load(real_path) as Texture2D
	# Fallback procedural
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	# Outer suit — teal-grey
	for x in range(8, 24):
		for y in range(8, 26):
			var dist_x: float = float(abs(x - 16)) / 8.0
			var dist_y: float = float(y - 17) / 9.0
			if dist_x * dist_x + dist_y * dist_y < 1.0:
				image.set_pixel(x, y, Color(0.30, 0.44, 0.42, 1.0))

	# Helmet / head
	for x in range(11, 21):
		for y in range(3, 12):
			var cx: float = 15.5
			var cy: float = 7.5
			if (float(x) - cx) * (float(x) - cx) + (float(y) - cy) * (float(y) - cy) < 22.0:
				image.set_pixel(x, y, Color(0.52, 0.65, 0.62, 1.0))

	# Visor
	for x in range(13, 19):
		for y in range(5, 9):
			image.set_pixel(x, y, Color(0.38, 0.82, 0.88, 0.92))

	# Visor glint
	image.set_pixel(13, 5, Color(0.85, 0.96, 1.0, 0.95))
	image.set_pixel(14, 5, Color(0.85, 0.96, 1.0, 0.75))

	# Shoulder pads
	for x in range(5, 10):
		for y in range(10, 14):
			image.set_pixel(x, y, Color(0.22, 0.32, 0.30, 1.0))
	for x in range(22, 27):
		for y in range(10, 14):
			image.set_pixel(x, y, Color(0.22, 0.32, 0.30, 1.0))

	# Chest accent stripe
	for x in range(13, 19):
		image.set_pixel(x, 14, Color(0.4, 0.92, 0.82, 0.9))

	# Belt / waist
	for x in range(9, 23):
		image.set_pixel(x, 20, Color(0.18, 0.22, 0.22, 1.0))

	# Legs
	for x in range(10, 15):
		for y in range(22, 30):
			image.set_pixel(x, y, Color(0.20, 0.30, 0.28, 1.0))
	for x in range(17, 22):
		for y in range(22, 30):
			image.set_pixel(x, y, Color(0.20, 0.30, 0.28, 1.0))

	# Boots
	for x in range(9, 15):
		image.set_pixel(x, 29, Color(0.12, 0.14, 0.14, 1.0))
	for x in range(17, 23):
		image.set_pixel(x, 29, Color(0.12, 0.14, 0.14, 1.0))

	return ImageTexture.create_from_image(image)


## ─── Creature ───────────────────────────────────────────────────────────────
## Replace with your asset pack's monster sprite when ready:
## e.g.  return load("res://assets/sprites/enemies/creature.png")
static func create_creature_texture() -> Texture2D:
	var real_path: String = "res://assets/sprites/enemies/creature.png"
	if ResourceLoader.exists(real_path):
		return load(real_path) as Texture2D
	# Fallback procedural — asymmetric, organic horror shape
	var image := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	# Main body blob — irregular
	for x in range(36):
		for y in range(36):
			var cx: float = 18.0
			var cy: float = 19.0
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			# Asymmetric distortion
			var r_sq: float = dx * dx * 0.9 + dy * dy + sin(dx * 0.4) * 3.0
			if r_sq < 92.0:
				var darkness: float = clampf(r_sq / 92.0, 0.0, 1.0)
				image.set_pixel(x, y, Color(
					lerpf(0.72, 0.28, darkness),
					lerpf(0.08, 0.02, darkness),
					lerpf(0.08, 0.02, darkness),
					1.0
				))

	# Head — bulge toward facing direction (right)
	for x in range(20, 34):
		for y in range(12, 24):
			var cx: float = 28.0
			var cy: float = 18.0
			if (float(x) - cx) * (float(x) - cx) + (float(y) - cy) * (float(y) - cy) < 42.0:
				image.set_pixel(x, y, Color(0.78, 0.10, 0.10, 1.0))

	# Eyes — glowing red
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			image.set_pixel(clamp(25 + dx, 0, 35), clamp(15 + dy, 0, 35), Color(1.0, 0.9, 0.1, 1.0))
			image.set_pixel(clamp(25 + dx, 0, 35), clamp(21 + dy, 0, 35), Color(1.0, 0.9, 0.1, 1.0))

	# Claws / limbs
	for i in range(3):
		var claw_x: int = 5 + i * 3
		image.set_pixel(claw_x, 8, Color(0.45, 0.06, 0.06, 0.85))
		image.set_pixel(claw_x - 1, 9, Color(0.45, 0.06, 0.06, 0.75))
		image.set_pixel(claw_x, 28, Color(0.45, 0.06, 0.06, 0.85))
		image.set_pixel(claw_x - 1, 27, Color(0.45, 0.06, 0.06, 0.75))

	return ImageTexture.create_from_image(image)


## ─── Tilesheet ──────────────────────────────────────────────────────────────
## Replace with your sci-fi tileset when ready:
## e.g.  return load("res://assets/sprites/tiles/sci_fi_floor.png")
static func create_tilesheet(tile_size: int = 32) -> Texture2D:
	var real_path: String = "res://assets/sprites/tiles/tileset.png"
	if ResourceLoader.exists(real_path):
		return load(real_path) as Texture2D

	var image := Image.create(tile_size * 4, tile_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	# Tile 0 — base metal floor
	_fill_sci_fi_tile(image, Rect2i(0, 0, tile_size, tile_size),
		Color(0.085, 0.092, 0.105, 1.0), Color(0.13, 0.14, 0.16, 1.0), 6)

	# Tile 1 — room interior floor (brighter)
	_fill_sci_fi_tile(image, Rect2i(tile_size, 0, tile_size, tile_size),
		Color(0.108, 0.115, 0.130, 1.0), Color(0.160, 0.168, 0.185, 1.0), 0)

	# Tile 2 — wall
	_fill_sci_fi_tile(image, Rect2i(tile_size * 2, 0, tile_size, tile_size),
		Color(0.190, 0.200, 0.225, 1.0), Color(0.260, 0.272, 0.300, 1.0), 3)

	# Tile 3 — hazard/accent (red-tinted)
	_fill_sci_fi_tile(image, Rect2i(tile_size * 3, 0, tile_size, tile_size),
		Color(0.155, 0.068, 0.068, 0.90), Color(0.310, 0.090, 0.090, 0.95), 4)

	return ImageTexture.create_from_image(image)


static func create_stylebox(bg: Color, border: Color, border_width: int = 2, radius: int = 6, shadow: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = shadow
	style.shadow_size = 8 if shadow.a > 0.0 else 0
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func _fill_sci_fi_tile(image: Image, rect: Rect2i, fill: Color, accent: Color, stripe_step: int) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			image.set_pixel(x, y, fill)
			# Subtle cross-hatch panel lines
			if stripe_step > 0 and ((x - rect.position.x) % stripe_step == 0 or (y - rect.position.y) % stripe_step == 0):
				if (x - rect.position.x) % stripe_step == 0 and (y - rect.position.y) % stripe_step == 0:
					image.set_pixel(x, y, accent)
				else:
					image.set_pixel(x, y, fill.lerp(accent, 0.35))
			# Border
			if x == rect.position.x or y == rect.position.y or \
			   x == rect.position.x + rect.size.x - 1 or \
			   y == rect.position.y + rect.size.y - 1:
				image.set_pixel(x, y, accent.darkened(0.25))
