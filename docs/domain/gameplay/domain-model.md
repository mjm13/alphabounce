# Gameplay 领域模型

限界上下文：Gameplay（玩法上下文）。
来源需求：`20250101130007-敌人系统`（R08，业务 / 红档）。

## 聚合与实体

- **Enemy（敌人聚合根 / BaseEnemy）**：`health` / `speed` / `behavior_name`；`hit(damage)` / `step(delta)`；`destroyed` 信号。
- **EvEnemy（事件型敌人）**：11 亚型（Dragon / Drone / Generator / Indigestion / Javelot / Ouverture / Quasar / Storm / UltraViolet / Unification / Wave），行为由 `behavior_name` 区分。
- **Molecule（飞行怪物）**：7 亚型（M1–M7），`molecule_type` / `health`；由 `Generator` / `Cage` 方块生成。
- **EnemyManager（领域服务 / Autoload 单例）**：持有 `enemies` / `molecules`，`spawn_ev` / `spawn_molecule` / `get_ev_data` / `get_molecule_data` / `set_world` / `update`。
- **Block.GUARDIAN（Boss 等价特殊方块）**：仅导弹可击杀。

## 状态枚举

| 值 | 含义 |
|---|---|
| alive | 在场（HP>0） |
| destroyed | 已消灭（HP≤0，触发掉落/信号） |

## 不变量（INV）

- **INV-001**：球碰敌人/Molecule 造成 1 点伤害（同方块），HP≤0 消灭并掉落（星星/道具）。
- **INV-002**：GUARDIAN 仅导弹可击杀，球不可击杀（见 OQ-003 / `Pad.hx:607`）。
- **INV-003**：敌/闪电/Molecule 碰玩家 → `PlayerData.lives -= 1`；`lives<=0` 触发 Game Over；敌人之间互不伤害。
- **INV-004**：Molecule 仅由 `Generator` / `Cage` 方块生成，受 `MOLECULES_MAX=6` 上限约束。

## 信号

- `destroyed(pos: Vector2)`：敌人消灭
- `dangerous_triggered(type: BlockType)`：危险方块（DRAGON / MISSILE / MINE / INSECT / KILL）击碎触发对应行为
