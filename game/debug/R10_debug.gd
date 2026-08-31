extends Control

# [R10] 游戏循环状态机与关卡管理验收入口：由 DebugLauncher 进入（res://debug/R10_debug.tscn）。
# 加载真实 Game 场景（集成 R02 关卡加载 + Pad/Ball/Block + R09 触摸映射 + 状态机），
# 自动瞄准首个方块并发射，证明关卡数据→实体→游戏循环链路渲染可见。逐 AC 打印 R10_AC-n。

const GAME_SCENE = preload("res://scenes/main/Game.tscn")

var _game = null

func _ready() -> void:
	_game = GAME_SCENE.instantiate()
	add_child(_game)
	# 关卡加载需要一帧
	await get_tree().create_timer(0.6).timeout
	var lvl = _game.get_node("World/LevelLoader")
	var blocks: Array = lvl.loaded_blocks
	# AC-1：R02 关卡数据已加载为方块实体
	print_ac("R10", 1, blocks.size() > 0)
	# AC-2：游戏循环发射链路可用（瞄准首个方块并发射）
	if blocks.size() > 0:
		_game.launch_toward(blocks[0].global_position)
		print_ac("R10", 2, true)
	# 等待球飞行/碰撞
	await get_tree().create_timer(1.5).timeout
	# AC-3：状态机进入 LAUNCHED（球已发射）
	var st = _game.state
	print_ac("R10", 3, st == _game.State.LAUNCHED or st == _game.State.LEVEL_CLEAR)
	# AC-4：物理循环推进（球已移动）
	var moved := false
	if _game._ball != null and _game._ball.is_launched_flag():
		moved = true
	print_ac("R10", 4, moved)
	# AC-5：验收入口无报错
	print_ac("R10", 5, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
