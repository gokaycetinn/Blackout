extends CanvasLayer

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@onready var battery_bar: ProgressBar = %BatteryBar
@onready var ammo_value: Label = %AmmoValue
@onready var detection_label: Label = %DetectionLabel
@onready var stealth_value: Label = %StealthValue
@onready var prompt_label: Label = %PromptLabel
@onready var warning_rect: ColorRect = %DetectionWarning
@onready var crosshair: Control = %Crosshair
@onready var pause_panel: PanelContainer = %PausePanel
@onready var fail_panel: PanelContainer = %FailPanel
@onready var win_panel: PanelContainer = %WinPanel
@onready var fail_reason_label: Label = %FailReason
@onready var restart_buttons: Array[Button] = [%PauseRestartButton, %FailRestartButton, %WinRestartButton]
@onready var menu_buttons: Array[Button] = [%PauseMenuButton, %FailMenuButton, %WinMenuButton]
@onready var top_left_panel: PanelContainer = %TopLeftPanel
@onready var stealth_box: PanelContainer = %StealthBox
@onready var pause_panel_container: PanelContainer = %PausePanel
@onready var fail_panel_container: PanelContainer = %FailPanel
@onready var win_panel_container: PanelContainer = %WinPanel
@onready var health_bar_container: HBoxContainer = %HealthBar

# Kalp ikonları dizisi (ProgressBar yerine)
var _heart_icons: Array[ColorRect] = []
var _max_health: int = 3


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_apply_skin()
	GameManager.battery_changed.connect(_on_battery_changed)
	GameManager.ammo_changed.connect(_on_ammo_changed)
	GameManager.detection_changed.connect(_on_detection_changed)
	GameManager.interact_prompt_changed.connect(_on_prompt_changed)
	GameManager.pause_changed.connect(_on_pause_changed)
	GameManager.player_died.connect(_on_player_died)
	GameManager.level_completed.connect(_on_level_completed)
	GameManager.health_changed.connect(_on_health_changed)

	for button in restart_buttons:
		button.pressed.connect(_on_restart_pressed)
	for button in menu_buttons:
		button.pressed.connect(_on_menu_pressed)

	_on_battery_changed(GameManager.battery_level)
	_on_ammo_changed(GameManager.ammo_count)
	_on_detection_changed(GameManager.current_detection)
	_on_prompt_changed(GameManager.current_prompt)
	_on_pause_changed(false)
	_build_health_icons(GameManager.HEALTH_MAX)
	_on_health_changed(GameManager.player_health, GameManager.HEALTH_MAX)


func _build_health_icons(max_hp: int) -> void:
	_max_health = max_hp
	# Eski ikonları temizle
	for child in health_bar_container.get_children():
		child.queue_free()
	_heart_icons.clear()

	for i in range(max_hp):
		var heart := ColorRect.new()
		heart.custom_minimum_size = Vector2(20, 20)
		heart.color = Color(0.9, 0.18, 0.18, 1.0)
		# Yuvarlak köşe için StyleBoxFlat kullan
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.9, 0.18, 0.18, 1.0)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_left = 4
		sb.corner_radius_bottom_right = 4
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(1.0, 0.5, 0.5, 0.8)
		heart.add_theme_stylebox_override("panel", sb)
		health_bar_container.add_child(heart)
		_heart_icons.append(heart)


func _on_health_changed(value: int, max_value: int) -> void:
	if _heart_icons.size() != max_value:
		_build_health_icons(max_value)

	for i in range(_heart_icons.size()):
		var heart := _heart_icons[i]
		if i < value:
			# Dolu kalp - kırmızı parlak
			heart.color = Color(0.95, 0.22, 0.22, 1.0)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.95, 0.22, 0.22, 1.0)
			sb.corner_radius_top_left = 4
			sb.corner_radius_top_right = 4
			sb.corner_radius_bottom_left = 4
			sb.corner_radius_bottom_right = 4
			sb.border_width_left = 1
			sb.border_width_right = 1
			sb.border_width_top = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(1.0, 0.6, 0.6, 1.0)
			heart.add_theme_stylebox_override("panel", sb)
			# Küçük pulse animasyonu
			var tw := create_tween()
			tw.tween_property(heart, "modulate", Color(1.3, 1.0, 1.0, 1.0), 0.12)
			tw.tween_property(heart, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
		else:
			# Boş kalp - koyu gri
			heart.color = Color(0.2, 0.08, 0.08, 1.0)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.08, 0.08, 1.0)
			sb.corner_radius_top_left = 4
			sb.corner_radius_top_right = 4
			sb.corner_radius_bottom_left = 4
			sb.corner_radius_bottom_right = 4
			sb.border_width_left = 1
			sb.border_width_right = 1
			sb.border_width_top = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.5, 0.2, 0.2, 0.6)
			heart.add_theme_stylebox_override("panel", sb)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		if fail_panel.visible or win_panel.visible:
			return
		GameManager.toggle_pause()


func _process(_delta: float) -> void:
	# Stealth durumu - GameManager'dan direkt oku (daha güvenilir)
	if GameManager.run_state != "playing":
		stealth_value.text = "---"
		stealth_value.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	elif GameManager.is_hidden:
		stealth_value.text = "Hidden"
		stealth_value.add_theme_color_override("font_color", Color(0.42, 0.92, 0.62, 1.0))
	else:
		var player = GameManager.player
		var crouching: bool = false
		if player != null:
			crouching = bool(player.get("is_crouching"))
		if crouching:
			stealth_value.text = "Crouched"
			stealth_value.add_theme_color_override("font_color", Color(0.96, 0.85, 0.32, 1.0))
		else:
			stealth_value.text = "Exposed"
			stealth_value.add_theme_color_override("font_color", Color(0.96, 0.42, 0.28, 1.0))

	if crosshair:
		crosshair.position = get_viewport().get_mouse_position()


func _on_battery_changed(value: float) -> void:
	battery_bar.value = value
	# Pürüzsüz renk geçişi
	if value > 60.0:
		battery_bar.modulate = Color(0.38, 0.93, 0.56, 1.0)
	elif value > 25.0:
		battery_bar.modulate = Color(0.96, 0.82, 0.22, 1.0)
	else:
		battery_bar.modulate = Color(0.96, 0.28, 0.22, 1.0)
		# Düşük batarya flash
		if value <= 10.0:
			var tw := create_tween()
			tw.tween_property(battery_bar, "modulate:a", 0.4, 0.3)
			tw.tween_property(battery_bar, "modulate:a", 1.0, 0.3)


func _on_ammo_changed(value: int) -> void:
	ammo_value.text = "x %d" % value
	if value == 0:
		ammo_value.add_theme_color_override("font_color", Color(0.96, 0.28, 0.22, 1.0))
	elif value <= 2:
		ammo_value.add_theme_color_override("font_color", Color(0.96, 0.72, 0.22, 1.0))
	else:
		ammo_value.add_theme_color_override("font_color", Color(1.0, 0.9, 0.65, 1.0))


func _on_detection_changed(value: float) -> void:
	warning_rect.modulate.a = clampf(value / 100.0, 0.0, 0.45)
	if value >= 90.0:
		detection_label.text = "⚠ LOCKED"
		detection_label.add_theme_color_override("font_color", Color(1.0, 0.18, 0.18, 1.0))
	elif value >= 45.0:
		detection_label.text = "● SEEN"
		detection_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.22, 1.0))
	else:
		detection_label.text = "✔ CLEAR"
		detection_label.add_theme_color_override("font_color", Color(0.38, 0.9, 0.56, 1.0))


func _on_prompt_changed(text: String) -> void:
	prompt_label.visible = not text.is_empty()
	prompt_label.text = text


func _on_pause_changed(paused: bool) -> void:
	pause_panel.visible = paused


func _on_player_died(reason: String) -> void:
	fail_panel.visible = true
	pause_panel.visible = false
	fail_reason_label.text = reason


func _on_level_completed() -> void:
	win_panel.visible = true
	pause_panel.visible = false


func _on_restart_pressed() -> void:
	GameManager.restart_level()


func _on_menu_pressed() -> void:
	GameManager.return_to_menu()


func _apply_skin() -> void:
	var dark_panel := PrototypeArt.create_stylebox(
		Color(0.05, 0.055, 0.07, 0.92),
		Color(0.28, 0.31, 0.38, 0.95),
		2,
		12,
		Color(0, 0, 0, 0.45)
	)
	var modal_panel := PrototypeArt.create_stylebox(
		Color(0.04, 0.045, 0.055, 0.94),
		Color(0.56, 0.18, 0.16, 0.95),
		2,
		14,
		Color(0, 0, 0, 0.55)
	)

	top_left_panel.add_theme_stylebox_override("panel", dark_panel)
	stealth_box.add_theme_stylebox_override("panel", dark_panel.duplicate())
	pause_panel_container.add_theme_stylebox_override("panel", modal_panel)
	fail_panel_container.add_theme_stylebox_override("panel", modal_panel.duplicate())
	win_panel_container.add_theme_stylebox_override("panel", PrototypeArt.create_stylebox(
		Color(0.04, 0.055, 0.055, 0.94),
		Color(0.2, 0.54, 0.42, 0.95),
		2,
		14,
		Color(0, 0, 0, 0.45)
	))
