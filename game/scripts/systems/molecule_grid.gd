extends Node
class_name MoleculeGrid

## Molecule 网格管理（monsterGrid 等价）：维护网格坐标与球碰撞查询。

var grid: Dictionary = {}
var cols: int = 14
var rows: int = 23

func place(m: Node, c: int, r: int) -> void:
	grid["%d,%d" % [c, r]] = m

func remove_at(c: int, r: int) -> void:
	grid.erase("%d,%d" % [c, r])

## 返回与球位置重叠的 molecule（供 game.gd 调用 mon.damage()）
func ball_hit(pos: Vector2) -> Node:
	for key in grid:
		var m = grid[key]
		if is_instance_valid(m) and m.position.distance_to(pos) < 14.0:
			return m
	return null
