# 关卡 JSON 加载模式（Level JSON Loading）

> 来源：R02 关卡网格与关卡数据系统。坐标转换复用 `game/scripts/core/grid.gd`。

## 数据结构（JSON）

```json
{
  "grid_width": 12,
  "grid_height": 16,
  "blocks": [
    { "type": 0, "x": 0, "y": 0 },
    { "type": 2, "x": 5, "y": 3 }
  ]
}
```

- `type` 对应 `block.gd` 的 `BlockType` 枚举（NORMAL=0 / STEEL=1 / BONUS=2 / EXPLOSIVE=3）。
- `x`/`y` 为网格坐标（列、行），非像素坐标。

## 解析链

`LevelData.load(path)` → `FileAccess` + `JSON.parse_string` → 校验字段 → 暴露 `grid_width/grid_height/blocks`。
`LevelLoader`（Game/World 子节点）在 `_ready` 中 `load_level()`：遍历 `blocks`，`preload("res://scenes/entities/Block.tscn").instantiate()` 后，用 `Grid.grid_to_world(Vector2i(x,y))` 设本地坐标，`add_child(block)` 到自身（非 World，避免 `_ready` 期间父节点 busy）。

## 约定

- 关卡数据纯 JSON，与代码解耦；数值平衡走 DEF-001 后续。
- 新关卡只需新增 `resources/levels/level_XXX.json`，无需改代码。
