extends Node

# [核心目的] 关卡加载器：加载关卡 JSON，按网格实例化方块到世界节点。
# [功能描述] _ready 自动加载 level_path；遍历 LevelData.blocks，用 Grid 坐标转换
# 计算世界位置并 instantiate Block.tscn（复用既有网格与方块资源）。

const BLOCK_SCENE = preload("res://scenes/entities/Block.tscn")
const GridScript = preload("res://scripts/core/grid.gd")
const LevelDataScript = preload("res://scripts/core/level_data.gd")

@export var level_path: String = "res://resources/levels/level_001.json"

# 已加载并实例化的方块节点（供测试/验收读取）
var loaded_blocks: Array = []

func _ready() -> void:
	load_level(level_path)

# 加载指定关卡并实例化方块；成功返回 true
func load_level(path: String) -> bool:
	var data = LevelDataScript.new()
	if not data.load(path):
		return false
	_spawn_blocks(data)
	return true

func _spawn_blocks(data) -> void:
	for b in data.blocks:
		var block = BLOCK_SCENE.instantiate()
		block.block_type = b["type"]
		add_child(block)
		block.position = GridScript.grid_to_world(Vector2i(b["x"], b["y"]))
		loaded_blocks.append(block)
