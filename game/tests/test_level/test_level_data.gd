extends TestBase

const LevelDataScript = preload("res://scripts/core/level_data.gd")

# AC-1：LevelData 从 JSON 正确解析关卡数据（网格宽高 + 方块列表）
func _ready() -> void:
	var data = LevelDataScript.new()
	var ok: bool = data.load("res://resources/levels/level_001.json")
	var ok_struct: bool = ok and data.grid_width > 0 and data.grid_height > 0 and data.blocks.size() > 0
	print_ac("R02", 1, ok_struct)
	if get_tree().current_scene == self:
		get_tree().quit(1 if not ok_struct else 0)
