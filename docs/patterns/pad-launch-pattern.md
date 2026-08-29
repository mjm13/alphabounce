# Pad 发射模式（R01）

> 来源需求：R01 Pad发射台系统。复刻自 `frontend/src/haxe/Pad.hx`。

## 模式要点

- **固定布局**：Pad 为 `Node2D`，`_ready` 中 `position = (viewport.x/2, viewport.y - 60)`，不随关卡移动（DEF-001 待参数化评估）。
- **触摸瞄准**：`_input` 监听 `InputEventScreenTouch`/`InputEventScreenDrag`；按下 `begin_aim`、拖拽 `update_aim`、松手 `end_aim`。
- **方向量化**：`compute_aim_direction()` 纯函数——先 `normalized()`，再按 5°（OQ-001）量化，避免过于敏感。返回归一化 `Vector2`。
- **发射**：`launch_ball(dir)` 实例化 `Ball.tscn`，加入 `get_parent()`（World），`global_position = Pad.global_position`，调用 `ball.launch(dir)`。**速度由 `ball.gd` 的 `SPEED` 决定，Pad 不硬编码**（OQ-002：实际 `SPEED=300.0`）。
- **可视化**：`_draw` 用 `draw_circle` 占位色块 + 拖拽时 `draw_line` 画瞄准线（`aiming` 为真时）。

## 复用约定

- 复用 `ball.gd` 的 `launch(direction: Vector2)` 接口，不新增发射逻辑。
- 触摸事件处理模式复用 `godot-android-export` 技能（Android 真机一致）。

## 测试落地

- 组件测试：`game/tests/test_pad/test_pad_{position,aim,launch}.tscn` 各自 `extends TestBase`，断言后 `print_ac("R01", n, ok)`；`test_pad_suite.tscn` 聚合。
- 真机验收：`game/debug/R01_debug.tscn` 由 `DebugLauncher` 进入，触摸拖拽松手逐 AC 打印 `R01_AC-n`。
