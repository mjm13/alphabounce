# Spec Delta — r08-enemy-system

## 验收标准（对齐需求 AC-1..AC-7）

- AC-1：BaseEnemy + EnemyManager + MoleculeGrid 可实例化并管理生命周期。
- AC-2：11 种 ev 敌人全部实现，行为对齐 `ev/*.hx`。
- AC-3：7 种 Molecule 全部实现，由 Generator/Cage 生成，球碰 `mon.damage()` 生效。
- AC-4：GUARDIAN 仅导弹可击杀，球不可；击杀后关卡可通。
- AC-5：危险方块触发链（DRAGON/MISSILE/MINE/INSECT/KILL）击碎触发对应行为。
- AC-6：球碰敌人/Molecule 扣血消灭掉落；敌/闪电/Molecule 碰玩家减 life，`lives<=0` Game Over。
- AC-7：真机 android-debug 闭环——含全量敌人的关卡，敌人出现且行为与原版一致（截图 + logcat 零 ERROR）。

## 设计约束

- 架构：`CharacterBody2D`/`Area2D` 替代 Haxe Sprite 手动移动，行为等价。
- 碰撞层：`layer=8(enemy)`，`mask=5(ball+boundary)`（OQ-001）。
- 伤害：球碰造成 1 点伤害（OQ-002）；GUARDIAN 仅导弹（OQ-003）。
- 复用：R04 `block.hit()` 模式、`R07` `PlayerData.lives`；数据来自 R16 `enemies.json`（未就绪用 `fixtures/enemy_demo.json`）。
