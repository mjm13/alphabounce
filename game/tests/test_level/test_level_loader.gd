extends TestBase

const LevelLoaderScript = preload("res://scripts/core/level_loader.gd")
const LevelDataScript = preload("res://scripts/core/level_data.gd")

# AC-3：LevelLoader 加载后 World（父节点）下出现正确数量方块
# AC-4：至少 3 个不同布局且类型混合的示例关卡 JSON
func _ready() -> void:
	var loader = LevelLoaderScript.new()
	add_child(loader)
	var ok_ac3: bool = loader.loaded_blocks.size() == 4
	var d2 = LevelDataScript.new()
	var d3 = LevelDataScript.new()
	var ok_ac4: bool = d2.load("res://resources/levels/level_002.json") and d3.load("res://resources/levels/level_003.json")
	if ok_ac4:
		ok_ac4 = ok_ac4 and d2.blocks.size() > 0 and d3.blocks.size() > 0
		ok_ac4 = ok_ac4 and _has_types(d2) and _has_types(d3)
	print_ac("R02", 3, ok_ac3)
	print_ac("R02", 4, ok_ac4)
	if get_tree().current_scene == self:
		get_tree().quit(1 if not (ok_ac3 and ok_ac4) else 0)

func _has_types(d) -> bool:
	var t := {}
	for b in d.blocks:
		t[b["type"]] = true
	return t.size() >= 2
