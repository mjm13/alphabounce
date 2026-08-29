# 关卡网格：坐标往返与 add_child 陷阱

> 来源：R02 测试与集成中暴露的两个真实问题。

## 陷阱 1：`world_to_grid` 有损，AC-2 断言误 FAIL

`Grid.world_to_grid(v) = floor(v / GRID_SIZE)` 对像素坐标做了截断。若断言
`grid_to_world(world_to_grid(v)) == v`（v 为任意像素点，如 (100,200)），
`world_to_grid(100,200) → (3,6)`，`grid_to_world(3,6) → (112,208) ≠ (100,200)`，**必然失败**。

**正确断言**：以格子中心为基准验证可逆——
```gdscript
var cell := Vector2i(3, 6)
var center := Grid.grid_to_world(cell)   # (112, 208)
assert center.is_equal_approx(Vector2(3*32+16, 6*32+16))
assert Grid.world_to_grid(center) == cell
```

## 陷阱 2：在 `_ready` 中向正在 setup 的父节点 `add_child`

`LevelLoader._ready` 内若 `get_parent().add_child(block)`，父节点（World）正处于 `_ready`
setup 阶段，会报 `Parent node is busy setting up children, add_child() failed`。

**修复**：加到自身节点 `add_child(block)`（LevelLoader 挂在 World 下，归属等价），
并以本地坐标设置位置：`block.position = Grid.grid_to_world(Vector2i(b["x"], b["y"]))`。
