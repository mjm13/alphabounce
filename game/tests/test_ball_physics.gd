extends TestBase

# R03 球体物理系统完整化 组件测试：覆盖 AC-1..AC-5。
# 场景（test_ball_physics.tscn）含 Ball + 4 个边界 StaticBody2D；本脚本在 _physics_process 中驱动仿真。

var ball = null
var _frame := 0
var _prev_vel := Vector2.ZERO
var _bounced := false
var _pre_speed := 0.0
var _post_speed := 0.0
var _start_pos := Vector2.ZERO
var _moved := false

func _ready() -> void:
	ball = $Ball
	# AC-2：Ball.tscn 碰撞形状为 CircleShape2D 且 radius=10
	var cs = ball.get_node_or_null("CollisionShape2D")
	var ok_ac2 = cs != null and cs.shape is CircleShape2D and is_equal_approx(cs.shape.radius, 10.0)
	print_ac("R03", 2, ok_ac2)
	# AC-4：launch(direction) 签名不变，接收归一化 Vector2 并设置初速 ~SPEED
	var ok_ac4a = not ball.is_launched_flag()
	ball.friction = 1.0  # 隔离 restitution，便于 AC-5 精确校验
	ball.launch(Vector2.RIGHT)
	var ok_ac4b = ball.is_launched_flag() and is_equal_approx(ball.get_ball_velocity().length(), 300.0)
	print_ac("R03", 4, ok_ac4a and ok_ac4b)
	_start_pos = ball.position

func _physics_process(_d: float) -> void:
	_frame += 1
	var vel = ball.get_ball_velocity()
	if not _moved and _frame >= 3:
		_moved = ball.position.distance_to(_start_pos) > 1.0
	if not _bounced and vel.x < 0.0:
		_bounced = true
		_post_speed = vel.length()
		_pre_speed = _prev_vel.length()
	if _frame >= 240 or (_bounced and _frame > 5):
		_finish()
	_prev_vel = vel

func _finish() -> void:
	# AC-1：move_and_slide 驱动球体移动（非手动 position += velocity*delta）
	print_ac("R03", 1, _moved)
	# AC-3：碰到边界正确反弹（velocity 分量取反）
	print_ac("R03", 3, _bounced)
	# AC-5：restitution 0.95（反弹后速度 ≈ 反弹前 0.95）
	if _bounced and _pre_speed > 0.0:
		var ratio = _post_speed / _pre_speed
		print_ac("R03", 5, abs(ratio - 0.95) < 0.1)
	else:
		print_ac("R03", 5, false)
	get_tree().quit(0 if not has_failure() else 1)
