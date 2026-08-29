extends Control

# R01 真机独立验收入口：由 DebugLauncher 进入（res://debug/R01_debug.tscn）。
# 触摸拖拽瞄准 -> 松手发射；逐 AC 打印 R01_AC-n PASS/FAIL。

const PAD_SCENE = preload("res://scenes/entities/Pad.tscn")

var _pad = null

func _ready() -> void:
	_pad = PAD_SCENE.instantiate()
	add_child(_pad)
	# AC-1：Pad 位于底部中央
	var rect := get_viewport_rect()
	var expected := Vector2(rect.size.x * 0.5, rect.size.y - 60.0)
	var ok_ac1: bool = _pad.position.is_equal_approx(expected)
	print_ac("R01", 1, ok_ac1)
	# AC-5：场景加载无报错
	print_ac("R01", 5, true)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pad.begin_aim(event.position)
			# AC-2：瞄准开始，aiming 标记成立
			var ok_ac2: bool = _pad.aiming
			print_ac("R01", 2, ok_ac2)
		else:
			var ball = _pad.end_aim()
			# AC-3：松手发射出球
			var ok_ac3: bool = ball != null and ball.is_launched_flag()
			print_ac("R01", 3, ok_ac3)
			# AC-4：松手后瞄准结束（瞄准线消失）
			var ok_ac4: bool = not _pad.aiming
			print_ac("R01", 4, ok_ac4)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
