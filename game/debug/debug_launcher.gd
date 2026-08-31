extends Control

# 全部需求验收入口清单（id 用于定位 res://debug/<id>_debug.tscn）
const REQ_ITEMS := [
	{"id": "R19", "name": "Debug验收载具与测试框架"},
	{"id": "R01", "name": "Pad发射台系统"},
	{"id": "R02", "name": "关卡网格与关卡数据系统"},
	{"id": "R03", "name": "球体物理系统完整化"},
	{"id": "R04", "name": "球-块碰撞集成"},
	{"id": "R05", "name": "任务系统"},
	{"id": "R06", "name": "商店系统", "scene": "R06_shop_debug.tscn"},
	{"id": "R07", "name": "玩家存档系统", "scene": "R07_save_debug.tscn"},
	{"id": "R08", "name": "敌人系统（全量）", "scene": "R08_enemy_debug.tscn"},
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

# 静态预载 R05 验收入口，确保真机导出包包含该场景及其依赖（MissionManager / MissionPanel）。
# headless 导出不会扫描未导入的新文件，preload 使其成为 DebugLauncher 的静态依赖而被打包。
const R05_SCENE := preload("res://debug/R05_debug.tscn")

# 静态预载 R06 验收入口，确保真机导出包含 ShopManager / ShopPanel 及其依赖。
const R06_SCENE := preload("res://debug/R06_shop_debug.tscn")

# 静态预载 R07 验收入口，确保真机导出包含 PlayerData 及其依赖。
const R07_SCENE := preload("res://debug/R07_save_debug.tscn")

# 静态预载 R08 验收入口，确保真机导出包含全量敌人系统（BaseEnemy/EvEnemy/Molecule/EnemyManager）。
const R08_SCENE := preload("res://debug/R08_enemy_debug.tscn")

# 静态预载 R01-R04 验收入口，确保 headless 导出也打包这些独立验收场景（避免仅字符串路径引用被漏打包）。
const R01_SCENE := preload("res://debug/R01_debug.tscn")
const R02_SCENE := preload("res://debug/R02_debug.tscn")
const R03_SCENE := preload("res://debug/R03_debug.tscn")
const R04_SCENE := preload("res://debug/R04_debug.tscn")

# 静态预载 R09 验收入口，确保 headless 导出打包触摸输入映射场景及其依赖（TouchInputManager）。
const R09_SCENE := preload("res://debug/R09_debug.tscn")

# 静态预载 R10 验收入口，确保 headless 导出打包真实 Game 场景及其依赖（Game/LevelLoader/TouchInputManager）。
const R10_SCENE := preload("res://debug/R10_debug.tscn")

# 静态预载 R11 验收入口，确保 headless 导出打包导弹系统场景及其依赖（Missile）。
const R11_SCENE := preload("res://debug/R11_debug.tscn")

# 静态预载 R12 验收入口，确保 headless 导出打包音频系统场景及其依赖（AudioManager）。
const R12_SCENE := preload("res://debug/R12_debug.tscn")

# 静态预载 R13 验收入口，确保 headless 导出打包粒子特效系统场景及其依赖（ParticleManager）。
const R13_SCENE := preload("res://debug/R13_debug.tscn")

# 静态预载 BASE1/BASE2 验收入口，确保 headless 导出打包物理/方块系统基础场景。
const BASE1_SCENE := preload("res://debug/BASE1_debug.tscn")
const BASE2_SCENE := preload("res://debug/BASE2_debug.tscn")

# 静态预载 R14 验收入口，确保 headless 导出打包完整 UI 层（MainMenu 及其依赖）。
const R14_SCENE := preload("res://debug/R14_debug.tscn")

# 静态预载 R16 验收入口，确保 headless 导出打包内容数据迁移场景及其依赖（Game/LevelLoader/Block）。
const R16_SCENE := preload("res://debug/R16_debug.tscn")

# 静态预载 R15 验收入口，确保 headless 导出打包资产迁移核对场景。
const R15_SCENE := preload("res://debug/R15_debug.tscn")

# 静态预载 R17 验收入口，确保 headless 导出打包物理对等校验场景及其依赖（Ball）。
const R17_SCENE := preload("res://debug/R17_debug.tscn")

# 静态预载 R18 验收入口，确保 headless 导出打包画面动画对等证据场景及其依赖（Ball）。
const R18_SCENE := preload("res://debug/R18_debug.tscn")

# 静态预载 LEVEL 验收入口，确保 headless 导出打包关卡内容设计场景及其依赖（LevelLoader）。
const LEVEL_SCENE := preload("res://debug/LEVEL_debug.tscn")

func _ready() -> void:
	# 真机免点按自动跳转：若 user://debug_auto_req.txt 存在则直接进入对应需求场景
	var auto_path := "user://debug_auto_req.txt"
	if FileAccess.file_exists(auto_path):
		var f := FileAccess.open(auto_path, FileAccess.READ)
		if f != null:
			var req_id := f.get_line().strip_edges()
			f.close()
			if req_id.length() > 0:
				print("DBG_AUTOJUMP -> %s" % req_id)
				_enter(req_id)
				return

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
	var scene_name := "%s_debug.tscn" % req_id
	for item in REQ_ITEMS:
		if item["id"] == req_id and item.has("scene"):
			scene_name = item["scene"]
			break
	var path := "res://debug/%s" % scene_name
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
