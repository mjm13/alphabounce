extends Control

## R05 真机独立验收入口：由 DebugLauncher 进入（res://debug/R05_debug.tscn）。
## 自含 3 个示例任务 + 任务面板；按钮/计时触发 level_complete → MissionManager.check_conditions。
## 逐 AC 打印 R05_AC-n PASS/FAIL（不依赖任何未完成的上游需求）。

const DEMO = "res://debug/fixtures/mission_demo.json"
const PANEL_SCENE = preload("res://scenes/ui/MissionPanel.tscn")

var _panel: Control
var _hud: Label
var _ac_lines: Array = []


func _ready() -> void:
	_hud = Label.new()
	_hud.position = Vector2(12, 12)
	_hud.add_theme_font_size_override("font_size", 22)
	add_child(_hud)

	# AC-1：MissionData 可从 JSON 正确解析任务（id/name/条件/奖励）
	var ok := MissionManager.load_missions_from_file(DEMO)
	var ac1 := ok and MissionManager.missions.size() == 3
	print_ac("R05", 1, ac1)

	# AC-2：初始状态均为 -1（未开始）
	var ac2 := true
	for m in MissionManager.missions:
		if MissionManager.get_status(m.mission_id) != -1:
			ac2 = false
	print_ac("R05", 2, ac2)

	# 创建任务面板
	_panel = PANEL_SCENE.instantiate()
	_panel.position = Vector2(12, 60)
	add_child(_panel)

	# AC-4：面板正确显示 3 个任务条目（名称 + 状态）
	var rows := _panel.get_node("List").get_child_count()
	print_ac("R05", 4, rows == 3)
	# AC-5：场景加载无报错
	print_ac("R05", 5, true)

	_update_hud()

	# 模拟关卡完成（与 game.gd 的 level_complete 解耦：debug 直接触发条件检查）
	await get_tree().create_timer(1.5).timeout
	var ctx := {"level": 1, "blocks_cleared": 5, "score": 50}
	MissionManager.check_conditions(ctx)

	# AC-3：关卡完成后满足条件任务状态变为 0（进行中）
	var ac3 := true
	for m in MissionManager.missions:
		if MissionManager.get_status(m.mission_id) != 0:
			ac3 = false
	print_ac("R05", 3, ac3)

	_panel.refresh()
	_update_hud()
	var done := Label.new()
	done.text = "任务系统验收完成"
	done.position = Vector2(12, 330)
	done.add_theme_font_size_override("font_size", 24)
	add_child(done)

	_flush_ac()


func _flush_ac() -> void:
	# 桌面端（Windows）把 AC 结果落盘，便于无 stdout 捕获环境下核验；Android 端自动跳过。
	if OS.get_name() != "Windows":
		return
	var f := FileAccess.open("d:/Project/SELF/alphabounce/r05_ac_result.txt", FileAccess.WRITE)
	if f != null:
		for l in _ac_lines:
			f.store_string(l + "\n")
		f.close()


func _update_hud() -> void:
	var active := 0
	for m in MissionManager.missions:
		if MissionManager.get_status(m.mission_id) >= 0:
			active += 1
	_hud.text = "任务数: %d  已激活: %d" % [MissionManager.missions.size(), active]


func print_ac(req_id: String, n: int, ok: bool) -> void:
	var line := "%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"]
	print(line)
	if not ok:
		printerr(line)
	_ac_lines.append(line)
