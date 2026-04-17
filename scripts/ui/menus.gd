extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	GameManager.run_state = "menu"
	GameManager.is_game_paused = false
	get_tree().paused = false
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	GameManager.start_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
