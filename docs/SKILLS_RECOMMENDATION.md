# 技能推荐清单（xijia-init · 仅推荐不安装）

- 技术栈：Godot 4（GDScript/C#）+ 安卓导出；纯单机，无后端/数据库
- 安装策略：仅生成推荐清单（用户选择，未实际安装任何技能）
- 候选来源：WorkBuddy 内置技能 + 已迁移 xijia 技能目录
- init 阶段硬上限：≤10 个；本次实际安装：0

## A. 通用工程能力（与栈无关，强烈推荐）

| 技能 | 评分 | 入选理由 | 来源 |
|---|---|---|---|
| systematic-debugging | 88 | 游戏物理/碰撞/游戏循环调试，条件等待与根因追踪直接可用 | 已迁移 |
| test-driven-development | 84 | GDScript/GUT 单测思路、测试反模式，保障 MVP 质量 | 已迁移 |
| verification-before-completion | 82 | Gate-2 验收证据、完成前自检，契合 xijia 门禁 | 已迁移 |
| writing-plans | 80 | 实现前方案/计划文档，Gate-1 切片基础 | 已迁移 |
| executing-plans | 76 | 计划落地执行编排 | 已迁移 |

## B. 设计 / 需求（按需启用）

| 技能 | 评分 | 入选理由 | 来源 |
|---|---|---|---|
| xijia-requirement-refinement | 85 | 需求分级与闭环澄清，走 xijia Gate-0 | 已迁移(项目) |
| xijia-prd-to-requirement | 83 | PRD 拆解为可切片需求 | 已迁移(项目) |
| brainstorming | 78 | MVP 范围/玩法梳理 | 已迁移 |

> 注：xijia 工作流技能（xijia-feature-pipeline / xijia-release / xijia-git-commit / xijia-ops-pipeline 等）已随本次迁移进入 `.workbuddy/skills/`，作为本项目流程基座，不计入"栈技能"评分。

## C. 未找到（Skipped / NotFound）

| 期望技能 | 状态 | 理由 |
|---|---|---|
| godot / gdscript | 未找到 | 当前环境内置/已迁移技能中无 Godot 专用技能 |
| android / mobile-game / godot-android-export | 未找到 | 同上 |
| frontend-design / webapp-testing | 不适用 | 面向 Web，非 Godot 客户端 |

## 结论与后续

- 本次 0 个技能实际安装（recommendation-only），符合用户选择。
- MVP 阶段建议优先启用：`systematic-debugging` + `test-driven-development` + `verification-before-completion`。
- Godot / 安卓专用技能可后续从技能市场安装（仍受 ≤10 上限约束）；届时更新本清单与 `skills-lock.json`。
