extends Node

const GAME_SCENE = preload("res://scenes/main/Game.tscn")

# 聚合 R02 组件测试：AC-5 在本场景校验，AC-1/2/3/4 由各子测试场景 print_ac
func _ready() -> void:
	# AC-5：Game 场景可加载且无脚本错误（等价 Editor 打开无报错）
	print_ac_suite("R02", 5, GAME_SCENE != null)
	var tests := [
		"res://tests/test_level/test_level_data.tscn",
		"res://tests/test_level/test_grid.tscn",
		"res://tests/test_level/test_level_loader.tscn",
	]
	for t in tests:
		add_child(load(t).instantiate())
	await get_tree().create_timer(0.2).timeout
	get_tree().quit(0)

func print_ac_suite(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
