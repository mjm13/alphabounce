---
name: xijia-ops-pipeline
description: "Load when /xijia:start, 推进需求, 我要做, 帮我实现, 完整流程, 不要漏步骤, 不要漏 Gate."
---

# Xijia Ops Pipeline

统一编排入口：分级 → Gate-0~3 → 实现/verify → 知识回灌。与 `/xijia:start`、`xijia-feature-pipeline` 共用本技能。

## 何时使用

- 完整推进单个需求（含缺陷修复）
- 按项目标准从需求做到归档

**非本技能**：`/xijia:init`、`/xijia:adopt`、`/xijia:release`、`/xijia:prd`、`/xijia:defect`（登记）、`/xijia:overview` — 见下表。

## 项目阶段路由

| 用户意图 | 入口 |
| --- | --- |
| 冷启动 / 种子 / supplement-only | `/xijia:init` → `xijia-project-init` |
| **历史多模块接入** | `/xijia:adopt` → `xijia-project-adopt` |
| PRD→inbox（含按分档写满 Gate-1） | `/xijia:prd` → `xijia-prd-to-requirement` |
| 缺陷登记 | `/xijia:defect` → `xijia-defect-to-requirement` |
| Gate-0 部分通过补闭环 | 自然语言「细化 Gate-0」→ `xijia-requirement-refinement`（禁写 Gate-1） |
| **推进需求** | `/xijia:start` / `xijia-feature-pipeline` |
| 发布批次 | `/xijia:release` → `xijia-release` |
| 速览/回填 | `/xijia:overview` / `/xijia:backfill-index` |

对照：`docs/process/project-lifecycle.md`

## 固定约束

1. 硬门禁见 `.cursor/rules/00-workflow.mdc`（Gate-0/1/2/3、Approval Gates）
2. Gate-0 先于分级；领域草稿只写 `docs/openspec/changes/<name>/domain/`
3. DB 安全：`22-db-destructive-safety.mdc`
4. 本技能**独有增量**：A.0.5 Plan 探针、`--resolve-gate`、单回合输出契约、会话恢复

## 渐进披露（硬 pointer）

| 阶段 | 必须 Read |
| --- | --- |
| Gate-0 / 分级 / 红绿路由 | [`references/tier-routing.md`](references/tier-routing.md) |
| verify / closeout / 放弃 | [`references/verify-closeout.md`](references/verify-closeout.md) |
| 9 步收尾清单 | [`references/closeout-steps.md`](references/closeout-steps.md) |
| 活文档 / 经验复用 / DDD | [`references/living-docs.md`](references/living-docs.md) |
| 续聊 / 当前门禁 / 输出模板 | [`references/session-recovery.md`](references/session-recovery.md) |
| 多篇 inbox | [`references/multi-inbox.md`](references/multi-inbox.md) |
| Gate-0 程序细节 | [`.cursor/templates/requirements/gate0-intake.md`](../templates/requirements/gate0-intake.md) |

## 主路径速记

**绿/黄**：Gate-0（断点→refinement）→ 类型判型 → `--check-plan`（缺则 A.0.5 增量）→ Gate-1 → TDD+comment-sync → verify → Gate-2 → Gate-3 → `--check-closeout`

**红**：explore → propose → analyze → Gate-1 → superpowers-apply → verify → sync → archive → Gate-3 → closeout

每回合完成标准：

1. 跑 `--resolve-gate --req <file> --format cta`（或等价文件证据）定位当前门禁。  
   **完成：** 回复正文照贴 CTA stdout。
2. 输出 CTA 块（**请你** + **然后** mandatory；阻塞条件展开）。细节 Read [`references/session-recovery.md`](references/session-recovery.md)。  
   **完成：** 用户 3 秒内可见口令；未用长诊断压过 CTA。
3. 仅推进当前门禁；Gate-1 文字批准后同轮实现；Gate-2 签字后同轮 Gate-3。  
   **完成：** 本回合未 solicit 第二道人审。

## 自治护栏

长链任务的恢复点以 `tasks.md` 勾选状态与文件证据为准（不以会话摘要为准）。不可逆动作的停点见 `00-workflow.mdc`「Approval Gates」。

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 摘要写 Stage=实现但 Gate-1 待批 | 会话摘要不可信 | `--resolve-gate` + 文件证据；漂移恢复仅 solicit Gate-1 |
| 状态块无 **然后** 行 | 未跑 `--format cta` 或手写 CTA | 照贴 guard stdout；禁止删 **然后** |
| CTA 本步指令/请你/然后挤成一段 | Markdown 把无空行的相邻加粗行合成段落 | `--format cta` 字段间空一行；照贴勿删空行 |
| Gate-1 待批准本步指令与请你重复 | 两行都写审阅路径+批准口令 | 省略本步指令，只保留请你 |
| 状态块堆十几行、找不到口令 | 默认展开 Intake/探针/注释/质量 | CTA 优先；证据另起 `### 附录` |
| 写了 CTA 但用户看不见 | 嵌套围栏 | 直接输出 markdown，无外层 fence |
| 同回合 solicit Gate-1+Gate-2 审批 | 违反单回合契约 | **请你** 仅 1 条；**然后** 写 Agent 链 |
| Gate-1 批准后停步问「是否开始实现」 | 误把批准当检查点 | 同轮 apply/TDD；`**请你：** 无（Agent 继续）` |
| Gate-2 签字后停步问「是否执行 Gate-3」 | 误把单回合契约用于机器步骤 | 签字即授权 Gate-3；同轮 `xijia-sync-knowledge`（见 `session-recovery.md`） |
| 「磁盘消失」后 Write 重建 shipped | 跳过预检；`.cursorignore` 误导 Glob | inbox 改状态→写总结→Move；`--check-gate3-preflight`；禁止 rebuild |
| shipped Cursor Write Permission denied | shipped 在 ignore 中 | 归档仅 Move；改 shipped 用 Python（`xijia-safe-file-write` `references/shipped-write.md`） |
| Move 后才改 `状态:已交付` | 步骤颠倒 | Move **前**在 inbox 写齐状态与 Gate-3 段 |
| 跳 Gate-1 直接改代码 | 未获文字批准 | stop-and-report；AskQuestion 不算批准 |
| `--check-release` 输出当用户待办 | 聚合审计误用 | 内部判断用；对用户只报当前门禁 + 下一步命令（不全文转述） |
| 三重维护后流程不一致 | 只改 rule 未改 skill | 改流程后跑 `policy_flow_drift_check.py` |
| 代码 diff 有、验收记录全「未执行」却当 Gate-2 | 跳过 verify；误读 `Gate-2: 待验收` | `--resolve-gate`=实现；先跑 verify（前端 UI 用 `scripts/verify-frontend-parity.ps1`）并填验收记录 |
