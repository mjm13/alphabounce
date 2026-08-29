extends TestBase

const GridScript = preload("res://scripts/core/grid.gd")

# AC-2：Grid 双向坐标转换正确（格子→中心→格子稳定，且中心坐标精确）
func _ready() -> void:
	var cell := Vector2i(3, 6)
	var center := GridScript.grid_to_world(cell)
	# 已知：GRID_SIZE=32，grid(3,6) -> 世界中心 (3*32+16, 6*32+16)
	var ok_forward: bool = center.is_equal_approx(Vector2(3 * 32 + 16, 6 * 32 + 16))
	# 中心反算回原格子（说明转换一致可逆）
	var ok_inverse: bool = GridScript.world_to_grid(center) == cell
	print_ac("R02", 2, ok_forward and ok_inverse)
	if get_tree().current_scene == self:
		get_tree().quit(1 if not (ok_forward and ok_inverse) else 0)
