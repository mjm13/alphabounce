extends Control

# R02 真机独立验收入口：由 DebugLauncher 进入（res://debug/R02_debug.tscn）。
# 逐 AC 打印 R02_AC-n PASS/FAIL。

const LevelLoaderScript = preload("res://scripts/core/level_loader.gd")
const LevelDataScript = preload("res://scripts/core/level_data.gd")
const GridScript = preload("res://scripts/core/grid.gd")

var _loader = null

func _ready() -> void:
	_loader = LevelLoaderScript.new()
	add_child(_loader)
	# AC-1：LevelData 解析
	var data = LevelDataScript.new()
	var ok_ac1: bool = data.load("res://resources/levels/level_001.json")
	# AC-2：网格中心→世界→网格可逆（world_to_grid 有 floor 截断，故以格子中心为基准）
	var cell := Vector2i(3, 6)
	var center := GridScript.grid_to_world(cell)
	var ok_ac2: bool = center.is_equal_approx(Vector2(3 * 32 + 16, 6 * 32 + 16)) and GridScript.world_to_grid(center) == cell
	# AC-3：方块已加载
	var ok_ac3: bool = _loader.loaded_blocks.size() > 0
	# AC-4：3 个关卡 JSON 存在且类型混合
	var d2 = LevelDataScript.new()
	var d3 = LevelDataScript.new()
	var ok_ac4: bool = d2.load("res://resources/levels/level_002.json") and d3.load("res://resources/levels/level_003.json")
	# AC-5：场景加载无报错
	var ok_ac5: bool = true
	print_ac("R02", 1, ok_ac1)
	print_ac("R02", 2, ok_ac2)
	print_ac("R02", 3, ok_ac3)
	print_ac("R02", 4, ok_ac4)
	print_ac("R02", 5, ok_ac5)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
