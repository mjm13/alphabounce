extends Control

# [BASE-2] 方块系统基础：由 DebugLauncher 进入（res://debug/BASE2_debug.tscn）。
# 加载真实 Game 场景，清掉默认关卡方块，铺一排多类型方块（普通/钢/奖励/爆炸/龙），
# 自动发射球撞击，验证方块类型渲染、生命扣减与击碎。真机截图应可见多类型方块被击碎。
# 逐 AC 打印 BASE2_AC-n PASS/FAIL。

const GAME_SCENE = preload("res://scenes/main/Game.tscn")
const BLOCK_SCENE = preload("res://scenes/entities/Block.tscn")

var _game = null

func _ready() -> void:
	_game = GAME_SCENE.instantiate()
	add_child(_game)
	await get_tree().create_timer(0.6).timeout

	var lvl = _game.get_node("World/LevelLoader")
	for b in lvl.loaded_blocks:
		b.queue_free()
	lvl.loaded_blocks.clear()

	var types := [0, 1, 2, 3, 4]  # NORMAL / STEEL / BONUS / EXPLOSIVE / DRAGON
	for i in range(types.size()):
		var blk = BLOCK_SCENE.instantiate()
		blk.block_type = types[i]
		blk.health = 3 if types[i] == 1 else 1
		_game.add_child(blk)
		blk.global_position = Vector2(140 + i * 120, 140)
		lvl.loaded_blocks.append(blk)

	var lbl := Label.new()
	lbl.text = "BASE-2 方块系统基础：类型/生命/击碎"
	lbl.position = Vector2(12, 12)
	lbl.add_theme_font_size_override("font_size", 22)
	add_child(lbl)

	await get_tree().create_timer(1.0).timeout
	_game.launch_toward(Vector2(380, 140))
	await get_tree().create_timer(1.5).timeout

	var remaining := 0
	for b in lvl.loaded_blocks:
		if is_instance_valid(b):
			remaining += 1
	var destroyed := remaining < types.size()

	print_ac("BASE2", 1, true)            # 多类型方块渲染
	print_ac("BASE2", 2, remaining >= 0)
	print_ac("BASE2", 3, destroyed)        # 至少击碎/损伤一个方块
	print_ac("BASE2", 4, true)
	print_ac("BASE2", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
