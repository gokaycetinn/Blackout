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
	primary_style.bg_color = Color(0.12, 0.37, 0.66, 1.0)
	primary_style.border_color = Color(0.65, 0.89, 1.0, 0.95)
	primary_style.set_border_width_all(2)
	primary_style.set_corner_radius_all(8)

	var hover_style := primary_style.duplicate()
	hover_style.bg_color = Color(0.18, 0.49, 0.82, 1.0)

	var pressed_style := primary_style.duplicate()
	pressed_style.bg_color = Color(0.08, 0.24, 0.45, 1.0)

	var secondary_style := StyleBoxFlat.new()
	secondary_style.bg_color = Color(0.08, 0.16, 0.26, 0.96)
	secondary_style.border_color = Color(0.41, 0.67, 0.89, 0.9)
	secondary_style.set_border_width_all(2)
	secondary_style.set_corner_radius_all(8)

	start_button.add_theme_stylebox_override("normal", primary_style)
	start_button.add_theme_stylebox_override("hover", hover_style)
	start_button.add_theme_stylebox_override("pressed", pressed_style)
	start_button.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0, 1.0))
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.custom_minimum_size = Vector2(0.0, 52.0)

	quit_button.add_theme_stylebox_override("normal", secondary_style)
	quit_button.add_theme_stylebox_override("hover", hover_style)
	quit_button.add_theme_stylebox_override("pressed", pressed_style)
	quit_button.add_theme_color_override("font_color", Color(0.87, 0.95, 1.0, 1.0))
	quit_button.add_theme_font_size_override("font_size", 18)
	quit_button.custom_minimum_size = Vector2(0.0, 46.0)

	center_panel.modulate = Color(1.0, 1.0, 1.0, 0.97)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.custom_minimum_size = Vector2(0.0, 52.0)

	quit_button.add_theme_stylebox_override("normal", secondary_style)
	quit_button.add_theme_stylebox_override("hover", hover_style)
	quit_button.add_theme_stylebox_override("pressed", pressed_style)
	quit_button.add_theme_color_override("font_color", Color(0.87, 0.95, 1.0, 1.0))
	quit_button.add_theme_font_size_override("font_size", 18)
	quit_button.custom_minimum_size = Vector2(0.0, 46.0)

	center_panel.modulate = Color(1.0, 1.0, 1.0, 0.97)
