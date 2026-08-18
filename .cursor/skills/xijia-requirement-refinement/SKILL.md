---
name: xijia-requirement-refinement
description: "Load when 细化需求, Gate-0 复核, 补全 OQ, 部分通过补闭环. Gate-0 only."
---

# xijia-requirement-refinement

## 目标

在**不改动代码**的前提下，把 `部分通过` / 口径冲突的已有需求文档的 **Gate-0** 讨论清楚并回写，使 `--check-intake` 通过。

**本技能不写满 Gate-1。** 验收标准 / 实现方案由 `/xijia:prd` 或 `/xijia:start` A.0.5 负责。

与 `xijia-prd-to-requirement` 区别：后者从 PRD **新建**；本技能在已有 inbox 上**只修 Gate-0**。

## 触发判定

- 用户指定 inbox 文件并要求细化 / 补 OQ（Gate-0）
- `verdict: 部分通过`（歧义/闭环/OQ 待确认）；**仅有 DEF 不算部分通过**
- `/xijia:start` 时 `--check-intake` 失败

**不触发：** Gate-0 已通过、仅缺 Gate-1 密度 → A.0.5 + `writing-plans`。

## 硬约束

1. 先读并遵循 `brainstorming`（一次一问、2～3 方案、批准后落盘）。
2. Gate-1 前勿改代码/迁移/依赖/配置。
3. 默认更新原 requirement；回写前加载 `xijia-safe-file-write`。
4. 勿破坏 guard 结构：闭环表、YAML Gate、`DEF-*` / `OQ-*`。
5. 结论写入 Must-Confirm / Gate-0 范围与领域；勿在本技能写满 Gate-1。
6. 轻量路径：断点 ≤2 且无架构争议 → 可缩短方案对比，仍须用户确认后落盘。

## 渐进披露（硬 pointer）

| 主题 | 必须 Read |
| --- | --- |
| Phase 0–3 闭环细节 + Re-eval 模板 | [`references/gate0-closed-loop.md`](references/gate0-closed-loop.md) |
| Gate-0 程序字段 | [`.cursor/templates/requirements/gate0-intake.md`](../../templates/requirements/gate0-intake.md) |
| Gate-1 布局预览片段（供 prd/A.0.5 引用；**本技能不写**） | [`.cursor/templates/requirements/section-fragments.md`](../../templates/requirements/section-fragments.md) § Gate-1 / 页面布局预览 |

## 主路径

1. **必须** Read [`references/gate0-closed-loop.md`](references/gate0-closed-loop.md)，执行 Phase 0。  
   **完成：** Re-eval 摘要已输出。
2. 按 closed-loop Phase 1 对话（先 brainstorming）。  
   **完成：** 当前断点已获用户答复。
3. 用户批准后按 Phase 2 回写 Gate-0（safe-file-write）。  
   **完成：** `verify_utf8.py` exit 0。
4. Phase 3：`--check-intake` exit 0 后交接 `/xijia:start`（`--format cta`）。  
   **完成：** intake exit 0；**禁止**本技能输出 Tier Matrix / Gate-1 批准 CTA（由 start guard 生成）。

## 原型表自动化（intake fail 且 reason=原型表）

1. 读取原型 HTML（修正路径 typo：`document/demo/` vs `页面DEMO/`）
2. 生成「原型现状（相对 PRD）」三列表草稿（维度 | PRD 描述 | 原型实际 | 结论）
3. 用户确认口径 → 回写 → 重跑 `--check-intake`

## 与 brainstorming 分工

| 阶段 | brainstorming | 本技能 |
| --- | --- | --- |
| 对话 | 一次一问、方案对比 | 问题围绕 Gate-0 文档缺口 |
| 产出 | 默认 superpowers spec | 回写 Gate-0 + Re-eval |
| 终止 | — | intake OK → `/xijia:start` |

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 跳过 brainstorming | 硬约束 | 先 brainstorming 再 Phase 0 |
| OQ 未闭合标已通过 | Gate-0 违规 | `--check-intake` 拦截 |
| 本技能写满 Gate-1 | 职责越界 | 停手；交接 prd / A.0.5 |
| AskQuestion 当 Gate-1 | 批准无效 | 须用户文字批准（由 start 提请） |
