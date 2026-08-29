# CharacterBody2D 球体弹跳模式（Ball Physics）

> 来源：R03 球体物理系统完整化。替代原自定义 `position += velocity*delta` 手动积分。

## 迁移要点

- `ball.gd` 继承 `CharacterBody2D`，物理步进用 `move_and_slide()`，不再手动写位置。
- 碰撞反弹：在 `_physics_process` 中先保存 `pre := velocity`，调用 `move_and_slide()`，再用
  `get_last_slide_collision().get_normal()` 反射：`velocity = pre.bounce(normal) * RESTITUTION`。
- `RESTITUTION = 0.95` 模拟原版弹性衰减（DEF-001，后续按 R16/R17 数值微调）。
- `Ball.tscn` 的 `CollisionShape2D` 为 `CircleShape2D radius=10`，`physics_material_override` 设
  `bounce=0 / friction=0`，restitution 由代码手动处理，避免与 `move_and_slide` 双重施加。
- 边界：4 个 `StaticBody2D` + `RectangleShape2D` 薄板（或 `WorldBoundaryShape2D`）围出游戏区。

## 保留接口（契约不变）

`launch(direction)` / `get_move_velocity()` / `is_launched_flag()` / `get_type()` 签名保持兼容，
Pad（R01）与后续碰撞（R04）无需改动调用方。
