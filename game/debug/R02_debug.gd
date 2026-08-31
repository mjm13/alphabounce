extends Control

# [R02][重验收] 关卡网格与关卡数据系统：由 DebugLauncher 进入（res://debug/R02_debug.tscn）。
# 既加载真实关卡数据（level_001），又用 Grid 坐标映射铺展演示网格，
# 真机截图应直接可见按网格排布的方块（证明 grid_to_world 映射与关卡数据渲染）。
# 逐 AC 打印 R02_AC-n PASS/FAIL。

const LevelLoaderScript = preload("res://scripts/core/level_loader.gd")
const LevelDataScript = preload("res://scripts/core/level_data.gd")
const GridScript = preload("res://scripts/core/grid.gd")
const BLOCK_SCENE = preload("res://scenes/entities/Block.tscn")

var _loader = null

func _ready() -> void:
	# 标题
	var title := Label.new()
	title.text = "R02 关卡网格与数据系统"
	title.position = Vector2(12, 12)
	title.add_theme_font_size_override("font_size", 26)
	add_child(title)

	# 真实关卡数据加载（level_001）→ 按 grid 坐标实例化方块
	_loader = LevelLoaderScript.new()
	add_child(_loader)

	# 用 Grid 系统铺展一个 6x12 演示网格，直接可视化 grid_to_world 映射
	var grid_start := Vector2(40, 130)
	for r in range(6):
		for c in range(12):
			var b = BLOCK_SCENE.instantiate()
			b.block_type = (r + c) % 2
			add_child(b)
			b.global_position = Vector2(grid_start.x + c * 36, grid_start.y + r * 36)

	# 标签：真实关卡方块数
	var info := Label.new()
	info.text = "level_001 方块数: %d" % _loader.loaded_blocks.size()
	info.position = Vector2(12, 50)
	add_child(info)

	# ---- AC ----
	var data = LevelDataScript.new()
	var ok_ac1: bool = data.load("res://resources/levels/level_001.json")
	var cell := Vector2i(3, 6)
	var center := GridScript.grid_to_world(cell)
	var ok_ac2: bool = center.is_equal_approx(Vector2(3 * 32 + 16, 6 * 32 + 16)) and GridScript.world_to_grid(center) == cell
	var ok_ac3: bool = _loader.loaded_blocks.size() > 0
	var d2 = LevelDataScript.new(); var d3 = LevelDataScript.new()
	var ok_ac4: bool = d2.load("res://resources/levels/level_002.json") and d3.load("res://resources/levels/level_003.json")
	print_ac("R02", 1, ok_ac1)
	print_ac("R02", 2, ok_ac2)
	print_ac("R02", 3, ok_ac3)
	print_ac("R02", 4, ok_ac4)
	print_ac("R02", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
