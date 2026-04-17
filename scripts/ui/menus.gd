extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var center_panel: PanelContainer = $CenterPanel


func _ready() -> void:
	GameManager.run_state = "menu"
	GameManager.is_game_paused = false
	get_tree().paused = false
	_apply_button_theme()
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	GameManager.start_game()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _apply_button_theme() -> void:
	var primary_style := StyleBoxFlat.new()
	primary_style.bg_color = Color(0.63, 0.2, 0.2, 1.0)
	primary_style.border_color = Color(0.93, 0.72, 0.67, 0.85)
	primary_style.set_border_width_all(2)
	primary_style.set_corner_radius_all(8)

	var hover_style := primary_style.duplicate()
	hover_style.bg_color = Color(0.76, 0.28, 0.27, 1.0)

	var pressed_style := primary_style.duplicate()
	pressed_style.bg_color = Color(0.45, 0.13, 0.13, 1.0)

	var secondary_style := StyleBoxFlat.new()
	secondary_style.bg_color = Color(0.16, 0.12, 0.14, 0.95)
	secondary_style.border_color = Color(0.53, 0.32, 0.33, 0.75)
	secondary_style.set_border_width_all(2)
	secondary_style.set_corner_radius_all(8)

	start_button.add_theme_stylebox_override("normal", primary_style)
	start_button.add_theme_stylebox_override("hover", hover_style)
	start_button.add_theme_stylebox_override("pressed", pressed_style)
	start_button.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92, 1.0))
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.custom_minimum_size = Vector2(0.0, 52.0)

	quit_button.add_theme_stylebox_override("normal", secondary_style)
	quit_button.add_theme_stylebox_override("hover", hover_style)
	quit_button.add_theme_stylebox_override("pressed", pressed_style)
	quit_button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.9, 1.0))
	quit_button.add_theme_font_size_override("font_size", 18)
	quit_button.custom_minimum_size = Vector2(0.0, 46.0)

	center_panel.modulate = Color(1.0, 1.0, 1.0, 0.97)
