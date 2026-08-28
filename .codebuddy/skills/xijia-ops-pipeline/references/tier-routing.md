# 分级与路由（Tier / 类型 / 红绿黄）

## A.0 Gate-0

见 [`.codebuddy/templates/requirements/gate0-intake.md`](../../templates/requirements/gate0-intake.md)。

机器校验：`python .codebuddy/hooks/pipeline_guard.py --check-intake --req <file>`

**硬序（机器优先）**：

1. 任何 Gate-0 verdict（`已通过` / `部分通过` / `已驳回`）输出前 **必须先**跑 `--check-intake`
2. exit≠0 → frontmatter **不得**写「已通过」；以 exit code 为准，文档 Intake 自评仅作 hint
3. intake fail → 加载 `xijia-requirement-refinement` **仅修 Gate-0**（禁止写满 Gate-1、禁止输出 Tier Matrix / 实施切片）
4. 红档：`openspec变更` 目录缺失或已 archive → intake **硬 fail**；proposal Out of Scope 命中需求标识 → **warning**（见 guard）

**断点路由**：`部分通过` 或 `--check-intake` fail → refinement。断点闭合后再进 A.0.1 / A.0.5。

**输出**：Gate-0 通过后交接 `/xijia:start` → `--resolve-gate --format cta`（非 refinement 输出 CTA）。

## A.0.1 类型判型

Gate-0 通过后：DDD A|B|C|D → 类型判型矩阵 → frontmatter `类型`（业务|技术|混合）；已按缺陷模板登记的修复固定为 `缺陷`。详见 gate0-intake.md。

## A.0.5 Plan 探针（Gate-1 前）

> Gate-1 正文应已在 `/xijia:prd`（或缺陷落盘）按分档写满。本步为**缺口补全**，非首次起草。

```bash
python .codebuddy/hooks/pipeline_guard.py --check-plan --req <file>
```

- exit=0 → 直接提请 Gate-1 文字批准（**禁止**再跑 `writing-plans`；计划以 inbox Gate-1 为准）。
- exit≠0 或方案含 TODO/TBD → codegraph 探针 + `writing-plans` **增量** merge Gate-1（**先** `## 页面布局预览` 若缺且无原型有 UI，**再** `## 验收标准` + `## 实现方案`；骨架见 `.codebuddy/templates/requirements/gate1-plan-template.md` / 分档见 `.codebuddy/templates/requirements/gate1-by-tier.md`）→ 再提请 Gate-1。
- `green-trivial` 有步骤+验证命令可跳过完整字段（验收标准可写 `不适用（green-trivial）`）；宜含可执行切片 Files/Done。
- 🔴 且 OpenSpec change 包齐备 → 以 OpenSpec 为准跳过 requirement 内容校验。
- 🔴 但 change 目录缺失 → **同黄档**校验草案；实现方案首段须已说明 OpenSpec 变更名/目录与 `openspec-propose` 时机。

## Tier Decision Matrix

| red 触发器 | 命中 | 证据 | 置信度 |
|---|---|---|---|
| 核心业务领域变更 | ... | ... | ... |
| 复杂规则/状态机 | ... | ... | ... |
| 用户可见状态机（集合随操作增减 / 可关闭 / 可恢复的会话态） | ... | ... | ... |
| 跨限界上下文 | ... | ... | ... |

- 任一 `yes+high` → red；多个 `yes+med` → red 或 spike；全 no → green/yellow。
- 用户可见状态机命中时最低为 **yellow**，且 Gate-1 前强制执行 `brainstorming`，将操作序列、初态/末态及异常路径人工消歧；复杂领域状态机仍按 red 触发器判定。

分级：
- **green**：`/xijia:prd` 写满 Gate-1（含**可执行切片**）→ 批准后按切片执行；仅 `--check-plan` fail 才 A.0.5/`writing-plans` 增量
- **green-trivial**：声明无数据流；PRD 写简化可执行切片 + 验证命令；保留 Gate-1/2/3（**收尾走快路径**：Gate-2 人工签字后同一轮合并 sync-knowledge + `--check-closeout`，见 `closeout-steps.md` 快路径）
- **yellow**：PRD 写满 Gate-1；允许 A.0.5 补切片密度；用户可见状态机命中时 brainstorming 强制，其余场景可选
- **red**：OpenSpec 全链路；无 change 包时先按黄档写满 Gate-1；批准后执行真相源为 `tasks.md`
- **spike**：`xijia-spike-probe`，代码非交付

## A.1 green / green-trivial / yellow

1. A.0.1 类型判型 → frontmatter `分级`/`类型`
2. `--check-plan` 或 A.0.5（**仅 fail 时**增量；exit=0 **禁止**再跑 `writing-plans`）
3. Gate-1 文字批准（AskQuestion 不算）——批准对象即 inbox 内 Gate-1「**页面布局预览**（若有）」+「验收标准」+「实现方案」
3b. **批准后同轮进入实现**（硬约束）：落盘 `Gate-1: 状态:已批准` 后 **禁止** 反问「是否开始实现」；`本回合请求=无，继续执行` → 步骤 5
4. **经验读闭环（只读 Gate-0 已列路径）** → 勾选：命中路径 | 采用/规避 | 预写 `Experience Reuse:`  
   - 若 capability-map 命中行：再 `@` 该行「需求来源」最近 1 条 shipped 闭环表  
   - 细节见 [`living-docs.md`](living-docs.md)
5. **按 Gate-1「实现方案」切片执行**（绿/绿-轻量：可执行切片 Files/Test/Steps/Done 勾选推进；TDD + comment-sync）。禁止另建 `docs/plans/` / `docs/superpowers/plans/`；禁止因「还要拆任务」重开 writing-plans（除非重新跑 `--check-plan` 且 fail）
6. verify（见 verify-closeout.md）
7. Gate-2 → Gate-3 `xijia-sync-knowledge` → `--check-closeout`

**green-trivial**：禁止扩写沉淀段；模板预填 `Experience Reuse: none` + `Living Docs/Flow/Patterns/Pitfalls/Capability Index: no-op` 即可（仍保留 Gate-2 人审与 verify）。

## B. red

explore → propose → analyze → **analyze 阶段显式确认 change 名与需求 1:1** → Gate-1 → **批准即 apply**（`openspec-superpowers-apply`；缺包同轮 `openspec-propose`）→ verify → sync → Gate-2 → archive → Gate-3 → closeout

**OpenSpec 路由**（session-recovery 路由表）：

| 条件 | 当前门禁 | next action |
| --- | --- | --- |
| 红档 + openspec 包 scope/目录不匹配 | Gate-0 / OpenSpec | `openspec-propose` 新建 change + 更新 frontmatter |
| 红档 + 无包 | Gate-1 方案缺口 | 同黄档写满 Gate-1 + 注明 propose 时机 |

进入 apply 前：`python .codebuddy/hooks/pipeline_guard.py --check-apply --change <name> --tier red`

## 缺陷快路径

`/xijia:defect` → inbox；`/xijia:start` 绿档修复。Gate-0 可简化。hotfix 合入 `release/<版本>` 后回合 `master`。

## D. spike

`xijia-spike-probe` → 报告 → 用户确认 partial/重跑 Gate-0/reject → Deferred 入 backlog。

## F. 发布（批次）

Gate-3+closeout 通过后 → `/xijia:release` → `--check-release-readiness` → Release Gate → 从 `master` 切 `release/<版本>`。
