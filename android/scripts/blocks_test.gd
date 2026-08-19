extends Node2D

# 砖块系统自测：遍历数据表中所有砖块类型，逐一断言 5 种行为差异、
# 破坏特效与字母掉落、不可破不销毁等。全部通过输出 ALL BRICK TESTS PASSED。
# 运行：godot --headless --path android scenes/blocks_test.tscn

const BS = preload("res://scripts/brick_system.gd")

func _ready() -> void:
	var failures: Array[String] = []
	var reg := BS.BlocksRegistry.new()
	var n := reg.load_from_file()
	prints("Loaded brick types:", n)

	# ---- AC-1：数据驱动，>=40 类型，行为由数据而非代码决定 ----
	if n < 40:
		failures.append("AC-1: 仅加载 %d 个类型，需要 >=40" % n)

	# ---- AC-1 / AC-2：每个实例的销毁命中数必须 == 数据推导值（证明数据驱动）----
	var behaviors_seen := {}
	for d in reg.get_all():
		behaviors_seen[d.behavior] = true
		var expected := _expected_hits(d)
		var b := BS.Block.new()
		add_child(b)
		b.setup(d)
		var hits := 0
		while b.alive and hits < 500:
			b.take_hit(1)
			hits += 1
		if expected == -1:
			if not b.alive:
				failures.append("AC-2: 类型 '%s' 应为不可破却被销毁" % d.id)
		else:
			if not b.alive:
				if hits != expected:
					failures.append("AC-2: 类型 '%s' 用了 %d 次命中销毁，期望 %d（数据与行为不一致）" % [d.id, hits, expected])
			else:
				failures.append("AC-2: 类型 '%s' 500 次命中仍未销毁，期望 %d" % [d.id, expected])
		b.queue_free()

	# ---- AC-2：5 种行为在数据表中均存在 ----
	for i in range(5):
		if not behaviors_seen.get(i, false):
			failures.append("AC-2: 数据中缺失行为 %d" % i)

	# ---- AC-3：销毁生成 FX，且 drop_letter 时生成字母拾取物 ----
	for d in reg.get_all():
		if d.behavior == BS.Behavior.UNBREAKABLE:
			continue
		var b := BS.Block.new()
		add_child(b)
		b.setup(d)
		var cnt := [0, 0]   # [fx, pickup]
		b.fx_spawned.connect(func(_fx): cnt[0] += 1)
		b.pickup_spawned.connect(func(_pu): cnt[1] += 1)
		b.take_hit(999)
		if cnt[0] == 0:
			failures.append("AC-3: 类型 '%s' 销毁却未生成 FX" % d.id)
		if d.drop_letter and cnt[1] == 0:
			failures.append("AC-3: 类型 '%s' 应掉字母却无拾取物" % d.id)
		if not d.drop_letter and cnt[1] > 0:
			failures.append("AC-3: 类型 '%s' 不应掉字母却生成了拾取物" % d.id)
		b.queue_free()

	# ---- AC-4：对照原版 Block.hx 关键不变量 ----
	# (a) 不可破（原版 life==null）永不销毁
	for d in reg.get_all():
		if d.behavior == BS.Behavior.UNBREAKABLE:
			var b := BS.Block.new(); add_child(b); b.setup(d)
			for _i in range(100):
				b.take_hit(1)
			if b.alive == false:
				failures.append("AC-4: 不可破 '%s' 被销毁，违反 Block.hx life==null 规则" % d.id)
			b.queue_free()
	# (b) 标准砖销毁掉字母（原版经 bonusTable -> newOption）
	var normal_drop := false
	for d in reg.get_all():
		if d.behavior == BS.Behavior.NORMAL and d.drop_letter:
			normal_drop = true
	if not normal_drop:
		failures.append("AC-4: 无标准砖掉字母（原版经 bonusTable 掉落）")
	# (c) 特殊砖销毁触发 special_triggered（原版 REDUC/STEEL 等 onDamage 触发）
	var special_ok := false
	for d in reg.get_all():
		if d.behavior == BS.Behavior.SPECIAL:
			var b := BS.Block.new(); add_child(b); b.setup(d)
			var fired := [false]
			b.special_triggered.connect(func(_bl, _sid): fired[0] = true)
			b.take_hit(999)
			if fired[0]:
				special_ok = true
			b.queue_free()
	if not special_ok:
		failures.append("AC-4: 特殊砖销毁未触发 special_triggered（对照原版 onDamage）")

	# ---- 报告 ----
	if failures.is_empty():
		prints("ALL BRICK TESTS PASSED")
	else:
		for f in failures:
			prints("FAIL:", f)
		prints("BRICK TESTS FAILED (%d 项)" % failures.size())
	get_tree().quit()

func _expected_hits(d) -> int:
	match d.behavior:
		BS.Behavior.UNBREAKABLE:
			return -1
		BS.Behavior.MULTISTAGE:
			var s := 0
			for v in d.stages:
				s += int(v)
			return s
		_:
			return maxi(d.hp, 1)
