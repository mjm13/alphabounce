extends Node2D

# AB-P1 核心玩法 MVP 管理器：挡板/球/砖块/墙/HUD/胜负/重开。
# 2026-08-19 v1.1 viewport: 加入版本号 + 调试信息（VP/win/disp/stretch）以诊断横屏铺满问题。

const START_LIVES := 3
const COLS := 9
const ROWS := 5
const BLOCK_W := 120.0
const BLOCK_H := 50.0
const GAP := 16.0
const SCORE_PER_BLOCK := 100
const BUILD_TAG := "viewport"

const PadScript := preload("res://objects/Pad.gd")
const BallScript := preload("res://objects/Ball.gd")
const BlockScript := preload("res://objects/Block.gd")

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

func _ready() -> void:
	call_deferred("_build")

func _build() -> void:
	_build_background()
	_build_walls()
	_build_hud()
	_build_paddle()
	_build_blocks()
	_reset_ball()
	_update_hud()

func _vp() -> Vector2:
	return get_viewport_rect().size

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

func _build_paddle() -> void:
	paddle = PadScript.new()
	paddle.position = Vector2(_vp().x / 2.0, _vp().y * 0.82)
	add_child(paddle)

func _build_blocks() -> void:
	var vps := _vp()
	var total_w := COLS * BLOCK_W + (COLS - 1) * GAP
	var start_x := (vps.x - total_w) / 2.0 + BLOCK_W / 2.0
	var start_y := 200.0
	for r in ROWS:
		for c in COLS:
			var b := BlockScript.new()
			b.durability = 1
			b.max_durability = 1
			b.game = self
			b.position = Vector2(start_x + c * (BLOCK_W + GAP), start_y + r * (BLOCK_H + GAP))
			add_child(b)
			blocks_remaining += 1

func _reset_ball() -> void:
	if ball != null:
		ball.queue_free()
	ball = BallScript.new()
	ball.position = Vector2(paddle.position.x, paddle.position.y - 60.0)
	ball.launch(Vector2(randf_range(-0.35, 0.35), -1.0))
	add_child(ball)

func _process(_delta: float) -> void:
	if state == "playing":
		paddle.follow_pointer(get_global_mouse_position().x)

func _physics_process(_delta: float) -> void:
	if state != "playing" or ball == null:
		return
	if ball.global_position.y > _vp().y - 10.0:
		_on_ball_lost()

func _on_ball_lost() -> void:
	lives -= 1
	_update_hud()
	if lives <= 0:
		state = "lost"
		_show_message("GAME OVER\nTap to Restart")
	else:
		_reset_ball()

func on_block_destroyed() -> void:
	score += SCORE_PER_BLOCK
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
	if state == "won" or state == "lost":
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
			get_tree().reload_current_scene()
