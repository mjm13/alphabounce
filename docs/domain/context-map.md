# 限界上下文映射（Context Map）

> 维护说明：每完成一个业务/混合需求（Gate-3），在此追加其限界上下文条目并标注 `Domain: updated <日期>`。

Domain: updated 2026-08-30

| 限界上下文 | 职责 | 相邻上下文 | 关系 |
|---|---|---|---|
| Progression（任务/进度子域） | 任务配置、条件检查、状态机、任务面板 UI | Shop（奖励发放 R06）、Content（R16 任务源搬运） | 消费已有 `level_complete` 信号；仅记录奖励，不发放（发放由 R06 消费） |
| Gameplay（玩法上下文） | 物理/方块/敌人/任务/商店/存档协同；敌人生命周期、Molecule 网格、GUARDIAN 跟踪 | Physics（R03 球-敌碰撞）、Block（R04 危险方块触发）、Mission（R05）、Shop（R06 奖励）、Save（R07 生命） | 敌人归入 Gameplay；`EnemyManager` 为领域服务（Autoload）协调 ev 敌人 / Molecule / GUARDIAN；INV-001..004 沿用 R04 碰撞与 R07 生命字段 |
