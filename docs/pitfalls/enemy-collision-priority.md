# 敌人系统陷阱（R08）

- **碰撞优先级**：`EnemyManager` 的球-敌碰撞回调须优先于 `Block` 的同类回调处理，否则敌人会在方块逻辑前被错误消费（R08 AC-6 依赖此顺序）。
- **GUARDIAN 仅导弹可击杀**：`Block.GUARDIAN.hit(damage, by_missile)` 仅当 `by_missile == true` 时消灭；球（`by_missile == false`）不可击杀。对齐原版 `Pad.hx:607`（OQ-003），违反会破坏 INV-002，Boss 被球误杀。
- **Molecule 上限**：`MOLECULES_MAX = 6`，仅由 `Generator` / `Cage` 方块生成，避免飞行怪物无限堆叠（INV-004）。
