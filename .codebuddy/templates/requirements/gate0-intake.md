# Gate-0 完整性闸门（程序细节）

> Schema 契约见 `.codebuddy/rules/45-requirement-intake.mdc`；编排见 `xijia-ops-pipeline` A.0。

## 完整性维度

1. **数据流闭环**：来源 → 加工 → 去向；任一段空/占位/`[待确认]` 即未闭环。`green-trivial` 可声明 `本需求无数据流（green-trivial）`。
2. **原型对齐**：有原型须 Step 1.2 对照表 + 口径确认；Deviation `open` 不得 `已通过`。静态 HTML/图片仅能证明外观与布局，**不得**用于确认交互时序、状态生成规则或集合增减语义；这些动态行为必须列入歧义登记并由用户文字确认。
3. **范围边界闭环（Gate-0）**：`## 范围与切片` 的 In/Out/DEF/OQ 边界清晰；In Scope 只写能力边界，**不写**细 GWT。可执行验收（AC-* + 反例 + GWT）在 Gate-1 `## 验收标准`（由 `/xijia:prd` 按分档写满；`--check-plan` 校验；见 `gate1-plan-template.md` / `gate1-by-tier.md`）。Gate-0 须有 `## 业务目标` 与 `## 用例 / 用户故事`（业务/混合非空；技术/缺陷可写不适用）。
4. **未描述细节与多义表述**：用户/PRD 原话须逐字保留。多义片段列出至少两种读法，统一标 `[待确认]` 并在 Gate-1 前由用户文字确认；不得由 Agent 以 `[假设]` 自行选定后放行。确认后记录证据、确认人和日期；确无歧义则写 `歧义登记: none（已逐句复核，触达面：…）`。
5. **约束引用（主动检索 top-N，能力B）**：不止被动扫目录——按 **模块/BC/关键词** 主动检索 `docs/requirements/shipped/` + `docs/decisions/` + `docs/pitfalls/` + `docs/patterns/` + `docs/domain/`，产出 **top-N 相关历史清单**（相关需求/决策/坑 + 匹配依据 + 关联点）呈现给人，并填入需求 `## 约束引用`；未命中写 `约束引用: none（已检索，触达面：模块|BC|关键词）`——**业务/混合禁止无触达面的空 none**（intake 弱校验）。列出的 `docs/patterns|pitfalls/*.md` 在 apply/Gate-3 须进入 `Experience Reuse:`（禁止再写 none）。Gate-0 不执行 `score_docs`（读闭环以 Experience Reuse 行；Gate-3 再 `--judge-doc`）。
6. **与现有系统冲突（能力D，warning 起步）**：对照 `docs/capability-map.md` / `docs/domain/<bc>` 不变量 / `docs/decisions/*`，识别新需求是否**违反已交付能力/领域不变量/既有决策**；结论就近填入 Gate-0「约束引用/冲突识别」。命中冲突**不硬停**（避免 domain 未建全时误报/依赖倒置），但须写**显式处置结论**（改需求 / 提 Deviation Ticket / 建 ADR / 判定无冲突）。业务/混合需求缺处置结论 → `--check-intake` 弱校验 warning。待 domain/capability 成熟后，再评估将特定高危冲突升级为 stop-and-report。

## 范围边界 / Must-Confirm / Deferred

- **Out of Scope**：仅记录原本可能被合理纳入但本期明确排除的内容；每条写排除原因与重开触发，替代重复的 Non-Goals。

- **Must-Confirm**：`OQ-<nn>：<问题> → 结论：…`（需求内唯一，不嵌需求号；时间戳文件名已是主键）；任一未确认（含 `[待确认]`）则 `verdict` 不得 `已通过`，应标 `部分通过`。
- **Deferred**：`DEF-<nn>` 写入 backlog（兼容旧 `DEF-<需求号>-<nn>`）。**DEF 仅表示本期明确排除/延期，不触发「部分通过」**；有 DEF 但歧义/闭环/OQ 均已确认时，可标 `已通过`。

## 判定

| Gate-0 状态 | 条件 |
| --- | --- |
| `待确认` | 新建，尚未 intake（仅写状态，无审批人/日期） |
| `部分通过` | **歧义登记 / 数据流闭环表 / Open Questions** 中仍有待确认或未闭环；**须**写审批人/日期 |
| `已通过` | 上述三节无待确认断点 + `--check-intake` OK + 用户文字终认；**须**写审批人/日期 |
| `已驳回` | intake 失败或用户驳回；**须**写审批人/日期 |

> **禁止**：因存在 `DEF-*` 就标 `部分通过`。DEF 与「待确认断点」无关。

## 二次确认回环（不得一次放行）

1. 产出闭环表 + 断点，`stop-and-report`；frontmatter 可标 `部分通过`。
2. 用户补充后**重建并复核**闭环表；指引用户关注歧义登记 / 闭环表 / OQ 中的待确认项。
3. 全部 `已确认` 后请用户闭环终认（DEF 可保留，不阻塞）。
4. `--check-intake` 通过后方可分级；用户文字终认后将 Gate-0 写为 `状态:已通过；审批人:<git user.name>；YYYY-MM-DD`。

## Intake Score（0-100）

四维各 0–25：数据流 / 原型 / 范围边界 / 业务目标与用例。`>=80` 且无待确认断点 → 可标 `已通过`；存在待确认断点 → `部分通过`；`<50` 或硬失败 → `已驳回`。可执行验收密度在 Gate-1 `--check-plan` 另计，不阻塞 Gate-0。

## 类型判型（Gate-0 通过后）

与 Tier 分离。须 DDD 轻量版 A|B|C|D + 类型判型矩阵（见原 45-intake）。`类型=技术` 仅当 DDD=D 且无 platform BC 管理面。

`类型=缺陷` 走缺陷模板：保留复现步骤与期望行为；明确声明「缺陷修复无新增数据流」时可跳过闭环表，否则仍按逐 AC 闭环。

## 机器校验

```bash
python .codebuddy/hooks/pipeline_guard.py --check-intake --req docs/requirements/inbox/<file>.md
```

## 输出模板

```text
Gate-0 完整性判定：
- verdict: 已通过|部分通过|已驳回
- intake_score: <0-100>
- 数据流闭环表：...
- 二次确认状态：第一轮 | 复核完成 | 用户终认
- 可落地范围 / Deferred：...
```

## Deviation Ticket

```text
Deviation Ticket:
- id: DEV-<yyyyMMdd>-<nn>
- 差异点 / 风险评估 / 审批状态：open|approved|rejected
```
