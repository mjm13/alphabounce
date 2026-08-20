extends Node2D

# P3 球系统自测：9 型 / MAX_BALL=18 / Multiball 分布 / Pad 7 型 / 全失。
const BS = preload("res://scripts/ball_system.gd")
const BallScript := preload("res://objects/Ball.gd")
const PadScript := preload("res://objects/Pad.gd")

func _ready() -> void:
	var failures: Array[String] = []
	var ball_reg := BS.BallsRegistry.new()
	var pad_reg := BS.PadsRegistry.new()
	var bn := ball_reg.load_from_file()
	var pn := pad_reg.load_from_file()
	prints("Loaded ball types:", bn)
	prints("Loaded pad types:", pn)

	if bn != 9:
		failures.append("AC-1: 期望 9 种球，实际 %d" % bn)
	if pn != 7:
		failures.append("AC-2: 期望 7 种 Pad，实际 %d" % pn)

	var kinds_seen := {}
	for d in ball_reg.get_all():
		kinds_seen[d.kind] = true
	for i in range(9):
		if not kinds_seen.get(i, false):
			failures.append("AC-1: 缺失球 kind %d" % i)

	var pad_kinds := {}
	for p in pad_reg.get_all():
		pad_kinds[p.kind] = p
	for i in range(7):
		if not pad_kinds.has(i):
			failures.append("AC-2: 缺失 Pad kind %d" % i)

	var pad := PadScript.new()
	pad.setup_from_def(pad_kinds[BS.PadKind.GLUE])
	if not pad.is_glue_pad():
		failures.append("AC-2: GLUE pad 未设置 glue 标志")
	pad.setup_from_def(pad_kinds[BS.PadKind.LASER])
	if not pad.has_laser():
		failures.append("AC-2: LASER pad 未设置 laser 标志")

	var mgr := BS.BallManager.new()
	mgr.setup(self, 24.0, BallScript)
	var std: BS.BallDef = ball_reg.find_by_kind(BS.BallKind.STANDARD)
	for i in BS.MAX_BALL:
		var b = mgr.spawn(std, Vector2(100 + i, 100), Vector2(0, -1))
		if b == null and i < BS.MAX_BALL:
			failures.append("AC-1: 第 %d 球 spawn 失败（应成功至 18）" % (i + 1))
	var extra = mgr.spawn(std, Vector2(50, 50), Vector2(0, -1))
	if extra != null:
		failures.append("AC-1: 第 19 球应被拒绝")
	if mgr.count() != BS.MAX_BALL:
		failures.append("AC-1: 期望 %d 球，实际 %d" % [BS.MAX_BALL, mgr.count()])

	mgr.clear_all()
	if not mgr.is_empty():
		failures.append("AC-4: clear_all 后应为空")

	var spawned := mgr.spawn_multiball(3, Vector2(400, 300), Vector2(0.2, -1), std)
	if spawned != 3:
		failures.append("AC-3: Multiball 应生成 3 球，实际 %d" % spawned)
	var xs: Array = []
	for b in mgr.balls:
		if is_instance_valid(b):
			xs.append(b.global_position.x)
	if xs.size() >= 2:
		var has_left := false
		var has_right := false
		var cx := 400.0
		for x in xs:
			if x < cx - 5.0:
				has_left = true
			if x > cx + 5.0:
				has_right = true
		if not has_left or not has_right:
			failures.append("AC-3: Multiball 未左右分布 (xs=%s)" % str(xs))

	mgr.clear_all()
	var b1 = mgr.spawn(std, Vector2(200, 200), Vector2(1, 0))
	var b2 = mgr.spawn(std, Vector2(200 + 10, 200), Vector2(-1, 0))
	if b1 != null and b2 != null:
		for _f in range(30):
			b1._physics_process(1.0 / 60.0)
			b2._physics_process(1.0 / 60.0)
		var dist: float = b1.global_position.distance_to(b2.global_position)
		if dist < 12.0:
			failures.append("AC-5: 多球重叠未分离 dist=%.1f" % dist)
	mgr.clear_all()

	var lost_ref: Array = [false]
	mgr.all_balls_lost.connect(func(): lost_ref[0] = true)
	var sb = mgr.spawn(std, Vector2(100, 100), Vector2(0, -1))
	if sb == null:
		failures.append("AC-4: spawn 失败")
	else:
		mgr.remove_ball(sb)
	if not lost_ref[0]:
		failures.append("AC-4: 全失未触发 all_balls_lost")

	if failures.is_empty():
		prints("ALL BALL TESTS PASSED")
	else:
		for f in failures:
			prints("FAIL:", f)
		prints("BALL TESTS FAILED (%d)" % failures.size())
	get_tree().quit()
