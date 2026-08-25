extends CharacterBody2D

const SPEED = 400.0
const BOUNCE_DAMPING = 0.95

@export var ball_type: int = 0  # 0: normal, 1: fire, 2: ice

var velocity = Vector2.ZERO
var is_launched: bool = false

func _ready():
	# 初始状态：未发射
	velocity = Vector2.ZERO
	is_launched = false

func _physics_process(delta):
	if not is_launched:
		return
	
	# 应用速度
	velocity *= BOUNCE_DAMPING
	position += velocity * delta
	
	# 边界反弹
	_check_boundaries()

func launch(direction: Vector2):
	velocity = direction.normalized() * SPEED
	is_launched = true

func _check_boundaries():
	var screen_size = get_viewport_rect().size
	if position.x < 0 or position.x > screen_size.x:
		velocity.x *= -1
		position.x = clamp(position.x, 0, screen_size.x)
	if position.y < 0 or position.y > screen_size.y:
		velocity.y *= -1
		position.y = clamp(position.y, 0, screen_size.y)

func get_type() -> int:
	return ball_type

func is_launched_flag() -> bool:
	return is_launched
