extends Node2D

# [核心目的] Pad 发射台：AlphaBounce 核心玩法第一环。提供触摸拖动瞄准与松手发射，
# 球从 Pad 位置沿瞄准方向射出，Pad 固定位于屏幕底部中央。
# [功能描述] 处理 InputEventScreenTouch/Drag 计算归一化且 5° 量化的瞄准方向，
# 松手时实例化 Ball 并调用 launch()，并用 CanvasItem.draw 绘制占位色块与瞄准线。

const BALL_SCENE = preload("res://scenes/entities/Ball.tscn")

# OQ-001：瞄准角度量化步进（避免过于敏感）
const AIM_SNAP_DEGREES := 5.0
# 瞄准线长度（像素）
const AIM_LINE_LENGTH := 220.0
# Pad 距视口底部偏移（OQ-002：位置固定；球速复用 ball.gd，不在本需求内修改）
const BOTTOM_OFFSET := 60.0

# 运行时状态（供测试与绘制读取）
var aiming := false
var aim_start := Vector2.ZERO
var aim_end := Vector2.ZERO
var aim_direction := Vector2.UP

func _ready() -> void:
	_place_at_bottom_center()

func _place_at_bottom_center() -> void:
	var rect := get_viewport_rect()
	position = Vector2(rect.size.x * 0.5, rect.size.y - BOTTOM_OFFSET)

# [纯函数·可单测] 由拖拽向量计算归一化、5° 量化的瞄准方向
func compute_aim_direction(drag_vector: Vector2) -> Vector2:
	if drag_vector == Vector2.ZERO:
		return Vector2.ZERO
	var dir := drag_vector.normalized()
	var step := deg_to_rad(AIM_SNAP_DEGREES)
	var angle := dir.angle()
	angle = round(angle / step) * step
	return Vector2(cos(angle), sin(angle))

# 触摸瞄准：按下开始
func begin_aim(at: Vector2) -> void:
	aiming = true
	aim_start = at
	aim_end = at
	queue_redraw()

# 触摸瞄准：拖拽中更新方向与瞄准线
func update_aim(at: Vector2) -> void:
	if not aiming:
		return
	aim_end = at
	aim_direction = compute_aim_direction(aim_end - aim_start)
	queue_redraw()

# 触摸瞄准：松手结束并发射
func end_aim() -> Node:
	if not aiming:
		return null
	aiming = false
	var dir := aim_direction
	queue_redraw()
	return launch_ball(dir)

# [发射] 实例化 Ball 并沿方向发射，返回 Ball 节点（失败返回 null）
func launch_ball(direction: Vector2) -> Node:
	if direction == Vector2.ZERO:
		return null
	var ball := BALL_SCENE.instantiate()
	get_parent().add_child(ball)
	ball.global_position = global_position
	ball.launch(direction)
	return ball

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			begin_aim(event.position)
		else:
			end_aim()
	elif event is InputEventScreenDrag:
		update_aim(event.position)

func _draw() -> void:
	# Pad 已由 Sprite2D 渲染原版贴图；此处仅绘制瞄准线
	if aiming:
		var end := aim_direction * AIM_LINE_LENGTH
		draw_line(Vector2.ZERO, end, Color(1.0, 1.0, 1.0, 0.85), 3.0)
