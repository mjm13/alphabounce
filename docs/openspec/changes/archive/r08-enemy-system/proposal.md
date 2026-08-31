# Change: r08-enemy-system（全量敌人系统）

> 对标原版 AlphaBounce 全部敌人：11 种 ev 事件敌人 + 7 种 Molecule 飞行怪物 + GUARDIAN(Boss 等价) + 危险方块触发链。

## Why

R08 是核心玩法需求。原版「不做全部 11 种敌人 / 不做 Boss 战」的降级式 Out of Scope 已废除（见需求分级理由 `G-xx`/决策注记），须全量实现以达成「全部实现即等于原版」的验收基线。

## What Changes

- 新增 `BaseEnemy` 基类（`game/scripts/entities/enemy/base_enemy.gd`）：health / speed / 状态机 / 球碰撞。
- 新增 `EnemyManager`（Autoload）：事件敌人生命周期、Molecule 网格管理、GUARDIAN 跟踪。
- 新增 `MoleculeGrid`：Molecule 与球的网格碰撞（`monsterGrid` 等价）。
- 实现 11 种 ev 敌人（Dragon/Drone/Generator/Indigestion/Javelot/Ouverture/Quasar/Storm/UltraViolet/Unification/Wave），行为对齐 `frontend/src/haxe/ev/*.hx`。
- 实现 7 种 Molecule 亚型，由 Generator/Cage 生成，球碰 `mon.damage()`。
- 实现 `Block.GUARDIAN` 特殊方块（仅导弹可击杀，`Pad.hx:607`）。
- 危险方块触发链（DRAGON/MISSILE/MINE/INSECT/KILL）。
- 碰撞与伤害框架（球碰扣血掉落、敌/闪电/Molecule 碰玩家减 life、`lives<=0` Game Over）。

## Impact

- Gameplay 上下文新增 Enemy 领域服务（`EnemyManager`），复用 R04 碰撞回调模式与 R07 `PlayerData.lives` 字段。
- 不修改物理引擎；禁止 mock 物理（遵循 BASE-1/ADR-001）。
- 依赖 R16 敌方数据，未就绪时由 `fixtures/enemy_demo.json` 解耦（mock 基线）。

## Out of Scope

- 敌人 AI 难度曲线（首期固定行为对齐原版）。
- 新增敌人类型（超出原版范围，除非用户后续要求）。
