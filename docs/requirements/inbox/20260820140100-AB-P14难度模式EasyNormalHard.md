---
标题: AB-P14 难度模式（Easy/Normal/Hard）
状态: 待处理
负责人: meijianming
创建时间: 2026-08-20
分级: 黄
类型: 技术
openspec变更:
分级理由: 全量复刻缺口；原作三档难度影响星球排布与 Hard 专属奖励，无单独 Phase 认领
类型判型结论: 技术；全局 GameMode + P7 地图生成参数 + P8 envelope 解锁链
DDD主类: D
Gate-0: 状态:已通过；审批人:meijianming；2026-08-20
Gate-1: 状态:待批准；审批人:<git user.name>；2026-08-20
Gate-2: 状态:待验收；审批人:<git user.name>；2026-08-20
---

# AB-P14 难度模式（Easy/Normal/Hard）

> **全量复刻追加（2026-08-20）**：`docs/reference/alphabounce-facts.md` §1 三档难度 + Hard 专属 **HILAN-DR** envelope。

# Gate-0 澄清与范围

## 原始诉求（verbatim，禁止改写）

> 全量复刻：Easy / Normal / Hard 三档难度；通关 Easy+Normal 解锁 Hard；Hard 专属 envelope 奖励。

## 歧义登记

歧义登记: none（触达面：难度模式；确认人:meijianming；日期:2026-08-20）

## 业务目标

不适用（类型=技术）

## 用例 / 用户故事

不适用（类型=技术）

## 范围与切片

> 背景：依赖 P7（世界地图生成/星球排布）、P8/P8b（HILAN-DR envelope 解锁与 loadout）。

### In Scope（本期交付）

- **三档模式**：Easy / Normal / Hard 全局选择（新游戏/继续时）
- **星球排布差异**：同坐标星球在不同难度下地图位置/可达顺序不同（对照 facts §1 Asmech 示例）
- **解锁链**：通关 Easy **且** Normal 后解锁 Hard 模式可选
- **Hard 奖励**：Hard 通关链解锁 envelope **HILAN-DR**（写入 `envelopes.json`，P8b loadout 可装备）
- **难度注入 P7**：`LevelGen` / `WorldMap` 读取 `GameMode`，影响 `initProba` 权重或星球图生成 seed 偏移（对照源码 `ZoneInfo`/地图生成）
- **存档字段**：当前难度、Easy/Normal 完成标记、Hard 解锁标记（P11 落盘）

### Out of Scope

- 难度选择 UI 美术 → P9
- 非 Hard 的 27 envelope 解锁规则 → P8（本需求只改难度维度的地图/奖励）

### 待确认问题与延期项（Open Questions & Deferred）

**Must-Confirm**

- OQ-001：Hard 下 `Level.hx` 参数是否有独立分支 → 结论：[待确认，对照 `docs/reference/haxe/` 地图/Zone 相关常量]
- OQ-002：HILAN-DR 的 P-Bonus 与 Defense 数值 → 结论：[待确认，对照攻略 envelope #28 + 源码]

**Deferred**

- 无（全量复刻本需求不裁剪）

## 约束引用

| 约束 | 来源 | 说明 |
|---|---|---|
| 事实 §1 | `docs/reference/alphabounce-facts.md` | 三档、Hard 解锁、HILAN-DR |
| 地图 | `docs/reference/haxe/navi/Map.hx` | 难度与星球布局 |
| envelope | P8/P8b `envelopes.json` | HILAN-DR 条目 |

## 数据流闭环表

| 能力 | 来源 | 加工 | 去向 | 闭环 |
|---|---|---|---|---|
| 选难度 | 主菜单(P9) | `GameMode.set` | P7/P14 生成 | 已确认 |
| 解锁 Hard | Easy+Normal 通关 | `DifficultyProgress` | UI 可选 Hard | 已确认 |
| HILAN-DR | Hard 通关奖励 | `EnvelopeRegistry.unlock` | P8b 舰队 | 已确认 |

# Gate-1 方案与验收

## 验收标准

- [ ] **AC-1**：三档可切换（受解锁规则约束）；存档重进保留
- [ ] **AC-2**：Easy 与 Normal 下同一星球在地图上的相对排布不同（可测 seed/布局 hash）
- [ ] **AC-3**：Easy+Normal 全通后 Hard 可选；未完成时 Hard 不可选
- [ ] **AC-4**：Hard 通关链解锁 HILAN-DR，可在 P8b loadout 装备
- [ ] **AC-5**：难度影响 P7 关卡生成参数（同坐标 wx,wy 在不同难度下 proba/ymax 可区分）

## 实现方案

- 落点：`android/systems/game_mode.gd`、`android/systems/difficulty_progress.gd`；扩展 `WorldMap.gd` / `LevelGen.gd`
- 测试：`android/scenes/difficulty_test.tscn`

# Gate-2 验收

## 验收记录

| AC | 结论 | 验证方式 | 结果摘要 |
|---|---|---|---|
| AC-1..5 | 通过/未过 | difficulty_test | — |

# Gate-3 沉淀

## 实现记录与沉淀

- Experience Reuse: none
- Capability Index: no-op
- Living Docs: updated | no-op
- Flow: updated | no-op
- Patterns: no-op
- Pitfalls: no-op
