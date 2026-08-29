extends RefCounted

# [核心目的] 关卡数据：解析 JSON 关卡配置文件（格子矩阵 + 方块类型映射）。
# [功能描述] load(path) 读取 res:// JSON，产出 grid_width/grid_height 与 blocks 列表
# （每个 block 为 {type,x,y}，type 对应 block.gd 的 BlockType 枚举）。

var grid_width: int = 0
var grid_height: int = 0
var blocks: Array = []  # Array of {type:int, x:int, y:int}

# 加载并解析关卡 JSON；成功返回 true（并在本实例填入字段），失败返回 false
func load(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		return false
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("grid_width") or not data.has("grid_height") or not data.has("blocks"):
		return false
	grid_width = int(data["grid_width"])
	grid_height = int(data["grid_height"])
	blocks.clear()
	for b in data["blocks"]:
		if typeof(b) == TYPE_ARRAY and b.size() >= 3:
			blocks.append({"type": int(b[0]), "x": int(b[1]), "y": int(b[2])})
	return true
