extends CharacterBody2D

# [核心目的] 球体物理实体：承载位置/速度/类型，驱动定步长物理更新循环（速度/加速度/摩擦），并处理边界与方块碰撞反弹。
# [功能描述] Alphabounce 物理系统基础单元，提供 launch/set_ball_velocity/get_ball_velocity 与 step_physics/check_boundaries/collide_with_block 接口，供游戏循环与单元测试调用。

const SPEED = 300.0
const BOUNCE_DAMPING = 0.9
const RESTITUTION = 1.0

@export var ball_type: int = 0  # 0: normal, 1: fire, 2: ice

var is_launched: bool = false
var acceleration: Vector2 = Vector2.ZERO  # 外部设置的加速度（如重力）
var friction: float = BOUNCE_DAMPING     # 每帧速度衰减系数（摩擦）

func _ready() -> void:
	velocity = Vector2.ZERO
	is_launched = false

func _physics_process(delta: float) -> void:
	# [业务逻辑] 仅在发射后推进；先积分物理，再按视口边界反弹钳制。
	if not is_launched:
		return
	step_physics(delta)
	check_boundaries(get_viewport_rect())

func step_physics(delta: float) -> void:
	# [业务逻辑] 物理更新循环：速度叠加加速度、按摩擦衰减、积分位置（delta 驱动，帧率无关）。
	velocity += acceleration * delta
	velocity *= friction
	position += velocity * delta

func check_boundaries(bounds: Rect2 = Rect2()) -> void:
	# [业务逻辑] 边界碰撞：越界则沿法向反弹（RESTITUTION）并钳制位置，防止逃逸。
	var size := bounds.size if bounds.size != Vector2.ZERO else get_viewport_rect().size
	if position.x < 0.0 or position.x > size.x:
		velocity.x *= -RESTITUTION
		position.x = clampf(position.x, 0.0, size.x)
	if position.y < 0.0 or position.y > size.y:
		velocity.y *= -RESTITUTION
		position.y = clampf(position.y, 0.0, size.y)

func collide_with_block(block_position: Vector2) -> void:
	# [业务逻辑] 与方块碰撞：按入射方向反射速度（restitution），独立于 Godot 物理信号，便于单测。
	var normal := (global_position - block_position).normalized()
	if normal != Vector2.ZERO:
		velocity = velocity.bounce(normal)

func _on_body_entered(body: Node) -> void:
	# [业务逻辑] 场景内物理碰撞回调：方块组触发反弹。
	if body.is_in_group("blocks"):
		collide_with_block(body.global_position)

func launch(direction: Vector2) -> void:
	# [业务逻辑] 以单位方向 * 初速发射球体。
	velocity = direction.normalized() * SPEED
	is_launched = true

func set_ball_velocity(v: Vector2) -> void:
	velocity = v

func get_ball_velocity() -> Vector2:
	return velocity

func get_move_velocity() -> Vector2:
	return velocity

func get_type() -> int:
	return ball_type

func is_launched_flag() -> bool:
	return is_launched

func set_acceleration(a: Vector2) -> void:
	acceleration = a
