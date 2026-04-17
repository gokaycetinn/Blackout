extends Node

const PlayerController = preload("res://scripts/player/player.gd")

signal battery_changed(value: float)
signal ammo_changed(value: int)
signal flashlight_toggled(is_on: bool)
signal detection_changed(value: float)
signal interact_prompt_changed(text: String)
signal player_died(reason: String)
signal level_completed
signal hide_state_changed(hidden: bool)
signal pause_changed(paused: bool)
signal global_noise_emitted(position: Vector2, strength: float)
signal gunshot_fired(position: Vector2)

const LEVEL_SCENE := "res://scenes/levels/level_01.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const BATTERY_MAX := 100.0

var battery_level: float = BATTERY_MAX
var ammo_count: int = 6
var is_flashlight_on: bool = false
var is_game_paused: bool = false
var is_hidden: bool = false
var current_detection: float = 0.0
var current_prompt: String = ""
var run_state: String = "menu"

var player: PlayerController = null
var level = null

var _detection_sources: Dictionary = {}


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_ensure_input_map()


func _ensure_input_map() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("run", KEY_SHIFT)
	_add_key_action("crouch", KEY_CTRL)
	_add_key_action("toggle_flashlight", KEY_F)
	_add_key_action("interact", KEY_E)
	_add_key_action("pause", KEY_ESCAPE)
	_add_mouse_action("fire", MOUSE_BUTTON_LEFT)


func _add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _add_mouse_action(action_name: String, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func register_player(player_node: PlayerController) -> void:
	player = player_node
	battery_changed.emit(battery_level)
	ammo_changed.emit(ammo_count)
	flashlight_toggled.emit(is_flashlight_on)
	hide_state_changed.emit(is_hidden)
	detection_changed.emit(current_detection)
	interact_prompt_changed.emit(current_prompt)


func register_level(level_node: Node) -> void:
	level = level_node


func reset_run() -> void:
	battery_level = BATTERY_MAX
	ammo_count = 6
	is_flashlight_on = false
	is_hidden = false
	current_detection = 0.0
	current_prompt = ""
	run_state = "playing"
	is_game_paused = false
	_detection_sources.clear()
	get_tree().paused = false
	battery_changed.emit(battery_level)
	ammo_changed.emit(ammo_count)
	flashlight_toggled.emit(is_flashlight_on)
	hide_state_changed.emit(is_hidden)
	detection_changed.emit(current_detection)
	interact_prompt_changed.emit(current_prompt)
	pause_changed.emit(false)


func set_flashlight_on(value: bool) -> bool:
	if value and battery_level <= 0.0:
		return false
	is_flashlight_on = value
	flashlight_toggled.emit(is_flashlight_on)
	return true


func consume_battery(amount: float) -> float:
	battery_level = clampf(battery_level - amount, 0.0, BATTERY_MAX)
	battery_changed.emit(battery_level)
	if battery_level <= 0.0 and is_flashlight_on:
		set_flashlight_on(false)
	return battery_level


func add_battery(amount: float) -> void:
	battery_level = clampf(battery_level + amount, 0.0, BATTERY_MAX)
	battery_changed.emit(battery_level)


func consume_ammo(amount: int = 1) -> bool:
	if ammo_count < amount:
		return false
	ammo_count -= amount
	ammo_changed.emit(ammo_count)
	return true


func add_ammo(amount: int) -> void:
	ammo_count = max(ammo_count + amount, 0)
	ammo_changed.emit(ammo_count)


func set_hidden(hidden: bool) -> void:
	is_hidden = hidden
	hide_state_changed.emit(hidden)


func set_interact_prompt(text: String) -> void:
	current_prompt = text
	interact_prompt_changed.emit(text)


func report_detection(source: Node, value: float) -> void:
	if source == null:
		return
	_detection_sources[source.get_instance_id()] = clampf(value, 0.0, 100.0)
	_refresh_detection()


func clear_detection_source(source: Node) -> void:
	if source == null:
		return
	_detection_sources.erase(source.get_instance_id())
	_refresh_detection()


func _refresh_detection() -> void:
	var highest := 0.0
	for entry in _detection_sources.values():
		highest = maxf(highest, float(entry))
	current_detection = highest
	detection_changed.emit(current_detection)


func emit_noise(position: Vector2, strength: float) -> void:
	global_noise_emitted.emit(position, strength)


func emit_gunshot(position: Vector2) -> void:
	gunshot_fired.emit(position)
	emit_noise(position, 900.0)


func request_game_over(reason: String = "The creatures found you.") -> void:
	if run_state != "playing":
		return
	run_state = "failed"
	is_game_paused = false
	get_tree().paused = false
	player_died.emit(reason)


func request_level_complete() -> void:
	if run_state != "playing":
		return
	run_state = "won"
	is_game_paused = false
	get_tree().paused = false
	level_completed.emit()


func toggle_pause() -> void:
	if run_state != "playing":
		return
	is_game_paused = not is_game_paused
	get_tree().paused = is_game_paused
	pause_changed.emit(is_game_paused)


func start_game() -> void:
	get_tree().paused = false
	is_game_paused = false
	get_tree().change_scene_to_file(LEVEL_SCENE)


func restart_level() -> void:
	get_tree().paused = false
	is_game_paused = false
	get_tree().change_scene_to_file(LEVEL_SCENE)


func return_to_menu() -> void:
	get_tree().paused = false
	is_game_paused = false
	run_state = "menu"
	get_tree().change_scene_to_file(MENU_SCENE)
