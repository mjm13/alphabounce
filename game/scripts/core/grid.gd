class_name Grid
extends RefCounted

# [核心目的] 网格坐标系统：在 Alphabounce 世界像素坐标与逻辑网格坐标间双向转换。
# [功能描述] 提供 world_to_grid / grid_to_world 静态方法，供物理与渲染层对齐方块/球体位置。

const GRID_SIZE := 32.0

static func world_to_grid(world_pos: Vector2) -> Vector2i:
	# [业务逻辑] 像素坐标整除网格尺寸得到网格索引。
	return Vector2i(int(world_pos.x / GRID_SIZE), int(world_pos.y / GRID_SIZE))

static func grid_to_world(grid_pos: Vector2i) -> Vector2:
	# [业务逻辑] 网格索引映射到格子中心的世界像素坐标。
	return Vector2(grid_pos.x * GRID_SIZE + GRID_SIZE * 0.5, grid_pos.y * GRID_SIZE + GRID_SIZE * 0.5)
