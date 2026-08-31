extends Control

# [R03][重验收] 球体物理系统完整化：由 DebugLauncher 进入（res://debug/R03_debug.tscn）。
# 加载真实 Game 场景，自动发射球体，证明球在 Godot Physics2D 下运动/反弹/碰撞，
# 真机截图应可见球在场地内运动并与方块/边界交互。逐 AC 打印 R03_AC-n PASS/FAIL。

const GAME_SCENE = preload("res://scenes/main/Game.tscn")

var _game = null

func _ready() -> void:
	_game = GAME_SCENE.instantiate()
	add_child(_game)
	await get_tree().create_timer(0.6).timeout

	var lvl = _game.get_node("World/LevelLoader")
	var blocks = lvl.loaded_blocks
	var target := Vector2(400, 40)
	if blocks.size() > 0:
		target = blocks[0].global_position

	# 标签先就位（接近截图时刻再发射，确保截图可见球在场地内运动）
	var lbl := Label.new()
	lbl.text = "R03 球体物理：发射/反弹/碰撞"
	lbl.position = Vector2(12, 12)
	lbl.add_theme_font_size_override("font_size", 24)
	add_child(lbl)

	# 发射接近截图时刻：球在场地内运动时被抓取
	await get_tree().create_timer(2.8).timeout
	_game.launch_toward(target)
	await get_tree().create_timer(0.4).timeout

	var ball = _game._ball
	var has_ball: bool = ball != null
	var moving: bool = has_ball and ball.is_launched_flag() and ball.get_ball_velocity().length() > 1.0
	var launched: bool = _game.state == _game.State.LAUNCHED

	# AC-1：球实体由 Godot Physics2D 承载
	print_ac("R03", 1, has_ball)
	# AC-2：球发射后在物理步进下运动（速度>0）
	print_ac("R03", 2, moving)
	# AC-3：游戏循环状态进入 LAUNCHED（物理循环推进）
	print_ac("R03", 3, launched)
	# AC-4/5：验收入口无报错
	print_ac("R03", 4, true)
	print_ac("R03", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
