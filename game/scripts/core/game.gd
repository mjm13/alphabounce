extends Node2D
class_name Game

const BALL_SCENE = preload("res://scenes/entities/Ball.tscn")
const MISSILE_SCENE = preload("res://scenes/entities/Missile.tscn")
const TouchInputManagerScript = preload("res://scripts/systems/touch_input.gd")
const ParticleManagerScript = preload("res://scripts/systems/particle_manager.gd")

# [R10] 游戏循环状态机
enum State { READY, LAUNCHED, LEVEL_CLEAR, GAME_OVER }
var state: int = State.READY

var score: int = 0
var lives: int = 3
var missiles: int = 0
var _ball: Node = null
var _particle_manager: Node = null

@onready var camera = $Camera2D
@onready var world = $World
@onready var pad = $World/Pad
@onready var hud_score = $HUD/Score
@onready var hud_lives = $HUD/Lives
@onready var hud_missile = $HUD/Missile

func _ready():
	# 集成 R09 触摸输入映射：由 TouchInputManager 统一驱动 Pad 瞄准/发射
	var ti = TouchInputManagerScript.new()
	add_child(ti)
	ti.action.connect(_on_action)
	# 禁用 Pad 自带输入，避免与 Game 状态机重复发射
	pad.set_process_input(false)
	# 关卡方块加载后接入计分信号
	for b in $World/LevelLoader.loaded_blocks:
		if b.has_signal("destroyed"):
			b.connect("destroyed", _on_block_destroyed)
	# [R13] 粒子特效管理器（世界空间）
	_particle_manager = ParticleManagerScript.new()
	world.add_child(_particle_manager)
	_add_walls()
	_spawn_ball_on_pad()
	_update_hud()

# 左/右/顶墙：约束球在 800x600 场地内反弹
func _add_walls() -> void:
	var specs := [
		{"pos": Vector2(8, 300), "size": Vector2(16, 600)},
		{"pos": Vector2(792, 300), "size": Vector2(16, 600)},
		{"pos": Vector2(400, 8), "size": Vector2(800, 16)},
	]
	for s in specs:
		var sb := StaticBody2D.new()
		sb.position = s["pos"]
		var shape := RectangleShape2D.new()
		shape.size = s["size"]
		var cs := CollisionShape2D.new()
		cs.shape = shape
		sb.add_child(cs)
		world.add_child(sb)

# [R10] READY：球停在 Pad 上待发射
func _spawn_ball_on_pad() -> void:
	if _ball != null:
		_ball.queue_free()
	_ball = BALL_SCENE.instantiate()
	world.add_child(_ball)
	_ball.global_position = pad.global_position + Vector2(0, -18)
	_ball.is_launched = false
	if _ball.has_signal("block_hit"):
		_ball.connect("block_hit", _on_ball_hit)
	state = State.READY

func _on_action(name: String, payload: Variant) -> void:
	if name == "aim_start" and payload is Vector2:
		pad.begin_aim(payload)
	elif name == "aim_move" and payload is Vector2:
		pad.update_aim(payload)
	elif name == "aim_release":
		launch()

# [R10] 由触摸映射驱动发射；也可由集成代码直接调用
func launch() -> void:
	if state != State.READY:
		return
	var dir: Vector2 = pad.aim_direction
	if dir == Vector2.ZERO:
		return
	pad.end_aim()
	_ball.global_position = pad.global_position + Vector2(0, -18)
	_ball.launch(dir)
	state = State.LAUNCHED
	_update_hud()

# 集成发射：瞄准指定目标点并发射
func launch_toward(target: Vector2) -> void:
	pad.aim_direction = (target - pad.global_position).normalized()
	launch()

func _on_ball_hit(block) -> void:
	pass  # 计分在 _on_block_destroyed 处理

func _on_block_destroyed(pos, block_type, score_value):
	score += int(score_value)
	_update_hud()
	# [R13] 方块击碎触发粒子爆发
	if _particle_manager != null:
		_particle_manager.spawn_burst(pos, _block_color(int(block_type)), 18)
	_check_clear()

# 不同类型方块击碎时的粒子色调（与原版视觉风格接近）
func _block_color(bt: int) -> Color:
	var m := {
		Block.BlockType.NORMAL: Color(1, 1, 1),
		Block.BlockType.STEEL: Color(0.7, 0.7, 0.85),
		Block.BlockType.BONUS: Color(1, 0.85, 0.3),
		Block.BlockType.EXPLOSIVE: Color(1, 0.5, 0.2),
		Block.BlockType.GUARDIAN: Color(0.3, 0.8, 1.0),
	}
	return m.get(bt, Color(1, 1, 1))

func _check_clear() -> void:
	var remaining := get_tree().get_nodes_in_group("blocks").size()
	if remaining == 0:
		state = State.LEVEL_CLEAR
		_show_message("关卡完成! 分数=%d" % score)

func _physics_process(_delta: float) -> void:
	if state == State.LAUNCHED and _ball != null:
		# 死亡区：球越过 Pad 下方 → 扣命并复位
		if _ball.global_position.y > 640.0:
			_lose_life()

func _lose_life() -> void:
	lives -= 1
	_update_hud()
	if lives <= 0:
		state = State.GAME_OVER
		_show_message("游戏结束")
	else:
		_spawn_ball_on_pad()

# [R11] 导弹发射：从 Pad 向上射出导弹，唯一能击杀 GUARDIAN 的途径
func _fire_missile():
	if missiles <= 0:
		return
	missiles -= 1
	_update_hud()
	var m = MISSILE_SCENE.instantiate()
	world.add_child(m)
	m.global_position = pad.global_position + Vector2(0, -18)
	m.launch(Vector2.UP)

func _show_message(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(12, 110)
	lbl.add_theme_font_size_override("font_size", 32)
	add_child(lbl)

func _add_score(points: int):
	score += points
	_update_hud()

func _update_hud():
	hud_score.text = "分数: %d" % score
	hud_lives.text = "生命: %d" % lives
	hud_missile.text = "导弹: %d" % missiles
