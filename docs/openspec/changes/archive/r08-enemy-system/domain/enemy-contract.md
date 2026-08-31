# DDD 契约 — Enemy（Gameplay 上下文）

## 限界上下文（BC）

Enemy 归入 **Gameplay 玩法上下文**（与 Physics / Block / Mission / Shop / Save 同一 BC，不新增 BC 划分）。`EnemyManager` 为该上下文内领域服务（Autoload），协调事件敌人生命周期、`MoleculeGrid` 与 `GUARDIAN` 跟踪。

## 领域术语

- `ev`：事件型敌人（继承原版 `Event`，由 `Game.events` 驱动 update）。
- `Molecule`：飞行怪物，由 `Generator`/`Cage` 生成，经 `monsterGrid` 与球碰撞。
- `GUARDIAN`：`Block` 特殊类型（编号 55），Boss 等价威胁，仅导弹可击杀。
- Dragon/Drone/Generator/...：均为 `ev` 子类型，非独立 BC。

## 不变量（INV）

- INV-001：球碰敌人/Molecule 造成 1 点伤害（同方块）；HP≤0 消灭并掉落（星星/道具）。
- INV-002：GUARDIAN 仅导弹可击杀，球不可击杀（OQ-003）。
- INV-003：敌/闪电/Molecule 碰玩家 → `PlayerData.lives -= 1`；`lives<=0` 触发 Game Over；敌人之间互不伤害。
- INV-004：Molecule 仅由 `Generator`/`Cage` 生成，受 `MOLECULES_MAX=6` 上限约束。

## 依赖契约

- 下游：`R11` 导弹系统（GUARDIAN 击杀）、`R07` 存档（lives）、`R04` 碰撞模式。
- 数据：`R16` `enemies.json`（未就绪用 `game/debug/fixtures/enemy_demo.json`）。
