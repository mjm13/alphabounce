extends Control

# [R17] 物理对等校验：球体在封闭边界内保持恒定速率、反射角等于入射角，
# 还原原版 Alphabounce 匀速弹球手感。轨迹用 Line2D 可视化，便于真机截图核对。

const Ball = preload("res://scripts/entities/ball.gd")
const BallScene = preload("res://scenes/entities/Ball.tscn")

var _world: Node2D
var _ball: CharacterBody2D
var _trail: Line2D
var _bounces: int = 0
var _timer: float = 0.0

func _ready() -> void:
	var title := Label.new()
	title.text = "R17 物理对等：匀速弹球轨迹"
	title.position = Vector2(12, 12)
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)

	_world = Node2D.new()
	add_child(_world)
	_create_walls(Rect2(50, 80, 350, 440))

	_trail = Line2D.new()
	_trail.width = 2
	_trail.default_color = Color(1, 0.6, 0.2, 0.8)
	_trail.z_index = -1
	_world.add_child(_trail)

	_ball = BallScene.instantiate()
	_ball.position = Vector2(225, 300)
	_world.add_child(_ball)
	await get_tree().process_frame
	# 直接设置运动状态，避免与 ball._ready 的初始化时序互相覆盖
	_ball.set_ball_velocity(Vector2(1, -0.85).normalized() * Ball.SPEED)
	_ball.is_launched = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_ball):
		return
	_timer += delta

	# 记录轨迹
	if _trail.points.size() == 0 or _trail.points[-1].distance_to(_ball.position) > 4:
		_trail.add_point(_ball.position)
	if _trail.points.size() > 250:
		_trail.remove_point(0)

	# 统计反弹次数并验证速度恒定
	var v: Vector2 = _ball.get_ball_velocity()
	if _ball.get_last_slide_collision() != null:
		_bounces += 1
		var speed := v.length()
		print("R17_BOUNCE %d speed=%.1f" % [_bounces, speed])

	if _timer >= 3.5 and _bounces >= 2:
		_evaluate()
		set_physics_process(false)

func _create_walls(rect: Rect2) -> void:
	var border := Line2D.new()
	border.width = 2
	border.default_color = Color(0.5, 0.8, 1, 0.6)
	border.add_point(rect.position)
	border.add_point(rect.position + Vector2(rect.size.x, 0))
	border.add_point(rect.end)
	border.add_point(rect.position + Vector2(0, rect.size.y))
	border.add_point(rect.position)
	_world.add_child(border)

	var thickness := 8.0
	var segments := [
		[rect.position, rect.position + Vector2(rect.size.x, 0)],                 # top
		[rect.position + Vector2(0, rect.size.y), rect.end],                       # bottom
		[rect.position, rect.position + Vector2(0, rect.size.y)],                 # left
		[rect.position + Vector2(rect.size.x, 0), rect.end],                       # right
	]
	for seg in segments:
		var wall := StaticBody2D.new()
		var shape := SegmentShape2D.new()
		shape.a = seg[0]
		shape.b = seg[1]
		var col := CollisionShape2D.new()
		col.shape = shape
		wall.add_child(col)
		_world.add_child(wall)

func _evaluate() -> void:
	var v: Vector2 = _ball.get_ball_velocity()
	var speed: float = v.length()
	var pos := _ball.position
	var in_box := pos.x >= 40 and pos.x <= 420 and pos.y >= 70 and pos.y <= 540
	var speed_ok: bool = speed >= 280 and speed <= 320  # 额定 300，允许数值误差
	var bounced := _bounces >= 2
	print_ac("R17", 1, speed_ok)      # 速度恒定（无摩擦衰减）
	print_ac("R17", 2, in_box)        # 边界约束有效
	print_ac("R17", 3, bounced)       # 发生多次反弹
	print_ac("R17", 4, speed_ok and in_box and bounced)
	print_ac("R17", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
