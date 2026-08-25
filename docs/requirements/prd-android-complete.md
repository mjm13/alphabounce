# AlphaBounce Android 完整重写 — PRD

> 输入：`/xijia-prd-to-requirement`
> 目标：基于当前项目现状，拆分出可在安卓上用现有技术栈（Godot 4.x / GDScript）完整重写的所有需求。
> 日期：2025-01-01

---

## 现状审计（vs PRD 口径）

| 模块 | 当前代码坐标 | 完成度 | 缺口摘要 |
|------|------------|--------|---------|
| Godot 项目壳层 | `game/project.godot`, `game/.export_presets.cfg` | ✅ 100% | 无 |
| 主菜单 UI | `game/scenes/main/Main.tscn`, `scripts/core/main_menu.gd` | ✅ 90% | 功能完整，暂无数据绑定 |
| 游戏主场景骨架 | `game/scenes/main/Game.tscn`, `scripts/core/game.gd` | 🔄 40% | HUD 节点存在但无动态绑定；导弹逻辑未实现 |
| 球体物理 | `game/scripts/entities/ball.gd`, `Ball.tscn` | 🔄 30% | 自定义速度追踪，未使用 Godot Physics2D；无碰撞回调 |
| 方块系统 | `game/scripts/entities/block.gd`, `Block.tscn` | 🔄 30% | 基础类型/击破逻辑存；无关卡网格管理、无球-块碰撞集成 |
| 发射台(Pad) | ❌ 不存在 | ⬜ 0% | 核心玩法入口，完全缺失 |
| 关卡/网格系统 | ❌ 不存在 | ⬜ 0% | 需 GridManager + LevelLoader |
| 任务系统 | ❌ 不存在 | ⬜ 0% | MissionManager + MissionInfo 数据层 |
| 商店系统 | ❌ 不存在 | ⬜ 0% | ShopManager + UI 面板 |
| 玩家存档 | ❌ 不存在 | ⬜ 0% | PlayerData + JSON 持久化 |
| 敌人系统 | ❌ 不存在 | ⬜ 0% | BaseEnemy + 子类(Dragon/Drone/Generator 等) |
| 导弹系统 | 骨架在 `game.gd` 中 | 🔄 10% | `_fire_missile()` 为 TODO |
| 音频系统 | ❌ 不存在 | ⬜ 0% | 音效 + BGM |
| 粒子特效 | ❌ 不存在 | ⬜ 0% | 消除/击中反馈 FX |
| 触摸输入映射 | `project.godot` input 段 | ✅ 80% | 基础绑定完成，虚拟按钮区域待完善 |

**综合判断**：工程基线已就绪，核心玩法（Pad→Ball→Block→Score）链路断裂于「发射台」「关卡网格」「碰撞集成」「球体物理」四个环节；完整 Android 导出还需状态机、音频、粒子、导弹等辅助系统补齐。

---

## 业务目标

将 Haxe/Pixi.js 版 AlphaBounce 完整迁移到 Godot 4.x + GDScript，支持 Android 平台一键导出 Debug APK / Release AAB，实现完整可玩单人游戏。

---

## 用户故事

1. 作为玩家，我能从屏幕底部发射台点击并拖动瞄准，松手发射球体消除方块
2. 作为玩家，球体能真实弹跳碰撞方块，方块被击碎后计分
3. 作为玩家，每个关卡有明确的目标（消除所有方块/达到指定分数），通关后进入下一关
4. 作为玩家，我能看到任务面板，完成阶段目标获得奖励物品
5. 作为玩家，我能在商店用收集到的物品兑换特殊球体或导弹
6. 作为玩家，我能看到敌人出现并躲避/消灭它们
7. 作为玩家，我的游戏进度（关卡、物品、分数）自动保存，下次打开可继续
8. 作为玩家，游戏有音效和背景音乐，方块消除和击中时有反馈特效
9. 作为玩家，游戏在 Android 设备上触控响应流畅，画面适配不同屏幕比例

---

## 需求拆分（按实现顺序）

以下共 14 个需求（含 1 个工程基线 + 13 个功能需求），按依赖关系排序。每个需求落地后产生一个 `inbox/*.md` 文件，执行 `/xijia:start` 进入 Gate 流程。

| # | 需求ID | 需求名称 | 分级 | 类型 | 依赖 | 核心交付物 |
|---|--------|---------|------|------|------|-----------|
| R00 | 20250101120000 | Godot项目初始化 | 黄 | 技术 | — | project.godot + 导出配置 + 目录结构 |
| R01 | 20250101130000 | Pad发射台系统 | 黄 | 技术+业务 | R00 | Pad.gd + Pad.tscn，触摸瞄准+发射 |
| R02 | 20250101130001 | 关卡网格与关卡数据系统 | 黄 | 技术 | R00 | LevelLoader.gd + LevelData + JSON 配置 |
| R03 | 20250101130002 | 球体物理系统完整化 | 黄 | 技术 | R01, R02 | ball.gd 重构为 CharacterBody2D + Physics2D |
| R04 | 20250101130003 | 球-块碰撞集成 | 黄 | 技术 | R03, R02 | ball body_entered → block.hit() → score |
| R05 | 20250101130004 | 任务系统 | 黄 | 混合 | R00 | MissionManager.gd + MissionPanel.tscn |
| R06 | 20250101130005 | 商店系统 | 黄 | 混合 | R00, R05 | ShopManager.gd + ShopPanel.tscn |
| R07 | 20250101130006 | 玩家存档系统 | 黄 | 技术 | R00 | PlayerData.gd(Autoload) + JSON 读写 |
| R08 | 20250101130007 | 敌人系统 | 🔴 | 业务 | R02 | BaseEnemy.gd + Dragon/Drone/Generator + EnemyManager |
| R09 | 20250101130008 | 触摸输入映射配置 | 绿-轻量 | 技术 | R00 | project.godot [input] 段 |
| R10 | 20250101130009 | 游戏循环状态机与关卡管理 | 黄 | 技术+业务 | R01~R08 | game.gd 状态机 + GameOver/LevelClear 场景 |
| R11 | 20250101130010 | 导弹系统 | 黄 | 业务 | R04, R07 | Missile.gd + 范围伤害 + HUD 集成 |
| R12 | 20250101130011 | 音频系统 | 绿 | 技术 | R00 | AudioManager.gd(Autoload) + BGM/SFX |
| R13 | 20250101130012 | 粒子特效系统 | 绿 | 技术 | R04 | FXManager.gd + GPUParticles2D |
| R14 | 20250101130013 | 完整UI层与Android导出验证 | 黄 | 混合 | R01~R13 | 主菜单存档+所有场景按钮+APK验证 |

---

## 关键决策（ADR 摘要）

- **ADR-001**：物理系统优先使用 Godot 内置 `CharacterBody2D.move_and_slide()` 而非手动速度追踪（原 ball.gd 实现），以保证与 Godot Physics2D 碰撞系统的兼容性。
- **ADR-002**：关卡数据采用 JSON 配置表（`res://resources/levels/level_001.json`），不使用内置 Tiled，避免引入外部依赖。
- **ADR-003**：玩家存档使用 Godot `UserDirectory` + JSON，单文件存储，不引入 SQLite。
- **ADR-004**：音频使用 Godot 内置 `AudioStreamPlayer`，音效与 BGM 分离，由 `AudioManager` Autoload 统一管理。

---

## 缺口分析（Gap Analysis）

以下是在初次需求拆分后发现的补充需求，已通过 `/xijia-prd-to-requirement` 二次梳理补充：

| 缺口编号 | 问题描述 | 严重程度 | 补充需求ID |
|---------|---------|---------|-----------|
| G-01 | `project.godot` 缺少 `[input]` 段，触摸动作未定义，触摸控制完全失效 | 🔴 阻塞 | R09 (20250101130008) |
| G-02 | 无游戏循环状态机，各子系统无法协同 | 🔴 阻塞 | R10 (20250101130009) |
| G-03 | 无球体回收/丢失逻辑，生命系统无法运转 | 🔴 阻塞 | R10 (20250101130009) |
| G-04 | 无关卡切换逻辑，通关后无反应 | 🟡 重要 | R10 (20250101130009) |
| G-05 | 无 Game Over 独立场景 | 🟡 重要 | R10 (20250101130009) |
| G-06 | Main Menu 无存档读写，无法继续游戏 | 🟡 重要 | R14 (20250101130013) |
| G-07 | 音频系统缺失，体验不完整 | 🟢 增强 | R12 (20250101130011) |
| G-08 | 粒子特效缺失，反馈感不足 | 🟢 增强 | R13 (20250101130012) |
| G-09 | 导弹系统未实现 | 🟡 重要 | R11 (20250101130010) |

## 验收总目标（E2E）

运行以下命令后，在 Android 设备上看不到报错且游戏可完整游玩：

```bash
godot --path game --export-debug "Android"
adb install -r game/bin/android_debug.apk
```

完整游玩路径：启动 → 主菜单「开始游戏」→ 看到关卡方块 → Pad 发射球 → 球碰撞消除方块 → 计分 → 通关 → 进入任务/商店 → 返回主菜单。
