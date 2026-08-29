extends TestBase

const PAD_SCENE = preload("res://scenes/entities/Pad.tscn")

# AC-3：松手后正确实例化 Ball 并从 Pad 位置沿瞄准方向发射（调用 ball.launch）
func _ready() -> void:
	var pad = PAD_SCENE.instantiate()
	add_child(pad)
	var dir := Vector2(0, -1)
	var ball = pad.launch_ball(dir)
	var ok := ball != null
	if ok:
		ok = ok and (ball.get_parent() == pad.get_parent())
		ok = ok and ball.is_launched_flag()
		ok = ok and ball.get_ball_velocity().is_equal_approx(dir * 300.0)
	print_ac("R01", 3, ok)
	if get_tree().current_scene == self:
		get_tree().quit(1 if not ok else 0)
