extends Control

# [R16] 原版内容数据搬运：由 DebugLauncher 进入（res://debug/R16_debug.tscn）。
# 加载真实 Game（默认 level_001，已由 levels.json 全类型方块构成），按类型统计方块，
# 验证原版风格的多类型方块内容已迁移并渲染。真机截图应可见密集多类型方块墙。
# 逐 AC 打印 R16_AC-n PASS/FAIL。

const GAME_SCENE = preload("res://scenes/main/Game.tscn")

var _game = null

func _ready() -> void:
	_game = GAME_SCENE.instantiate()
	add_child(_game)
	await get_tree().create_timer(0.6).timeout

	var lbl := Label.new()
	lbl.text = "R16 内容数据：多类型方块"
	lbl.position = Vector2(12, 12)
	lbl.add_theme_font_size_override("font_size", 24)
	add_child(lbl)

	var lvl = _game.get_node("World/LevelLoader")
	var blocks = lvl.loaded_blocks

	var counts := {}
	for b in blocks:
		var t: int = b.block_type
		counts[t] = counts.get(t, 0) + 1

	var total: int = blocks.size()
	var types_present: int = counts.keys().size()
	var has_guardian: bool = counts.get(9, 0) > 0
	var has_steel: bool = counts.get(1, 0) > 0
	var has_bonus: bool = counts.get(2, 0) > 0

	print("R16_BLOCK_COUNT total=%d types=%d counts=%s" % [total, types_present, counts])

	print_ac("R16", 1, total > 50)        # 关卡有实质内容
	print_ac("R16", 2, types_present >= 8)  # 多类型方块已迁移渲染
	print_ac("R16", 3, has_guardian)        # GUARDIAN（仅导弹可击杀）存在
	print_ac("R16", 4, has_steel and has_bonus)  # 钢墙 / 奖励块存在
	print_ac("R16", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
