extends CanvasLayer

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


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	GameManager.battery_changed.connect(_on_battery_changed)
	GameManager.ammo_changed.connect(_on_ammo_changed)
	GameManager.detection_changed.connect(_on_detection_changed)
	GameManager.interact_prompt_changed.connect(_on_prompt_changed)
	GameManager.pause_changed.connect(_on_pause_changed)
	GameManager.player_died.connect(_on_player_died)
	GameManager.level_completed.connect(_on_level_completed)

	for button in restart_buttons:
		button.pressed.connect(_on_restart_pressed)
	for button in menu_buttons:
		button.pressed.connect(_on_menu_pressed)

	_on_battery_changed(GameManager.battery_level)
	_on_ammo_changed(GameManager.ammo_count)
	_on_detection_changed(GameManager.current_detection)
	_on_prompt_changed(GameManager.current_prompt)
	_on_pause_changed(false)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		if fail_panel.visible or win_panel.visible:
			return
		GameManager.toggle_pause()


func _process(_delta: float) -> void:
	var player := GameManager.player
	if player and player.has_method("is_hidden_state") and player.is_hidden_state():
		stealth_value.text = "Hidden"
	elif player and player.get("is_crouching"):
		stealth_value.text = "Crouched"
	else:
		stealth_value.text = "Exposed"

	if crosshair:
		crosshair.position = get_viewport().get_mouse_position()


func _on_battery_changed(value: float) -> void:
	battery_bar.value = value
	if value > 50.0:
		battery_bar.modulate = Color(0.38, 0.93, 0.56, 1.0)
	elif value > 20.0:
		battery_bar.modulate = Color(0.96, 0.82, 0.22, 1.0)
	else:
		battery_bar.modulate = Color(0.96, 0.28, 0.22, 1.0)


func _on_ammo_changed(value: int) -> void:
	ammo_value.text = "x %d" % value


func _on_detection_changed(value: float) -> void:
	warning_rect.modulate.a = clampf(value / 100.0, 0.0, 0.45)
	if value >= 90.0:
		detection_label.text = "LOCKED"
	elif value >= 45.0:
		detection_label.text = "SEEN"
	else:
		detection_label.text = "CLEAR"


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
