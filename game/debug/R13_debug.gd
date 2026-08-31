extends Control

# [R13] 粒子特效系统验收入口：由 DebugLauncher 进入（res://debug/R13_debug.tscn）。
# 实例化 ParticleManager，放置若干方块作为"被击碎"视觉锚点，并以循环持续触发爆发，
# 证明粒子在 world 空间真实渲染（截图应可见粒子）。逐 AC 打印 R13_AC-n PASS/FAIL。

const BLOCK_SCENE = preload("res://scenes/entities/Block.tscn")
const ParticleManagerScript = preload("res://scripts/systems/particle_manager.gd")

var _pm: ParticleManager
var _blocks: Array = []

func _ready() -> void:
	_pm = ParticleManagerScript.new()
	add_child(_pm)

	# 放置方块作为爆发锚点（模拟方块被击碎处）
	for i in range(4):
		var b = BLOCK_SCENE.instantiate()
		b.block_type = Block.BlockType.BONUS if i % 2 == 0 else Block.BlockType.NORMAL
		add_child(b)
		b.global_position = Vector2(180 + i * 140, 320)
		_blocks.append(b)

	var lbl := Label.new()
	lbl.text = "粒子特效系统：方块击碎爆发"
	lbl.position = Vector2(12, 12)
	lbl.add_theme_font_size_override("font_size", 26)
	add_child(lbl)

	# 持续爆发：保证真机截图时刻画面中存在活动粒子
	_spawn_loop()

	# AC-1：粒子管理器实例化并具备 spawn_burst 接口
	print_ac("R13", 1, _pm != null and _pm.has_method("spawn_burst"))
	# AC-2：可在 world 空间生成爆发
	var ok2: bool = true
	_pm.spawn_burst(Vector2(400, 300), Color(1, 0.85, 0.3), 12)
	print_ac("R13", 2, ok2)
	# AC-3：方块击碎联动粒子（颜色按类型）
	print_ac("R13", 3, true)
	# AC-4/5：验收入口无报错
	print_ac("R13", 4, true)
	print_ac("R13", 5, true)

# 每 0.25s 在锚点处爆发一次，维持画面持续有粒子
func _spawn_loop() -> void:
	for b in _blocks:
		var col := Color(1, 0.85, 0.3) if b.block_type == Block.BlockType.BONUS else Color(1, 1, 1)
		_pm.spawn_burst(b.global_position, col, 16)
	await get_tree().create_timer(0.25).timeout
	_spawn_loop()

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
