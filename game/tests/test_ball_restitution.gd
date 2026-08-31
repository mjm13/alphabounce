extends Node

# [R23] 球体反弹 restitution 物理手感回归（headless）：速率守恒 + 反射方向，对标原版 Ball.hx 恒定 speed。

const BallClass = preload("res://scripts/entities/ball.gd")

var _pass := 0
var _fail := 0

# AC-1 头碰（水平撞垂直墙）
var _ball1: Node
var _cap1: Vector2 = Vector2.ZERO
var _hit1 := false

# AC-2 斜碰（斜向撞垂直墙）
var _ball2: Node
var _cap2: Vector2 = Vector2.ZERO
var _hit2 := false

# AC-3 四壁盒连续反弹，速率偏差
var _ball3: Node
var _speed3 := 0.0
var _max_dev3 := 0.0
var _frames3 := 0
var _done3 := false

var _finished := false


func _ready() -> void:
	_setup_ac1_ac2()
	_setup_ac3()
	await get_tree().process_frame


func _add_wall(center: Vector2, size: Vector2) -> void:
	var w := StaticBody2D.new()
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	s.shape = r
	w.add_child(s)
	w.position = center
	add_child(w)


func _make_ball(pos: Vector2, vel: Vector2) -> Node:
	var b: Node = BallClass.new()
	var s := CollisionShape2D.new()
	var r := CircleShape2D.new()
	r.radius = 8
	s.shape = r
	b.add_child(s)
	b.position = pos
	add_child(b)
	# 必须在 add_child 之后设置：ball.gd 的 _ready() 会把 velocity/is_launched 重置
	b.set_ball_velocity(vel)
	b.is_launched = true
	return b


func _setup_ac1_ac2() -> void:
	# 高墙（垂直，法向 -x），覆盖宽广 y 区间，确保 AC-1/AC-2 均为干净垂直面反弹
	_add_wall(Vector2(300, 500), Vector2(20, 1000))
	_ball1 = _make_ball(Vector2(100, 300), Vector2(300, 0))
	_ball2 = _make_ball(Vector2(100, 700), Vector2(300, 150))


func _setup_ac3() -> void:
	# 四壁盒：x∈[400,1000], y∈[200,800]
	_add_wall(Vector2(400, 500), Vector2(20, 600))   # 左
	_add_wall(Vector2(1000, 500), Vector2(20, 600))  # 右
	_add_wall(Vector2(700, 200), Vector2(600, 20))   # 上
	_add_wall(Vector2(700, 800), Vector2(600, 20))   # 下
	_ball3 = _make_ball(Vector2(700, 500), Vector2(300, 150))
	_speed3 = float(_ball3.get_ball_velocity().length())


func _physics_process(_delta: float) -> void:
	if not _hit1:
		var c1 = _ball1.get_last_slide_collision()
		if c1 != null:
			_hit1 = true
			_cap1 = _ball1.get_ball_velocity()
	if not _hit2:
		var c2 = _ball2.get_last_slide_collision()
		if c2 != null:
			_hit2 = true
			_cap2 = _ball2.get_ball_velocity()
	if not _done3:
		var sp := float(_ball3.get_ball_velocity().length())
		var dev: float = float(abs(sp - _speed3)) / _speed3
		if dev > _max_dev3:
			_max_dev3 = dev
		_frames3 += 1
		if _frames3 >= 120:
			_done3 = true
			_finalize()


func _finalize() -> void:
	if _finished:
		return
	_finished = true

	# AC-1：水平撞垂直墙 → vx 反号、vy 不变、速率≈300
	var ac1: bool = _hit1 and float(_cap1.x) < -250.0 and float(abs(float(_cap1.y))) < 50.0 and float(abs(float(_cap1.length()) - 300.0)) < 30.0
	print_ac("R23", 1, ac1)

	# AC-2：斜向撞垂直墙 → vx 反号、vy 不变、速率≈√(300²+150²)
	var exp2 := sqrt(300.0 * 300.0 + 150.0 * 150.0)
	var ac2: bool = _hit2 and float(_cap2.x) < -250.0 and float(abs(float(_cap2.y) - 150.0)) < 30.0 and float(abs(float(_cap2.length()) - exp2)) < 30.0
	print_ac("R23", 2, ac2)

	# AC-3：连续反弹全程速率偏差 ≤ 1%
	var ac3: bool = _max_dev3 < 0.01
	print_ac("R23", 3, ac3)

	await get_tree().process_frame
	get_tree().quit(0 if _fail == 0 else 1)


func print_ac(tag: String, n: int, ok: bool) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("%s_AC-%d %s" % [tag, n, "PASS" if ok else "FAIL"])
