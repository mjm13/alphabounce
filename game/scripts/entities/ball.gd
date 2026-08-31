extends CharacterBody2D

# [核心目的] 球体物理实体：承载位置/速度/类型，使用 Godot Physics2D（move_and_slide）驱动定步长物理更新，
# 通过碰撞法向反射实现边界/方块反弹（替代原自定义 position += velocity*delta 手动积分）。
# [功能描述] Alphabounce 物理系统基础单元，提供 launch/set_ball_velocity/get_ball_velocity 与
# collide_with_block 接口，供 Pad（R01）与关卡/方块碰撞（R04）调用。

const SPEED = 300.0
const BOUNCE_DAMPING = 0.9  # 预留：可选逐帧阻尼（默认不启用，保持原版匀速弹球）
const RESTITUTION = 1.0     # [R17] 原版匀速弹球：反弹不衰减速度，保持恒定速率
const MAX_STEP = 8.0        # [R21] CCD 安全步长(px)：每物理子步位移上限，≤ 最薄碰撞体厚度，避免高速穿墙

@export var ball_type: int = 0  # 0: normal, 1: fire, 2: ice

var is_launched: bool = false
var acceleration: Vector2 = Vector2.ZERO  # 外部设置的加速度（如重力）
var friction: float = 1.0                 # 默认无逐帧衰减，保持原版匀速弹球手感

# [R15/R18] 球体视觉帧循环：10 张单帧图（mcBall/01..10.png）逐帧切换，还原原版彩色旋转球。
var _frames: Array = []
var _frame_idx: int = 0
var _frame_timer: float = 0.0

# [R04] 球-块碰撞：识别到方块并调用其 hit() 时发出，供验收入口断言 AC-1
signal block_hit(block)

func _ready() -> void:
	velocity = Vector2.ZERO
	is_launched = false
	_setup_sprite()

# [R15/R18] 球体视觉：用 10 张单帧图（mcBall/01..10.png）构建帧序列并循环切换贴图，
# 还原原版彩色旋转球效果（避免直接贴整张精灵表导致所有帧叠显成竖条假象）。
func _setup_sprite() -> void:
	var sp := get_node_or_null("Sprite2D")
	if sp == null:
		return
	for i in range(1, 11):
		var tex := load("res://resources/images/mcBall/%02d.png" % i)
		if tex != null:
			_frames.append(tex)
	if _frames.size() > 0:
		sp.texture = _frames[0]

func _process(delta: float) -> void:
	# [R15/R18] 逐帧切换球体贴图，形成彩色旋转/变色效果（不依赖 Godot 动画节点，确保跨版本稳定）。
	if _frames.is_empty():
		return
	_frame_timer += delta
	if _frame_timer >= 0.1:
		_frame_timer = 0.0
		_frame_idx = (_frame_idx + 1) % _frames.size()
		var sp := get_node_or_null("Sprite2D")
		if sp != null:
			sp.texture = _frames[_frame_idx]

func _physics_process(delta: float) -> void:
	# [R21][业务逻辑] 仅在发射后推进；先积分速度，再按 MAX_STEP 子步进 move_and_slide（CCD），
	# 每步检测碰撞并按法向反射（restitution）。常态 speed=300 单帧 ~5px<MAX_STEP → 步数=1，行为等价无 CCD。
	if not is_launched:
		return
	velocity += acceleration * delta
	velocity *= friction
	var speed := velocity.length()
	if speed < 0.001:
		return
	var phys_delta := get_physics_process_delta_time()
	var remaining := speed * delta           # 本帧总位移
	var steps := int(ceil(remaining / MAX_STEP))
	if steps < 1:
		steps = 1
	for i in steps:
		var dist := MAX_STEP if remaining > MAX_STEP else remaining
		# 本物理步位移向量（碰撞前入射速度）。注意：Godot 4 的 move_and_slide 会改写 velocity 为
		# 滑动速度（去掉法向分量），故反弹必须基于入射速度 incoming 反射；若基于 move_and_slide 之后的
		# 速度反射，正面/斜碰都会丢失法向分量，导致球贴墙滑行甚至停滞（restitution 手感缺陷）。
		var incoming := velocity.normalized() * (dist / phys_delta)
		velocity = incoming
		move_and_slide()
		var collision := get_last_slide_collision()
		if collision != null:
			var normal := collision.get_normal()
			velocity = incoming.bounce(normal) * RESTITUTION
			# [R04] 物理滑动碰撞识别方块并造成伤害（本 Godot 版本无 body_entered 信号，改用 get_slide_collision）
			var collider = collision.get_collider()
			if collider != null and collider.is_in_group("blocks"):
				if collider.has_method("hit"):
					collider.hit(1)
				emit_signal("block_hit", collider)
		remaining -= dist
	# [R21] 末尾归一到原速率，保持匀速弹球（RESTITUTION=1.0），避免子步速度残差累积
	velocity = velocity.normalized() * speed

func collide_with_block(block_position: Vector2) -> void:
	# [业务逻辑] 与方块碰撞：按入射方向反射速度（restitution），独立于 Godot 物理信号，便于单测。
	var normal := (global_position - block_position).normalized()
	if normal != Vector2.ZERO:
		velocity = velocity.bounce(normal) * RESTITUTION

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
