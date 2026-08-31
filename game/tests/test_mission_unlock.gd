extends TestBase

# [R20] 任务解锁树 组件测试：覆盖 AC-1..AC-3 与 AC-UI-1（headless）。
# 直接操控 MissionManager Autoload 的公开字段，无需文件 I/O。

func _ready() -> void:
	# 构造测试任务：A(无前置, 完成关卡1) / B(需A, 达分100) / C(需A,B, 收集5块)
	var a := MissionData.new(); a.mission_id = "A"; a.title = "任务A"; a.cond_type = "COMPLETE_LEVEL"; a.cond_value = 1
	var b := MissionData.new(); b.mission_id = "B"; b.title = "任务B"; b.cond_type = "REACH_SCORE"; b.cond_value = 100; b.requires = ["A"]
	var c := MissionData.new(); c.mission_id = "C"; c.title = "任务C"; c.cond_type = "COLLECT_BLOCKS"; c.cond_value = 5; c.requires = ["A", "B"]
	MissionManager.missions = [a, b, c]
	MissionManager.status = {}
	for m in MissionManager.missions:
		MissionManager.status[m.mission_id] = -2 if m.requires.size() > 0 else -1

	# AC-2：仅加载后 B 应锁定(-2)，且前置提示含「任务A」
	print_ac("R20", 2, MissionManager.get_status("B") == -2 and ("任务A" in MissionManager.missing_requires("B")))

	# AC-1：完成关卡1 → A 达成(0)；B 仍有前置未达成 → 保持锁定(-2)；C 同理(-2)
	MissionManager.check_conditions({"level": 1})
	print_ac("R20", 1, MissionManager.get_status("A") == 0 and MissionManager.get_status("B") == -2 and MissionManager.get_status("C") == -2)
	# B 达分100 → B 进行中(0)；A、B 均达成 → 下一 tick C 解锁为可接取(-1)
	MissionManager.check_conditions({"score": 100})
	MissionManager.check_conditions({})
	print_ac("R20", 1, MissionManager.get_status("B") == 0 and MissionManager.get_status("C") == -1)

	# AC-3：环检测 —— A↔B 互锁，加载应告警且不崩溃，二者恒锁定(-2)
	MissionManager.missions = []
	MissionManager.status = {}
	var x := MissionData.new(); x.mission_id = "X"; x.title = "X"; x.cond_type = "REACH_SCORE"; x.cond_value = 1; x.requires = ["Y"]
	var y := MissionData.new(); y.mission_id = "Y"; y.title = "Y"; y.cond_type = "REACH_SCORE"; y.cond_value = 1; y.requires = ["X"]
	MissionManager.missions = [x, y]
	for m in MissionManager.missions:
		MissionManager.status[m.mission_id] = -2 if m.requires.size() > 0 else -1
	MissionManager._detect_requires_cycle()
	print_ac("R20", 3, MissionManager.get_status("X") == -2 and MissionManager.get_status("Y") == -2)

	# AC-UI-1：面板锁定渲染 + 前置提示（恢复 A/B/C，B 锁定）
	MissionManager.missions = [a, b, c]
	MissionManager.status = {}
	for m in MissionManager.missions:
		MissionManager.status[m.mission_id] = -2 if m.requires.size() > 0 else -1
	var PanelScript = load("res://scripts/ui/mission_panel.gd")
	var panel = PanelScript.new()
	add_child(panel)
	panel.refresh()
	var found_lock := false
	for child in panel._list.get_children():
		var lbl = child.get_child(1)
		if "锁定" in lbl.text and "需先完成" in lbl.text:
			found_lock = true
	print_ac("R20", 4, found_lock)

	await get_tree().process_frame
	get_tree().quit(0 if not has_failure() else 1)
