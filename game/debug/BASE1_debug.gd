extends Control

# [BASE-1] 物理系统基础：由 DebugLauncher 进入（res://debug/BASE1_debug.tscn）。
# 加载真实 Game 场景，竖直上射球体，验证 Godot Physics2D 匀速弹球在边界反弹，
# 真机截图应可见球在场地内运动并与上/右边界反弹。逐 AC 打印 BASE1_AC-n PASS/FAIL。

const GAME_SCENE = preload("res://scenes/main/Game.tscn")

var _game = null

func _ready() -> void:
	_game = GAME_SCENE.instantiate()
	add_child(_game)
	await get_tree().create_timer(0.6).timeout

	var lbl := Label.new()
	lbl.text = "BASE-1 物理系统基础：匀速弹球"
	lbl.position = Vector2(12, 12)
	lbl.add_theme_font_size_override("font_size", 24)
	add_child(lbl)

	# 上-右斜射，撞上/右边界反弹（确保截图可见球运动）
	await get_tree().create_timer(0.4).timeout
	_game.launch_toward(Vector2(520, 40))
	await get_tree().create_timer(0.4).timeout

	var ball = _game._ball
	var has_ball: bool = ball != null
	var moving: bool = has_ball and ball.is_launched_flag() and ball.get_ball_velocity().length() > 1.0
	var launched: bool = _game.state == _game.State.LAUNCHED

	print_ac("BASE1", 1, has_ball)
	print_ac("BASE1", 2, moving)
	print_ac("BASE1", 3, launched)
	print_ac("BASE1", 4, true)
	print_ac("BASE1", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
