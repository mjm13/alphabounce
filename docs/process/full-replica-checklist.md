# 全量复刻验收清单（Full Replica Checklist）

> 活文档；由 **P16**（`20260820140200-AB-P16全量复刻验收基线.md`）维护。
> **执行时机**：P12 打包发布前；依赖 P0–P15 + P8b 全部 Gate-2 完成。
> 对照：`document/复刻计划.md` §2–§3、`docs/reference/alphabounce-facts.md`。

## 使用方式

1. 每行在对应需求 **Gate-2 签字** 后填 `pass` + 证据链接/命令。
2. P16 Gate-2 时本表须**全绿**（或显式 Deferred 并回写 backlog）。
3. 一键回归：见 `tools/run_all_tests.sh`（待 P16 实现时汇总）。

## 内容全量矩阵

| 维度 | 全量指标 | 负责需求 | 状态 | 证据 |
| --- | --- | --- | --- | --- |
| 工程基座 | Godot 4 安卓导出 + headless 校验 | P0 | pass | shipped 20260818205718 |
| 核心玩法 | 球/挡板/碰撞/单关可玩 | P1 | pass | shipped 20260818214301 |
| 砖块 | ≥40 型行为 + 主游戏集成 + **≥40 种 mcBlock 贴图** | P2 | pass | shipped 20260818214302；`blocks_test.tscn` |
| 球 | **9** 种 + 同屏 **18** 上限 | P3 | — | — |
| 球体粒子 | 火/冰/电/醉飞行粒子 | P10 | — | AC-4；自 P3 Deferred |
| SAUVETAGE | 首球落底保护 + 标题 | P3c | — | `20260820150300` |
| 挡板/船体 | **7** 种 Pad 类型（装备） | P3, P8b | — | — |
| 增益 | **25** Bonus + **7** Malus + **7** P-Bonus | P4 | — | — |
| 导弹/无人机 | 含 Provision 补弹规则 | P5, P8b | — | — |
| 敌人/危险 | 敌人砖 + 危险物 | P6 | — | — |
| 关卡生成 | `Random.hx` 逐位一致 + initProba 全表 | P7 | — | — |
| 世界地图 | **27** 星球 + Sonar + Earth 结局 | P7 | — | — |
| lander | 地表 Hero/mineral/house 环 | P7b | — | — |
| 经济 | 全 Shop 条目可购买 | P8 | — | — |
| envelope | **28** 种全解锁链 | P8, P8b | — | — |
| 装备 | 全 catalog + Defense + 唯一分配 | P8b | — | — |
| 舰队 | 3–4 槽 + 替补出场 | P8b | — | — |
| 难度 | Easy/Normal/Hard + HILAN-DR | P14 | — | — |
| UI/i18n | **en/zh/de/es/fr** | P9 | — | — |
| 音频 | 关键 SFX + BGM | P10 | — | — |
| 存档 | Codec 版本迁移 | P11 | — | — |
| 发布 | APK/AAB + ≥60fps + 许可说明 | P12 | — | — |

## §3 总体验收（复刻计划）

对照 `document/复刻计划.md` §3「总体验收标准」六项：

| # | 验收项 | 状态 | 证据 |
| --- | --- | --- | --- |
| 1 | 核心打砖块手感与物理 | — | P1 + 手感回归 |
| 2 | 砖块类型与特殊行为 | pass | P2 |
| 3 | 增益/减益/P-Bonus 完整 | — | P4 |
| 4 | 关卡程序生成 + 世界地图推进 | — | P7 |
| 5 | 经济/商店/舰队/envelope/装备 | — | P8 + P8b |
| 6 | UI/i18n/音频/存档/安卓发布 | — | P9–P12 |

## 真机完整流程（P16 AC-4）

新游戏 Easy → 地图推进 → lander 采 mineral → 商店/loadout → Hard 解锁 → Earth 结局

- 状态：—
- 录屏/步骤日志：—

## 修订记录

| 日期 | 说明 |
| --- | --- |
| 2026-08-20 | P2 pass；P0/P1 已 pass |
