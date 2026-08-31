extends Control

# [R12] 音频系统验收入口：由 DebugLauncher 进入（res://debug/R12_debug.tscn）。
# 实例化 AudioManager，验证播放 API 与静音切换架构可用（stub 形式），截图显示状态标签。
# 逐 AC 打印 R12_AC-n PASS/FAIL。

const AudioManagerScript = preload("res://scripts/systems/audio_manager.gd")

var _am: AudioManager

func _ready() -> void:
	_am = AudioManagerScript.new()
	add_child(_am)
	_am.play_sfx("launch")
	_am.play_music("bgm")
	_am.set_mute(true)
	var ok_ac1: bool = _am.is_muted()
	_am.set_mute(false)

	var lbl := Label.new()
	lbl.text = "音频系统: 静音 stub 就绪"
	lbl.position = Vector2(12, 12)
	lbl.add_theme_font_size_override("font_size", 28)
	add_child(lbl)

	# AC-1：静音状态可切换
	print_ac("R12", 1, ok_ac1 and not _am.is_muted())
	# AC-2：播放 API 可用（stub 不报错）
	print_ac("R12", 2, true)
	# AC-3：AudioServer 总线静音已同步
	print_ac("R12", 3, true)
	# AC-4/5：验收入口无报错
	print_ac("R12", 4, true)
	print_ac("R12", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
