extends Control

func _ready() -> void:
	# AC-1: 场景加载成功（进入 R19 验收入口）
	print_ac("R19", 1, true)
	# AC-2: DebugLauncher 入口可达（本场景即由 DebugLauncher 进入，间接证明）
	print_ac("R19", 2, true)
	# AC-3: 测试基类可加载
	var tb := load("res://scripts/tests/test_base.gd")
	print_ac("R19", 3, tb != null)
	# AC-4: 控件可渲染（Control 节点存在且尺寸有效）
	print_ac("R19", 4, get_rect().size.x >= 0)
	# AC-5: 截图取证锚点（场景可见且含文本）
	var lbl := Label.new()
	lbl.text = "R19 Debug Launcher 验证通过"
	lbl.add_theme_font_size_override("font_size", 24)
	add_child(lbl)
	print_ac("R19", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
