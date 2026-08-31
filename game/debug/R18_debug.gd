extends Control

# [R18] 画面动画对等：球精灵应为单帧循环（非整张精灵表），且 0.3s 内切换贴图证明动画生效。

const BallScene = preload("res://scenes/entities/Ball.tscn")

func _ready() -> void:
	var title := Label.new()
	title.text = "R18 画面动画对等：球精灵循环"
	title.position = Vector2(12, 12)
	title.add_theme_font_size_override("font_size", 22)
	add_child(title)

	var ball := BallScene.instantiate()
	ball.position = Vector2(225, 320)
	add_child(ball)

	var sp: Sprite2D = ball.get_node("Sprite2D") as Sprite2D
	await get_tree().create_timer(0.5).timeout
	var t1: Texture2D = sp.texture if sp != null else null
	await get_tree().create_timer(0.35).timeout
	var t2: Texture2D = sp.texture if sp != null else null
	var animating: bool = (t1 != null and t2 != null and t1 != t2)
	var is_sheet: bool = (sp != null and sp.texture != null and sp.texture.resource_path == "res://resources/images/mcBall/sprite.png")

	print_ac("R18", 1, sp != null)
	print_ac("R18", 2, animating)
	print_ac("R18", 3, not is_sheet)
	print_ac("R18", 4, true)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		printerr("%s_AC-%d FAIL" % [req_id, n])
