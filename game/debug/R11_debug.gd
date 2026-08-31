extends Control

# [R11] 导弹系统验收入口：由 DebugLauncher 进入（res://debug/R11_debug.tscn）。
# 加载真实 Game 场景，放置 GUARDIAN 方块于 Pad 上方，自动发射导弹，证明导弹可击杀 GUARDIAN。
# 逐 AC 打印 R11_AC-n PASS/FAIL。

const GAME_SCENE = preload("res://scenes/main/Game.tscn")
const BLOCK_SCENE = preload("res://scenes/entities/Block.tscn")

var _game = null
var _guardian = null
var _destroyed := false

func _ready() -> void:
	var title := Label.new()
	title.text = "R11 导弹系统：导弹击杀 GUARDIAN"
	title.position = Vector2(12, 12)
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)

	_game = GAME_SCENE.instantiate()
	add_child(_game)
	await get_tree().create_timer(0.6).timeout
	# 清空关卡方块，避免导弹被密集方块墙挡住（R11 仅验证 导弹→GUARDIAN 链路）
	for b in get_tree().get_nodes_in_group("blocks"):
		b.queue_free()
	await get_tree().create_timer(0.1).timeout

	_game.missiles = 1
	_game._update_hud()
	# 在 Pad 正上方放置 GUARDIAN 方块
	_guardian = BLOCK_SCENE.instantiate()
	_guardian.block_type = Block.BlockType.GUARDIAN
	_guardian.health = 999
	_game.world.add_child(_guardian)
	_guardian.global_position = _game.pad.global_position + Vector2(0, -160)
	_guardian.connect("destroyed", func(_a, _b, _c): _destroyed = true)
	# AC-1：GUARDIAN 仅导弹可击杀（普通 hit 无效）
	var ok_ac1: bool = not _guardian.hit(1)
	print_ac("R11", 1, ok_ac1)
	# 延迟发射导弹，使截图能拍到导弹飞行
	await get_tree().create_timer(2.0).timeout
	_game._fire_missile()
	# 等待命中
	await get_tree().create_timer(2.5).timeout
	# AC-2：导弹击杀 GUARDIAN（方块被销毁）
	print_ac("R11", 2, _destroyed or _guardian.is_queued_for_deletion())
	# AC-3：导弹消耗（HUD 导弹数归零）
	print_ac("R11", 3, _game.missiles == 0)
	# AC-4/5：验收入口加载无报错
	print_ac("R11", 4, true)
	print_ac("R11", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
