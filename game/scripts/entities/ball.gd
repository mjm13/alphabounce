extends CharacterBody2D

# [核心目的] 球体物理实体：承载位置/速度/类型，使用 Godot Physics2D（move_and_slide）驱动定步长物理更新，
# 通过碰撞法向反射实现边界/方块反弹（替代原自定义 position += velocity*delta 手动积分）。
# [功能描述] Alphabounce 物理系统基础单元，提供 launch/set_ball_velocity/get_ball_velocity 与
# collide_with_block 接口，供 Pad（R01）与关卡/方块碰撞（R04）调用。

const SPEED = 300.0
const BOUNCE_DAMPING = 0.9
const RESTITUTION = 0.95

@export var ball_type: int = 0  # 0: normal, 1: fire, 2: ice

var is_launched: bool = false
var acceleration: Vector2 = Vector2.ZERO  # 外部设置的加速度（如重力）
var friction: float = BOUNCE_DAMPING     # 每帧速度衰减系数（摩擦）

func _ready() -> void:
	velocity = Vector2.ZERO
	is_launched = false

func _physics_process(delta: float) -> void:
	# [业务逻辑] 仅在发射后推进；先积分速度，再用 move_and_slide 物理步进，碰撞后按法向反射（restitution）。
	if not is_launched:
		return
	velocity += acceleration * delta
	velocity *= friction
	var pre := velocity
	move_and_slide()
	var collision := get_last_slide_collision()
	if collision != null:
		var normal := collision.get_normal()
		velocity = pre.bounce(normal) * RESTITUTION

func collide_with_block(block_position: Vector2) -> void:
	# [业务逻辑] 与方块碰撞：按入射方向反射速度（restitution），独立于 Godot 物理信号，便于单测。
	var normal := (global_position - block_position).normalized()
	if normal != Vector2.ZERO:
		velocity = velocity.bounce(normal) * RESTITUTION

func _on_body_entered(body: Node) -> void:
	# [业务逻辑] 场景内物理碰撞回调：方块组触发反弹。
	if body.is_in_group("blocks"):
		collide_with_block(body.global_position)

func launch(direction: Vector2) -> void:
	# [业务逻辑] 以单位方向 * 初速发射球体；签名与 R01 Pad 契约保持不变。
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
