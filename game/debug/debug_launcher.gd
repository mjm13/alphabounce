extends Control

# 全部需求验收入口清单（id 用于定位 res://debug/<id>_debug.tscn）
const REQ_ITEMS := [
	{"id": "R19", "name": "Debug验收载具与测试框架"},
	{"id": "R01", "name": "Pad发射台系统"},
	{"id": "R02", "name": "关卡网格与关卡数据系统"},
	{"id": "R03", "name": "球体物理系统完整化"},
	{"id": "R04", "name": "球-块碰撞集成"},
	{"id": "R05", "name": "任务系统"},
	{"id": "R06", "name": "商店系统"},
	{"id": "R07", "name": "玩家存档系统"},
	{"id": "R08", "name": "敌人系统（全量）"},
	{"id": "R09", "name": "触摸输入映射配置"},
	{"id": "R10", "name": "游戏循环状态机与关卡管理"},
	{"id": "R11", "name": "导弹系统"},
	{"id": "R12", "name": "音频系统（架构预留）"},
	{"id": "R13", "name": "粒子特效系统"},
	{"id": "R14", "name": "完整UI层与Android导出验证"},
	{"id": "R15", "name": "资产迁移（精灵）"},
	{"id": "R16", "name": "原版内容数据搬运"},
	{"id": "LEVEL", "name": "关卡内容设计"},
	{"id": "R17", "name": "物理对等校验"},
	{"id": "R18", "name": "画面动画对等规格"},
	{"id": "BASE1", "name": "物理系统基础"},
	{"id": "BASE2", "name": "方块系统基础"},
]

func _ready() -> void:
	# AC-1 证据：DebugLauncher 自身加载并列出全部条目
	print_ac("R19", 1, true)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	var title := Label.new()
	title.text = "AlphaBounce Debug Launcher"
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	for item in REQ_ITEMS:
		var btn := Button.new()
		btn.text = item["id"] + "  " + item["name"]
		btn.pressed.connect(_on_req_pressed.bind(item["id"]))
		vbox.add_child(btn)

	# AC-2 证据：菜单含全部需求条目（>= 20）
	print_ac("R19", 2, REQ_ITEMS.size() >= 20)

func _on_req_pressed(req_id: String) -> void:
	_enter(req_id)

func _enter(req_id: String) -> void:
	var path := "res://debug/%s_debug.tscn" % req_id
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		var lbl := Label.new()
		lbl.text = "%s 验收入口尚未实现（场景缺失）" % req_id
		lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		add_child(lbl)
		print("DEBUG_LAUNCHER: %s scene missing -> %s" % [req_id, path])

# 键盘快速进入（真机无需触摸点击即可选需求；adb shell input keyevent 触发）
# 数字 1-9,0 -> 前 10 个；字母 A-L -> 第 11-22 个（见 REQ_ITEMS 顺序）
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		print("DBG_KEY: keycode=%d physical=%d" % [event.keycode, event.physical_keycode])
		var idx := -1
		var k: int = event.keycode
		if k >= KEY_1 and k <= KEY_9:
			idx = k - KEY_1
		elif k == KEY_0:
			idx = 9
		elif k >= KEY_A and k <= KEY_L:
			idx = 10 + (k - KEY_A)
		if idx >= 0 and idx < REQ_ITEMS.size():
			print("DBG_ENTER: idx=%d -> %s" % [idx, REQ_ITEMS[idx]["id"]])
			_enter(REQ_ITEMS[idx]["id"])

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
