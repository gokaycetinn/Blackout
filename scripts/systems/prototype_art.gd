extends RefCounted


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


static func create_player_texture() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for x in range(9, 23):
		for y in range(8, 24):
			image.set_pixel(x, y, Color(0.58, 0.72, 0.62, 1.0))

	for x in range(12, 20):
		for y in range(4, 10):
			image.set_pixel(x, y, Color(0.75, 0.79, 0.76, 1.0))

	for x in range(14, 18):
		for y in range(0, 8):
			image.set_pixel(x, y, Color(0.88, 0.92, 0.84, 1.0))

	for x in range(14, 18):
		for y in range(24, 30):
			image.set_pixel(x, y, Color(0.18, 0.22, 0.24, 1.0))

	for x in range(8, 24):
		image.set_pixel(x, 24, Color(0.12, 0.16, 0.18, 1.0))

	return ImageTexture.create_from_image(image)


static func create_creature_texture() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	for x in range(7, 25):
		for y in range(10, 26):
			image.set_pixel(x, y, Color(0.48, 0.09, 0.08, 1.0))

	for x in range(10, 22):
		for y in range(5, 12):
			image.set_pixel(x, y, Color(0.64, 0.12, 0.1, 1.0))

	image.set_pixel(12, 12, Color(1.0, 0.18, 0.12, 1.0))
	image.set_pixel(19, 12, Color(1.0, 0.18, 0.12, 1.0))

	for x in range(8, 24):
		image.set_pixel(x, 26, Color(0.15, 0.03, 0.03, 1.0))

	return ImageTexture.create_from_image(image)


static func create_tilesheet(tile_size: int = 32) -> Texture2D:
	var image := Image.create(tile_size * 4, tile_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	_fill_tile(image, Rect2i(0, 0, tile_size, tile_size), Color(0.105, 0.113, 0.125, 1.0), Color(0.145, 0.152, 0.164, 1.0), 4)
	_fill_tile(image, Rect2i(tile_size, 0, tile_size, tile_size), Color(0.13, 0.138, 0.152, 1.0), Color(0.172, 0.18, 0.196, 1.0), 8)
	_fill_tile(image, Rect2i(tile_size * 2, 0, tile_size, tile_size), Color(0.23, 0.24, 0.27, 1.0), Color(0.31, 0.32, 0.35, 1.0), 0)
	_fill_tile(image, Rect2i(tile_size * 3, 0, tile_size, tile_size), Color(0.17, 0.08, 0.08, 0.8), Color(0.35, 0.1, 0.1, 0.85), 5)

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


static func _fill_tile(image: Image, rect: Rect2i, fill: Color, accent: Color, stripe_step: int) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			image.set_pixel(x, y, fill)
			if stripe_step > 0 and ((x - rect.position.x + y - rect.position.y) % stripe_step == 0):
				image.set_pixel(x, y, accent)
			if x == rect.position.x or y == rect.position.y or x == rect.position.x + rect.size.x - 1 or y == rect.position.y + rect.size.y - 1:
				image.set_pixel(x, y, accent.darkened(0.2))
