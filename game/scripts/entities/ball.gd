extends CharacterBody2D

const SPEED = 400.0
const BOUNCE_DAMPING = 0.95

@export var ball_type: int = 0  # 0: normal, 1: fire, 2: ice

var _move_velocity = Vector2.ZERO
var is_launched: bool = false

func _ready():
	_move_velocity = Vector2.ZERO
	is_launched = false

func _physics_process(delta):
	if not is_launched:
		return
	
	_move_velocity *= BOUNCE_DAMPING
	position += _move_velocity * delta
	
	_check_boundaries()

func launch(direction: Vector2):
	_move_velocity = direction.normalized() * SPEED
	is_launched = true

func _check_boundaries():
	var screen_size = get_viewport_rect().size
	if position.x < 0 or position.x > screen_size.x:
		_move_velocity.x *= -1
		position.x = clamp(position.x, 0, screen_size.x)
	if position.y < 0 or position.y > screen_size.y:
		_move_velocity.y *= -1
		position.y = clamp(position.y, 0, screen_size.y)

func get_type() -> int:
	return ball_type

func is_launched_flag() -> bool:
	return is_launched

func get_move_velocity() -> Vector2:
	return _move_velocity
