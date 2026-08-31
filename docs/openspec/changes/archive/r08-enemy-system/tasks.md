# Tasks — r08-enemy-system

- [ ] T1 框架：BaseEnemy + EnemyManager + MoleculeGrid 可实例化与生命周期管理（AC-1）
- [ ] T2 11 种 ev 敌人行为实现（Dragon 横扫/KillZone、Drone 变形、Generator 周期生成、Indigestion 填满、Javelot 激光、Ouverture 挤压+震屏、Quasar 吸入、Storm 闪电锁 Pad、UltraViolet 射线、Unification 变 Bonus、Wave 扫描）（AC-2）
- [ ] T3 7 种 Molecule 亚型 + Generator/Cage 生成 + 球碰 `mon.damage()`（AC-3）
- [ ] T4 GUARDIAN 特殊方块，仅导弹可击杀，击杀后对应星球关卡可通（AC-4）
- [ ] T5 危险方块触发链（DRAGON/MISSILE/MINE/INSECT/KILL）击碎触发对应行为（AC-5）
- [ ] T6 碰撞与伤害框架（球碰敌人/Molecule 扣血消灭掉落；敌/闪电/Molecule 碰玩家减 life；`lives<=0` Game Over）（AC-6）
- [ ] T7 真机验收：R08_enemy_debug 场景 + 逐 AC 自检打印 `R08_AC-n PASS` + 零 Godot ERROR 截图（AC-7）
