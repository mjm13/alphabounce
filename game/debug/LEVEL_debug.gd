extends Control

# [关卡内容设计] 验收入口：由 DebugLauncher 进入（res://debug/LEVEL_debug.tscn）。
# 加载 level_001/002/003，统计三关方块数量与覆盖的方块类型（应覆盖全部 10 种 BlockType），
# 验证「关卡内容设计」按原版结构自建关卡集并已供给 R02/R10。逐 AC 打印 LEVEL_AC-n PASS/FAIL。

const LevelLoaderScript = preload("res://scripts/core/level_loader.gd")

var _ll: Node

func _ready() -> void:
	var title := Label.new()
	title.text = "关卡内容设计：level_001/002/003"
	title.position = Vector2(12, 12)
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)

	# 渲染 level_001 作为视觉证据（方块墙）
	_ll = LevelLoaderScript.new()
	_ll.level_path = "res://resources/levels/level_001.json"
	add_child(_ll)
	await get_tree().create_timer(0.4).timeout

	var levels := ["level_001", "level_002", "level_003"]
	var per_level := {}
	var all_types := {}
	var all_ok := true
	for name in levels:
		var ll := LevelLoaderScript.new()
		ll.level_path = "res://resources/levels/%s.json" % name
		ll.load_level(ll.level_path)
		var n: int = ll.loaded_blocks.size()
		per_level[name] = n
		if n <= 0:
			all_ok = false
		for b in ll.loaded_blocks:
			all_types[int(b.block_type)] = true
		print("LEVEL_%s blocks=%d" % [name, n])

	var type_count: int = all_types.keys().size()
	print("LEVEL_TYPES present=%d (expect 10)" % type_count)

	# AC-1：level_001 已生成且有实质内容
	print_ac("LEVEL", 1, per_level.get("level_001", 0) > 0)
	# AC-2：level_002 已生成且有实质内容
	print_ac("LEVEL", 2, per_level.get("level_002", 0) > 0)
	# AC-3：level_003 已生成且有实质内容
	print_ac("LEVEL", 3, per_level.get("level_003", 0) > 0)
	# AC-4：三关合计覆盖全部 10 种方块类型（NORMAL..GUARDIAN）
	print_ac("LEVEL", 4, type_count >= 10)
	# AC-5：三关均成功加载且无空关
	print_ac("LEVEL", 5, all_ok)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
