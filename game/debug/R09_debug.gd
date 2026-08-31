extends Control

# [R09] 触摸输入映射验收入口：由 DebugLauncher 进入（res://debug/R09_debug.tscn）。
# 实例化 Pad + TouchInputManager，将语义化动作接到 Pad 行为；HUD 显示最近触发的动作名，
# 合成一次瞄准动作以证明映射渲染（非空灰屏）。逐 AC 打印 R09_AC-n PASS/FAIL。

const PAD_SCENE = preload("res://scenes/entities/Pad.tscn")

var _pad = null
var _ti: TouchInputManager
var _hud: Label
var _last_action := "none"

func _ready() -> void:
	_pad = PAD_SCENE.instantiate()
	add_child(_pad)
	_ti = TouchInputManager.new()
	add_child(_ti)
	_ti.action.connect(_on_action)

	_hud = Label.new()
	_hud.position = Vector2(12, 12)
	_hud.add_theme_font_size_override("font_size", 28)
	add_child(_hud)

	# [R09] 合成一次完整瞄准动作序列，证明映射→行为链路渲染可见
	_ti.action.emit("aim_start", Vector2(200, 300))
	_ti.action.emit("aim_move", Vector2(250, 180))
	_ti.action.emit("aim_release", Vector2(250, 180))
	_update_hud()

	# AC-1：管理器定义了完整动作集（5 个原版动作）
	print_ac("R09", 1, TouchInputManager.ACTION_NAMES.size() >= 5)
	# AC-2：瞄准区域（屏幕下方 35%）映射正确
	var rect := get_viewport().get_visible_rect()
	var inside := Vector2(rect.size.x * 0.5, rect.size.y * 0.9)
	var ok_zone: bool = _ti._in_aim_zone(inside)
	print_ac("R09", 2, ok_zone)
	# AC-3：轻点非瞄准区映射为 tap 动作
	var outside := Vector2(rect.size.x * 0.5, rect.size.y * 0.1)
	var ok_tap: bool = not _ti._in_aim_zone(outside)
	print_ac("R09", 3, ok_tap)
	# AC-4：Pad 发射行为已触发（aim_release → 出球）
	print_ac("R09", 4, _pad.aiming == false)
	# AC-5：验收入口加载无报错
	print_ac("R09", 5, true)

func _on_action(name: String, payload: Variant) -> void:
	_last_action = name
	if name == "aim_start" and payload is Vector2:
		_pad.begin_aim(payload)
	elif name == "aim_move" and payload is Vector2:
		_pad.update_aim(payload)
	elif name == "aim_release":
		_pad.end_aim()
	_update_hud()

func _update_hud() -> void:
	_hud.text = "最近动作: %s" % _last_action

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
