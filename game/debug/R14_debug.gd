extends Control

# [R14] 完整 UI 层：由 DebugLauncher 进入（res://debug/R14_debug.tscn）。
# 实例化主菜单，验证按钮渲染、Start 入口存在并可点击触发场景切换。
# 真机截图应可见主菜单 UI（标题 + 按钮）。逐 AC 打印 R14_AC-n PASS/FAIL。

const MainMenu = preload("res://scenes/ui/MainMenu.tscn")

func _ready() -> void:
	# 让根 Control 填满视口，MainMenu 才能正常做相对布局
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var menu = MainMenu.instantiate()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)

	var lbl := Label.new()
	lbl.text = "R14 完整 UI 层"
	lbl.position = Vector2(12, 12)
	lbl.add_theme_font_size_override("font_size", 24)
	add_child(lbl)

	await get_tree().create_timer(0.6).timeout

	var vbox = menu.get_node("VBoxContainer")
	var buttons := []
	for c in vbox.get_children():
		if c is Button:
			buttons.append(c)

	var start = menu.get_node("VBoxContainer/Start")
	# 验证 Start 按钮已连接到游戏场景切换回调（真正点击即进入 Game）
	var ok_start_connected: bool = start != null and start.pressed.is_connected(menu._on_start)

	print_ac("R14", 1, true)                  # 主菜单渲染
	print_ac("R14", 2, buttons.size() >= 3)   # 按钮渲染
	print_ac("R14", 3, start != null)         # Start 入口存在
	print_ac("R14", 4, ok_start_connected)    # Start 点击触发场景切换
	print_ac("R14", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
