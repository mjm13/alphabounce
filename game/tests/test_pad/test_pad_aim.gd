extends TestBase

const PAD_SCENE = preload("res://scenes/entities/Pad.tscn")

# AC-2：触摸拖动计算正确归一化瞄准方向
# AC-4：拖拽过程中 aiming 标记成立（驱动瞄准线绘制）
func _ready() -> void:
	var pad = PAD_SCENE.instantiate()
	add_child(pad)
	# 模拟从底部向上拖拽（400,540）->（400,340）
	pad.begin_aim(Vector2(400, 540))
	pad.update_aim(Vector2(400, 340))
	var dir: Vector2 = pad.aim_direction
	var ok_dir: bool = dir.is_equal_approx(Vector2(0, -1)) and dir.is_normalized()
	var ok_aiming: bool = pad.aiming == true
	print_ac("R01", 2, ok_dir)
	print_ac("R01", 4, ok_aiming)
	if get_tree().current_scene == self:
		get_tree().quit(1 if (not ok_dir or not ok_aiming) else 0)
