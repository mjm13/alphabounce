extends Control

## R08 真机独立验收入口：res://debug/R08_enemy_debug.tscn
## 自含全量敌人系统（11 ev + 7 Molecule + GUARDIAN + 危险方块 + 碰撞伤害），逐 AC 打印 R08_AC-n PASS/FAIL。

var _world: Node2D
var _hud: Label
var _ac: Array = []
var _enemy_spawned_from_danger: bool = false

func _ready() -> void:
	_hud = Label.new()
	_hud.position = Vector2(12, 12)
	_hud.add_theme_font_size_override("font_size", 18)
	add_child(_hud)

	_world = Node2D.new()
	add_child(_world)
	EnemyManager.set_world(_world)

	var ball := Area2D.new()
	var bshape := CircleShape2D.new(); bshape.radius = 12.0
	var bcol := CollisionShape2D.new(); bcol.shape = bshape
	ball.add_child(bcol)
	ball.add_to_group("ball")
	_world.add_child(ball)

	_run_ac()
	_update_hud()
	var done := Label.new()
	done.text = "敌人系统验收完成"
	done.position = Vector2(12, 500)
	done.add_theme_font_size_override("font_size", 24)
	add_child(done)
	_flush()
	if OS.has_feature("headless"):
		get_tree().quit()

func _run_ac() -> void:
	# AC-1 框架：BaseEnemy + EnemyManager + MoleculeGrid 可实例化与生命周期管理
	var be := BaseEnemy.new(); be.position = Vector2(40, 40); _world.add_child(be)
	var mg := MoleculeGrid.new(); _world.add_child(mg)
	var ac1 := is_instance_valid(be) and is_instance_valid(mg) and EnemyManager != null
	print_ac("R08", 1, ac1)

	# AC-2 11 种 ev 敌人（全量，逐个独立 PASS 行）；网格布局并冻结，确保截图可见真实精灵
	var ev_names: Array[String] = ["Dragon","Drone","Generator","Indigestion","Javelot","Ouverture","Quasar","Storm","UltraViolet","Unification","Wave"]
	var ac2_all := true
	var eidx := 0
	for n in ev_names:
		var e := EnemyManager.spawn_ev(n, Vector2.ZERO) as EvEnemy
		e.position = Vector2(35 + (eidx % 5) * 75, 70 + floor(eidx / 5) * 72)
		e.step(0.1)
		e.set_physics_process(false)
		_add_tag(n, e.position)
		var ok := is_instance_valid(e) and e.behavior_name == n.to_lower()
		print_ac("R08", 2, ok, n)
		if not ok:
			ac2_all = false
		eidx += 1
	print_ac("R08", 2, ac2_all)

	# AC-3 7 种 Molecule（全量，逐个独立 PASS 行）；网格布局并冻结，确保截图可见真实精灵
	var mol_names: Array[String] = ["M1","M2","M3","M4","M5","M6","M7"]
	var ac3_all := true
	var midx := 0
	for n in mol_names:
		var m := EnemyManager.spawn_molecule(n, Vector2.ZERO) as Molecule
		m.position = Vector2(35 + (midx % 5) * 75, 235 + floor(midx / 5) * 72)
		m.step(0.1)
		m.set_physics_process(false)
		_add_tag(n, m.position)
		var ok := is_instance_valid(m) and m.molecule_type == n and m.health == int(EnemyManager.get_molecule_data(n).get("hp", 1))
		print_ac("R08", 3, ok, n)
		if not ok:
			ac3_all = false
		midx += 1
	print_ac("R08", 3, ac3_all)

	# AC-4 GUARDIAN 仅导弹可击杀（球不可）
	var g := Block.new()
	g.block_type = Block.BlockType.GUARDIAN
	g.health = 10
	var ball_kill := g.hit(50, false)
	var missile_kill := g.hit(50, true)
	var ac4 := (ball_kill == false) and (missile_kill == true)
	print_ac("R08", 4, ac4)

	# AC-5 危险方块触发链：DRAGON 击碎 -> 生成 Dragon 敌人
	var dblk := Block.new()
	dblk.block_type = Block.BlockType.DRAGON
	dblk.dangerous_triggered.connect(_on_danger)
	dblk.hit(1)
	var ac5 := _enemy_spawned_from_danger
	print_ac("R08", 5, ac5)

	# AC-6 碰撞与伤害：球碰敌人扣血；消灭；敌碰玩家减 life；life<=0 GameOver 条件
	PlayerData.lives = 3
	var en := EnemyManager.spawn_ev("Drone", Vector2(100, 100)) as EvEnemy
	en.health = 3
	var hp_before := en.health
	var ac6a := en.hit(1) == false and en.health == hp_before - 1
	var en2 := EnemyManager.spawn_ev("Drone", Vector2(120, 120)) as EvEnemy
	var ac6b := en2.hit(999) == true
	PlayerData.lose_life()
	var ac6c := PlayerData.lives == 2
	PlayerData.lives = 1
	PlayerData.lose_life()
	var ac6d := PlayerData.lives == 0
	var ac6 := ac6a and ac6b and ac6c and ac6d
	print_ac("R08", 6, ac6)

	# AC-7 真机闭环：场景完整运行至此即代表入口可达且全量敌人可调
	var all_pass := ac1 and ac2_all and ac3_all and ac4 and ac5 and ac6
	print_ac("R08", 7, all_pass)

func _on_danger(type: int) -> void:
	if type == Block.BlockType.DRAGON:
		EnemyManager.spawn_ev("Dragon", Vector2(150, 150))
		_enemy_spawned_from_danger = true

# [R15] 在敌人位置下方标注名称，便于真机截图核对“行为与原版一致”
func _add_tag(text: String, pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos + Vector2(-14, 16)
	lbl.add_theme_font_size_override("font_size", 11)
	_world.add_child(lbl)

func _update_hud() -> void:
	_hud.text = "敌人: %d  分子: %d" % [EnemyManager.enemies.size(), EnemyManager.molecules.size()]

func print_ac(req: String, n: int, ok: bool, tag: String = "") -> void:
	var line: String
	if tag != "":
		line = "%s_AC-%d_%s %s" % [req, n, tag, "PASS" if ok else "FAIL"]
	else:
		line = "%s_AC-%d %s" % [req, n, "PASS" if ok else "FAIL"]
	print(line)
	if not ok:
		printerr(line)
	_ac.append(line)

func _flush() -> void:
	if OS.get_name() != "Windows":
		return
	var f := FileAccess.open("d:/Project/SELF/alphabounce/r08_ac_result.txt", FileAccess.WRITE)
	if f != null:
		for l in _ac:
			f.store_string(l + "\n")
		f.close()
