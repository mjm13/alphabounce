extends Control

# [R15] 资产迁移（精灵）：核对核心精灵资源已就绪且可加载（球/方块/敌人/发射台）。

func _ready() -> void:
	var title := Label.new()
	title.text = "R15 资产迁移：精灵资源核对"
	title.position = Vector2(12, 12)
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)

	var ball_ok := true
	for i in range(1, 11):
		if not ResourceLoader.exists("res://resources/images/mcBall/%02d.png" % i):
			ball_ok = false
	var block_ok := true
	for i in range(1, 11):
		if not ResourceLoader.exists("res://resources/images/mcBlock/%02d.png" % i):
			block_ok = false
	var enemy_real := ["mcDrone/sprite.png", "mcGlue/sprite.png", "mcInsect/sprite.png",
		"mcOnde/sprite.png", "mcProtection/sprite.png", "mcUltraViolet/sprite.png",
		"mcShape/sprite.png", "mcLife/sprite.png"]
	var enemy_ok := true
	for p in enemy_real:
		if not ResourceLoader.exists("res://resources/images/" + p):
			enemy_ok = false
	var pad_ok := ResourceLoader.exists("res://resources/images/mcPad/sprite.png")

	print_ac("R15", 1, ball_ok)
	print_ac("R15", 2, block_ok)
	print_ac("R15", 3, enemy_ok)
	print_ac("R15", 4, pad_ok)
	print_ac("R15", 5, ball_ok and block_ok and enemy_ok and pad_ok)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
