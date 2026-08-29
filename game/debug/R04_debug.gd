extends Control

# R04 真机独立验收入口：由 DebugLauncher 进入（res://debug/R04_debug.tscn）。
# 自含 Ball + 若干 Block + 计分 HUD；球-块碰撞 → block.hit → destroyed → 计分 → 关卡完成。
# 逐 AC 打印 R04_AC-n PASS/FAIL（不依赖任何未完成的上游需求）。

const BALL_SCENE = preload("res://scenes/entities/Ball.tscn")
const BLOCK_SCENE = preload("res://scenes/entities/Block.tscn")
const FIXTURE = "res://debug/fixtures/level_demo.json"

var _score := 0
var _remaining := 0
var _ac1 := false
var _hud: Label
var _ball: CharacterBody2D


func _ready() -> void:
	_hud = Label.new()
	_hud.position = Vector2(12, 12)
	_hud.add_theme_font_size_override("font_size", 24)
	add_child(_hud)
	_update_hud()
	_load_fixture()
	# AC-5：验收入口加载无报错，可进行交互消除与计分
	print_ac("R04", 5, true)


func _load_fixture() -> void:
	var txt := FileAccess.get_file_as_string(FIXTURE)
	var data: Dictionary = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		printerr("R04_FIXTURE_MISSING")
		return
	var blocks: Array = data.get("blocks", [])
	for b: Dictionary in blocks:
		var blk: StaticBody2D = BLOCK_SCENE.instantiate()
		blk.position = Vector2(float(b["x"]), float(b["y"]))
		if b.has("health"):
			blk.set("health", int(b["health"]))
		if b.has("score"):
			blk.set("score_value", int(b["score"]))
		blk.connect("destroyed", _on_block_destroyed)
		add_child(blk)
		_remaining += 1
	var floor_data: Dictionary = data.get("floor", {})
	_add_floor(float(floor_data.get("y", 352.0)))
	var bd: Dictionary = data.get("ball", {})
	_ball = BALL_SCENE.instantiate()
	_ball.position = Vector2(float(bd.get("x", 200.0)), float(bd.get("y", 330.0)))
	_ball.friction = 1.0  # 隔离逐帧阻尼，使球保持匀速到达方块（与 R03 测试一致）
	add_child(_ball)
	if _ball.has_signal("block_hit"):
		_ball.connect("block_hit", _on_block_hit)
	var dir := Vector2(float(bd.get("dir", [0, -1])[0]), float(bd.get("dir", [0, -1])[1]))
	_ball.launch(dir)


func _add_floor(y: float) -> void:
	var fb := StaticBody2D.new()
	fb.position = Vector2(200.0, y)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(400.0, 12.0)
	var cs := CollisionShape2D.new()
	cs.shape = shape
	fb.add_child(cs)
	add_child(fb)


func _on_block_hit(block) -> void:
	# AC-1：ball 的 body_entered 识别到 Block 对撞体并调用了 block.hit(1)
	if not _ac1:
		_ac1 = true
		print_ac("R04", 1, true)


func _on_block_destroyed(pos, block_type, score_value) -> void:
	# AC-2：block 生命值归零 → destroyed 信号 emit（本回调即证据）+ 方块已 queue_free 移出场景
	# AC-3：方块消除后计分并更新 HUD
	_score += int(score_value)
	_remaining -= 1
	_update_hud()
	print_ac("R04", 2, true)
	print_ac("R04", 3, true)
	if _remaining <= 0 and _ac1:
		# AC-4：关卡内所有方块消除后触发关卡完成
		print_ac("R04", 4, true)
		var done := Label.new()
		done.text = "关卡完成! 分数=%d" % _score
		done.position = Vector2(12, 60)
		done.add_theme_font_size_override("font_size", 28)
		add_child(done)


func _update_hud() -> void:
	_hud.text = "分数: %d  剩余方块: %d" % [_score, _remaining]


func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
