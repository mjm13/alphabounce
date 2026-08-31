# 资产映射（R15 资产迁移）

> 源：`D:\Project\Self\EternalTwin-Alphabounce\frontend\src\static\images\`
> 目标：`res://resources/images/`
> 目的：让 Godot 实体渲染**原版精灵**，使“行为与原版一致”可被真机截图核对。

## 已迁移目录（核心玩法）

| 原版目录 | Godot 路径 | 用途 |
|---|---|---|
| mcPad/ | res://resources/images/mcPad/ | 发射台（sprite.png） |
| mcBall/ | res://resources/images/mcBall/ | 球体（sprite.png） |
| mcBlock/ | res://resources/images/mcBlock/ | 方块（01..63 + sprite.png，按类型映射待 R16 细化） |
| mcDragon/ | res://resources/images/mcDragon/ | 事件敌人 Dragon |
| mcDrone/ | res://resources/images/mcDrone/ | 事件敌人 Drone |
| mcGenerator/ | res://resources/images/mcGenerator/ | 事件敌人 Generator |
| mcJavelot/ | res://resources/images/mcJavelot/ | 事件敌人 Javelot |
| mcQuasar/ | res://resources/images/mcQuasar/ | 事件敌人 Quasar |
| mcUltraViolet/ | res://resources/images/mcUltraViolet/ | 事件敌人 UltraViolet |
| mcWave/ | res://resources/images/mcWave/ | 事件敌人 Wave |
| mcOnde/ | res://resources/images/mcOnde/ | 事件敌人 Ouverture（挤压） |
| mcProtection/ | res://resources/images/mcProtection/ | 事件敌人 Storm（护盾/闪电占位） |
| mcNut/ | res://resources/images/mcNut/ | 事件敌人 Indigestion（占位） |
| mcShape/ | res://resources/images/mcShape/ | 事件敌人 Unification（占位） |
| mcMonster/ | res://resources/images/mcMonster/ | 7 种 Molecule 飞行怪物 |
| mcMine/ mcGlue/ mcLaser/ mcVolt/ mcIce/ mcFire/ mcInsect/ mcLife/ mcStar/ mcScore/ mcShop/ mcBlink/ mcMenu/ partExplode/ fxBallPowerUp/ mcOption/ | 同名路径 | 危险方块/选项/Pad 类型/UI/特效（待 R16 细化映射） |

## 实体接图状态

- Pad：Sprite2D + mcPad/sprite.png ✅
- Ball：Sprite2D + mcBall/sprite.png ✅
- Block：按 BlockType 加载 mcBlock/0x.png（映射待 R16 细化）✅
- EvEnemy / Molecule：基类 `_setup_sprite()` 按 `sprite_path` 渲染 ✅

## 待办（R15 收尾）

- [ ] 完整类型映射：方块 30+ 种、7 种 Pad、9 种球、3 种无人机、GUARDIAN 与原版精灵精确对应（核对 `Block.hx`/`Pad.hx`/`Cs.hx`）
- [ ] 背景/关卡装饰/粒子/音效占位（R13/R18）
- [ ] 删减未被引用的多余精灵，控制包体
