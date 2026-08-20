extends Node2D

# AB-P1 核心玩法 MVP 管理器：挡板/球/砖块/墙/HUD/胜负/重开。
# 2026-08-19 v1.2 diag: 加入实时诊断日志面板（FPS/球状态/触控/物理帧/碰撞计数/输入事件流）。

const START_LIVES := 3
const COLS := 9
const ROWS := 5
const SCORE_PER_BLOCK := 100
const BUILD_TAG := "diag"

const PadScript := preload("res://objects/Pad.gd")
const BallScript := preload("res://objects/Ball.gd")
const BlockScript := preload("res://objects/Block.gd")
const BSScript := preload("res://scripts/brick_system.gd")
const MetricsScript := preload("res://scripts/game_metrics.gd")

var BLOCK_W := 96.0
var BLOCK_H := 48.0
var GAP := 12.0
var BALL_D := 26.0
var PAD_W := 320.0
var PAD_H := 36.0

var score := 0
var lives := START_LIVES
var blocks_remaining := 0
var state := "playing"  # playing | won | lost

var paddle  # Pad 实例
var ball    # Ball 实例
var score_label: Label
var lives_label: Label
var message_label: Label
var version_label: Label
var debug_label: Label
var diag_label: Label  # 实时诊断面板

# ---- 诊断计数器 ----
var _frame_count := 0
var _physics_tick := 0
var _collision_count := 0
var _fps_accum := 0.0
var _fps_frames := 0
var _fps_displayed := 0.0
var _fps_timer := 0.0
var _last_touch_x := -1.0
var _touch_active := false
var _input_log: Array[String] = []  # 最近 N 条输入事件
const INPUT_LOG_MAX := 6
var _diag_lines: Array[String] = []

func _ready() -> void:
	call_deferred("_build")

func _build() -> void:
	_apply_layout_metrics()
	_build_background()
	_build_walls()
	_build_hud()
	_build_paddle()
	_build_blocks()
	_reset_ball()
	_update_hud()

func _vp() -> Vector2:
	return get_viewport_rect().size

func _apply_layout_metrics() -> void:
	var m: Dictionary = MetricsScript.layout_for_viewport(_vp(), COLS)
	BLOCK_W = m["block_w"]
	BLOCK_H = m["block_h"]
	GAP = m["gap"]
	BALL_D = m["ball_d"]
	PAD_W = m["pad_w"]
	PAD_H = m["pad_h"]

func block_w() -> float:
	return BLOCK_W

func block_h() -> float:
	return BLOCK_H

func ball_size() -> float:
	return BALL_D

func pad_width() -> float:
	return PAD_W

func pad_height() -> float:
	return PAD_H

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = _vp()
	bg.color = Color(0.06, 0.08, 0.14)
	bg.position = Vector2.ZERO
	add_child(bg)
	get_viewport().connect("size_changed", _on_size_changed)

func _on_size_changed() -> void:
	var bg := get_node_or_null("Background")
	if bg != null:
		bg.size = _vp()
	_position_lives_label()
	_position_version_label()
	_update_debug_label()
	_position_diag_label()

func _position_diag_label() -> void:
	if diag_label == null:
		return
	var vps := _vp()
	diag_label.size = Vector2(vps.x * 0.52, 320)
	diag_label.position = Vector2(16, vps.y - 340)

func _build_walls() -> void:
	# 左、右、上三堵不可见静态墙；底部留空（球落底=判负）。
	var vps := _vp()
	var t := 60.0
	var specs := [
		[Vector2(-t / 2.0, vps.y / 2.0), Vector2(t, vps.y * 2.0)],
		[Vector2(vps.x + t / 2.0, vps.y / 2.0), Vector2(t, vps.y * 2.0)],
		[Vector2(vps.x / 2.0, -t / 2.0), Vector2(vps.x * 2.0, t)],
	]
	for s in specs:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.shape.size = s[1]
		body.add_child(shape)
		body.position = s[0]
		add_child(body)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.add_theme_font_size_override("font_size", 44)
	score_label.position = Vector2(40, 110)
	hud.add_child(score_label)

	lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.add_theme_color_override("font_color", Color.WHITE)
	lives_label.add_theme_font_size_override("font_size", 44)
	lives_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(lives_label)
	_position_lives_label()

	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4))
	message_label.add_theme_font_size_override("font_size", 80)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.size = Vector2(_vp().x, _vp().y * 0.6)
	message_label.position = Vector2(0, _vp().y * 0.2)
	message_label.visible = false
	hud.add_child(message_label)

	# 版本号（右上角，区分是否成功升级到 viewport 构建）
	version_label = Label.new()
	version_label.name = "VersionLabel"
	version_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.72))
	version_label.add_theme_font_size_override("font_size", 26)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(version_label)
	_position_version_label()
	_update_version_label()

	# 调试信息（顶部居中）：VP=根视口、win=窗口、disp=物理屏幕、stretch=拉伸模式
	debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.6))
	debug_label.add_theme_font_size_override("font_size", 20)
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(debug_label)
	_position_debug_label()
	_update_debug_label()

	# ===== 实时诊断日志面板（左下角，半透明深色背景）=====
	diag_label = Label.new()
	diag_label.name = "DiagLabel"
	diag_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.80))
	diag_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(diag_label)
	_position_diag_label()

func _position_lives_label() -> void:
	if lives_label == null:
		return
	var vps := _vp()
	lives_label.size = Vector2(460, 60)
	lives_label.position = Vector2(vps.x - 500, 110)

func _position_version_label() -> void:
	if version_label == null:
		return
	var vps := _vp()
	version_label.size = Vector2(480, 32)
	version_label.position = Vector2(vps.x - 500, 150)

func _update_version_label() -> void:
	if version_label == null:
		return
	var v := str(ProjectSettings.get_setting("application/config/version", "?.?"))
	version_label.text = "v%s %s" % [v, BUILD_TAG]

func _position_debug_label() -> void:
	if debug_label == null:
		return
	var vps := _vp()
	debug_label.size = Vector2(vps.x - 80, 26)
	debug_label.position = Vector2(40, 150)

func _update_debug_label() -> void:
	if debug_label == null:
		return
	var vp := _vp()
	var win := Vector2.ZERO
	var disp := Vector2.ZERO
	if DisplayServer != null:
		win = DisplayServer.window_get_size()
		disp = DisplayServer.screen_get_size()
	var mode := str(ProjectSettings.get_setting("display/window/stretch/mode", "?"))
	var aspect := str(ProjectSettings.get_setting("display/window/stretch/aspect", "?"))
	debug_label.text = "VP %dx%d  win %dx%d  disp %dx%d  stretch=%s aspect=%s" % [int(vp.x), int(vp.y), int(win.x), int(win.y), int(disp.x), int(disp.y), mode, aspect]

func _update_diag_label() -> void:
	if diag_label == null:
		return
	_diag_lines.clear()

	# --- 第 1 行：帧率与时间 ---
	_diag_lines.append("[DIAG] FPS %.1f | frame %d | phys_tick %d | state=%s" % [_fps_displayed, _frame_count, _physics_tick, state])

	# --- 第 2 行：球状态 ---
	if ball != null and is_instance_valid(ball):
		var bv: Vector2 = ball.velocity if ball.velocity != null else Vector2.ZERO
		var bp: Vector2 = ball.global_position
		var speed: float = bv.length()
		var angle := rad_to_deg(atan2(bv.y, bv.x))
		_diag_lines.append("BALL pos(%.0f,%.0f) vel(%.0f,%.0f) spd=%.0f ang=%.1f°" % [bp.x, bp.y, bv.x, bv.y, speed, angle])
	else:
		_diag_lines.append("BALL (null)")

	# --- 第 3 行：挡板状态 ---
	if paddle != null and is_instance_valid(paddle):
		_diag_lines.append("PAD  pos(%.0f,%.0f) hw=%.0f | touch_x=%.0f active=%s" % [paddle.global_position.x, paddle.global_position.y, paddle.half_width, _last_touch_x, _touch_active])
	else:
		_diag_lines.append("PAD  (null)")

	# --- 第 4 行：碰撞与游戏数据 ---
	_diag_lines.append("DATA collisions=%d | blocks_left=%d | score=%d | lives=%d" % [_collision_count, blocks_remaining, score, lives])

	# --- 第 5+ 行：输入事件流 ---
	if _input_log.size() > 0:
		_diag_lines.append("--- INPUT LOG ---")
		for i in range(_input_log.size()):
			_diag_lines.append("  [%d] %s" % [i, _input_log[i]])
	else:
		_diag_lines.append("--- INPUT: (none yet) ---")

	diag_label.text = "\n".join(_diag_lines)

func _build_paddle() -> void:
	paddle = PadScript.new()
	paddle.configure(PAD_W, PAD_H)
	paddle.position = Vector2(_vp().x / 2.0, _vp().y * 0.82)
	add_child(paddle)

func _build_blocks() -> void:
	var reg := BSScript.BlocksRegistry.new()
	var n := reg.load_from_file()
	if n == 0:
		push_error("LevelBase: blocks.json 加载失败，无法生成砖块")
		return
	var defs: Array = reg.get_all()
	var vps := _vp()
	var total_w := COLS * BLOCK_W + (COLS - 1) * GAP
	var start_x := (vps.x - total_w) / 2.0 + BLOCK_W / 2.0
	var start_y := _vp().y * 0.14
	var idx := 0
	for r in ROWS:
		for c in COLS:
			var b := BlockScript.new()
			b.game = self
			b.setup_from_def(defs[idx % defs.size()])
			idx += 1
			b.position = Vector2(start_x + c * (BLOCK_W + GAP), start_y + r * (BLOCK_H + GAP))
			add_child(b)
			if b.counts_toward_win:
				blocks_remaining += 1

func _reset_ball() -> void:
	if ball != null:
		ball.queue_free()
	ball = BallScript.new()
	ball.configure(BALL_D)
	ball.position = Vector2(paddle.position.x, paddle.position.y - BALL_D * 1.4)
	ball.launch(Vector2(randf_range(-0.35, 0.35), -1.0))
	add_child(ball)

func _process(_delta: float) -> void:
	_frame_count += 1
	# FPS 计算（每秒刷新一次显示值）
	_fps_accum += _delta if _delta > 0.0 else 0.016
	_fps_frames += 1
	_fps_timer += _delta
	if _fps_timer >= 1.0:
		if _fps_frames > 0:
			_fps_displayed = _fps_frames / _fps_timer
		_fps_timer = 0.0
		_fps_frames = 0
		_fps_accum = 0.0

	if state == "playing":
		paddle.follow_pointer(get_global_mouse_position().x)
		# 记录触控/鼠标 X（用于诊断输入是否正常）
		_last_touch_x = get_global_mouse_position().x
		_touch_active = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	_update_diag_label()

func _physics_process(_delta: float) -> void:
	_physics_tick += 1
	if state != "playing" or ball == null:
		return
	# 碰撞检测：球速度突变 = 发生了反弹/碰撞
	var prev_vel: Vector2 = ball.velocity if ball.velocity != null else Vector2.ZERO
	if ball.global_position.y > _vp().y - 10.0:
		_on_ball_lost()
	# 下一帧再检测速度变化（move_and_collide 在 _physics_process 内执行）
	call_deferred("_check_collision", prev_vel)

func _check_collision(prev_vel: Vector2) -> void:
	if ball == null or not is_instance_valid(ball):
		return
	if ball.velocity != prev_vel and prev_vel.length_squared() > 0:
		_collision_count += 1

func _on_ball_lost() -> void:
	lives -= 1
	_update_hud()
	if lives <= 0:
		state = "lost"
		_show_message("GAME OVER\nTap to Restart")
	else:
		_reset_ball()

func on_block_destroyed(block_score: int = SCORE_PER_BLOCK) -> void:
	score += block_score
	blocks_remaining -= 1
	_update_hud()
	if blocks_remaining <= 0:
		state = "won"
		_show_message("YOU WIN!\nTap to Restart")

func _update_hud() -> void:
	if score_label != null:
		score_label.text = "SCORE %d" % score
	if lives_label != null:
		lives_label.text = "LIVES %d" % lives

func _show_message(msg: String) -> void:
	if message_label != null:
		message_label.text = msg
		message_label.visible = true

func _input(event: InputEvent) -> void:
	# 记录输入事件到日志（用于诊断触控/按键是否正常到达）
	var entry := ""
	if event is InputEventScreenTouch:
		entry = "TOUCH %s pos(%.0f,%.0f)" % ["DOWN" if event.pressed else "UP", event.position.x, event.position.y]
	elif event is InputEventScreenDrag:
		entry = "DRAG  pos(%.0f,%.0f)" % [event.position.x, event.position.y]
	elif event is InputEventMouseButton:
		entry = "MOUSE %s btn=%d" % ["DOWN" if event.pressed else "UP", event.button_index]
	elif event is InputEventMouseMotion:
		pass  # 太频繁，跳过
	if entry != "":
		_input_log.append(entry)
		if _input_log.size() > INPUT_LOG_MAX:
			_input_log.pop_front()

	if state == "won" or state == "lost":
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
			get_tree().reload_current_scene()
