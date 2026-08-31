extends Node

# [R21] 球体穿墙 CCD 验证（headless 物理）：高速不穿墙 / 常态等价 / 砖块命中不丢。

var _pass := 0
var _fail := 0
var _hits := 0


func _ready() -> void:
	# ===== AC-1：高速不穿墙 =====
	var wall := _static_body(Vector2(300, 200), Vector2(6, 120))  # 厚 12px
	add_child(wall)
	var ball1 := _ball(Vector2(150, 200))
	add_child(ball1)
	ball1.is_launched = true
	ball1.set_ball_velocity(Vector2(1200, 0))   # 单帧 ~20px > MAX_STEP(8)
	var wall_left := 300 - 6
	for i in range(30):
		await get_tree().physics_frame
	var crossed1 := float(ball1.global_position.x) >= wall_left
	print_ac("R21", 1, not crossed1)
	ball1.queue_free()
	wall.queue_free()

	# ===== AC-2：常态速度等价（不穿墙 + 确有运动）=====
	var wall2 := _static_body(Vector2(300, 200), Vector2(6, 120))
	add_child(wall2)
	var ball2 := _ball(Vector2(150, 200))
	add_child(ball2)
	ball2.is_launched = true
	ball2.set_ball_velocity(Vector2(300, 0))    # 单帧 ~5px < MAX_STEP
	var start_x := float(ball2.global_position.x)
	for i in range(30):
		await get_tree().physics_frame
	var crossed2 := float(ball2.global_position.x) >= wall_left
	var moved := (float(ball2.global_position.x) - start_x) > 1.0 or (start_x - float(ball2.global_position.x)) > 1.0
	print_ac("R21", 2, (not crossed2) and moved)
	ball2.queue_free()
	wall2.queue_free()

	# ===== AC-3：高速命中砖块不丢 =====
	_hits = 0
	var brick := _brick(Vector2(300, 200), Vector2(12, 24))
	add_child(brick)
	var ball3 := _ball(Vector2(150, 200))
	add_child(ball3)
	ball3.is_launched = true
	ball3.set_ball_velocity(Vector2(1200, 0))
	ball3.connect("block_hit", _on_block_hit)
	for i in range(30):
		await get_tree().physics_frame
	print_ac("R21", 3, _hits > 0)
	ball3.queue_free()
	brick.queue_free()

	await get_tree().process_frame
	get_tree().quit(0 if _fail == 0 else 1)


func _on_block_hit(_b) -> void:
	_hits += 1


func print_ac(tag: String, n: int, ok: bool) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("%s_AC-%d %s" % [tag, n, "PASS" if ok else "FAIL"])


func _ball(pos: Vector2) -> Node:
	var s = preload("res://scripts/entities/ball.gd")
	var b = s.new()
	b.global_position = pos
	var cs = CollisionShape2D.new()
	cs.shape = CircleShape2D.new()
	cs.shape.radius = 8
	b.add_child(cs)
	return b


func _static_body(pos: Vector2, half: Vector2) -> Node:
	var b = StaticBody2D.new()
	b.global_position = pos
	var cs = CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	cs.shape.size = half * 2
	b.add_child(cs)
	return b


func _brick(pos: Vector2, half: Vector2) -> Node:
	var b = preload("res://tests/test_brick.gd").new()
	b.global_position = pos
	b.add_to_group("blocks")
	var cs = CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	cs.shape.size = half * 2
	b.add_child(cs)
	return b
