extends Node2D

@export var cooldown: float = 1.2
@export var bullet_range: float = 420.0
@export var damage: int = 1

@onready var muzzle_flash: PointLight2D = $MuzzleFlash

var _cooldown_left: float = 0.0
var _flash_timer: float = 0.0


func _ready() -> void:
	muzzle_flash.enabled = false


func aim_at(target: Vector2) -> void:
	look_at(target)


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	muzzle_flash.enabled = _flash_timer > 0.0


func try_fire() -> bool:
	if GameManager.run_state != "playing":
		return false
	if _cooldown_left > 0.0:
		return false
	if GameManager.player and GameManager.player.has_method("is_hidden_state") and GameManager.player.is_hidden_state():
		return false
	if not GameManager.consume_ammo(1):
		return false

	_cooldown_left = cooldown
	_flash_timer = 0.1
	muzzle_flash.enabled = true
	AudioManager.play_sfx("gunshot", global_position)
	GameManager.emit_gunshot(global_position)

	var origin := global_position
	var direction := (get_global_mouse_position() - origin).normalized()
	var query := PhysicsRayQueryParameters2D.create(origin, origin + direction * bullet_range)
	query.exclude = [get_parent()]
	query.collision_mask = 1 | 4

	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider and hit.collider.has_method("apply_damage"):
		hit.collider.apply_damage(damage, direction)

	return true
