# Pad 触摸 Ghost Touch 坑（R01）

> 来源需求：R01 Pad发射台系统；验收类型含 Android USB 真机。

## 现象

Android 设备（尤其低成本屏 / 多点触控固件）在松手瞬间可能上报**多余的 `InputEventScreenTouch`（pressed=false）** 或坐标抖动的 `ScreenDrag`，称为 Ghost Touch。若 Pad 直接以「松手事件」触发发射，会出现：

- 未真正松手就发射（误触一次抬起事件）；
- 单次拖拽被拆成多次 begin/end，连发多球。

## 缓解

- `end_aim()` 仅在 `aiming == true` 时生效，重复松手事件因 `aiming` 已置 false 而被忽略（天然去抖）。
- 拖拽中若 `drag_vector == Vector2.ZERO` 则 `compute_aim_direction` 返回 `Vector2.ZERO`，`launch_ball` 对零向量返回 `null`，避免零方向发射。
- 真机验收时如仍出现连发，应在 `begin_aim` 增加最小按下时长 / 位移阈值（后续 ADR 评估，当前不在 R01 范围）。

## 关联

- 验收入口：`game/debug/R01_debug.tscn`；真机步骤见需求文档 §真机独立验收。
