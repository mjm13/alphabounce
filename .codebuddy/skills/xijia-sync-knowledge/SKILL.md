---
name: xijia-sync-knowledge
description: "Load when Gate-2 signed, 知识回灌, Gate-3, domain/ADR sync after requirement shipped. All tiers mandatory."
depends:
  - xijia-docs-score
---

# 目标

将本次需求稳定结论回灌到长期文档；范围由 YAML `分级` 决定。所有档位（绿/绿-轻量/黄/红）收尾都要执行。回灌支持动态更新（update/supersede/rename），须先 diff 再写。

# 输入

- `分级`：`绿 | 绿-轻量 | 黄 | 红`
- 需求路径（`docs/requirements/**`）
- （红）change 名（`docs/openspec/changes/<name>/`）

# 按分级执行范围

| 步骤 | green/green-trivial/yellow | red |
|---|---|---|
| 读取 change 产物 | 跳过 | 执行 |
| OpenSpec domain→`docs/domain/<bc>/*` **提升** + DDD 校验 | 跳过 | 执行 |
| 沉淀四问 / context-map / **BC 目录直写** / 活文档 / capability-map | 执行（见下） | 执行 |
| inbox→shipped + closeout | 执行 | 执行 |

**黄/绿 domain 口径（勿与「仅红提升」混淆）：**

- 「仅 red」**只**指：从 `openspec/changes/<name>/domain/*` **提升**到 `docs/domain/<bc>/*` 并跑 validate。
- **非红没有提升草稿 ≠ 禁止写 `docs/domain/<bc>/`**。黄/绿业务|混合按 domain-merge **直写**已发布契约（README 已允许）。
- `类型=业务|混合` 且非 green-trivial、`DDD主类=A|B`（或未填主类）：Gate-3 **必须**写 `Domain:` 标记，并更新 `docs/domain/context-map.md`（或 `Domain: no-op` + 不适用理由）。不得用 `Living Docs: AGENTS.md` 顶替 Domain。
- **领域影响含 `INV-xxx`（非「无新 INV」）**：必须创建或更新 `docs/domain/<bc>/domain-model.md`（目录不存在则**首次建夹**）；ADR 只承载权衡叙事，**不得**以 ADR 或仅 context-map 代替 INV 真相源。
- **仅关系/BC 登记、显式无新 INV**：可只更新 `context-map.md`。
- **新术语 / 同词异义**：同步 `docs/domain/<bc>/ubiquitous-language.md`（首缺则建）。

# 渐进披露（硬 pointer）

| 阶段 | 必须 Read |
| --- | --- |
| 步骤 5–13（domain / 四问 / ADR） | [`references/domain-merge.md`](references/domain-merge.md) |
| 步骤 14–20（活文档 / 归档 / closeout） | [`references/gate3-archive.md`](references/gate3-archive.md) |

# 执行步骤（主路径）

**触发条件（硬约束）**：当 requirement `Gate-2:` 已验收且文件仍在 `docs/requirements/inbox/` 时，本技能为 **mandatory 续链**，非用户二次口令；Agent 不得反问「是否归档」。patterns B 类「须人确认」**不构成** Gate-2 后停轮理由——可先跑 trigger-report、预填沉淀候选，Move 前完成确认或标「跳过」。

0. **Gate-3 触发表（硬停，先于写沉淀）**  
   ```bash
   python .codebuddy/hooks/pipeline_guard.py --gate3-trigger-report --req docs/requirements/inbox/<file>.md
   ```  
   - 在会话输出 **「Gate-3 沉淀候选（须人确认）」**（强制/建议/no-op 三档；B 类 patterns/pitfalls **停等用户确认**后再写盘）。  
   - 在 inbox 需求正文预填 **`### 沉淀候选（Gate-3）`** 表格（类型|目标|动作|人确认：待确认/已确认/跳过）。  
   **完成：** 触发表已跑；B 类已确认或显式跳过；表格已写入 inbox（Move 前）。

1. 读取需求，确认变更结论与验收记录。  
   **完成：** 需求路径可读，Gate-2 已验收。
2. 校验 YAML Gate-0/1/2 审批可追溯（通过态须状态/审批人/日期；审批人 = git user.name）。  
   **完成：** 三门禁通过态字段齐全。
3. 从「实现记录与沉淀（Gate-3）」提取 Experience Reuse 清单（`docs/patterns|pitfalls/*`）。约束引用已列经验文档时写路径（可多路径；已读未采用亦列并 `--judge`）；仅当未列且未复用时写 `Experience Reuse: none（已检索，触达面：…）`。  
   **完成：** Experience Reuse 行已写且与约束引用一致。
4. 提炼新增经验：patterns/pitfalls 用「触发条件 + 结论/规避 + 来源需求号」。业务/混合（非 green-trivial）须写 `Patterns:` / `Pitfalls:` / `Living Docs:` / `Flow:` / `Capability Index:`（路径、`updated` 或 `no-op`）。已改对应活文档时对应标记写 `updated`/路径（closeout 兜底）。Table-First / 新 Panel 类 UI 经验 **优先写入 `docs/patterns/*`**（B 类须人确认），确保下轮 `constraint-discovery` 可检索并在需求 `约束引用` 复用；**禁止**用「改实现技能 GOTCHAS 堆 DOM 长文」代替 patterns。流程类 pitfall 可更新 gotchas-index，不把 patterns 正文搬进技能。AI 提议 + 人工确认后才沉淀。  
   **完成：** 沉淀标记齐全；待确认项已列出或已确认。
5. **必须** Read [`references/domain-merge.md`](references/domain-merge.md) 并执行步骤 5–13。  
   **完成：** domain-merge 内各步完成标准均满足（或按 tier 合法跳过）。
6. **必须** Read [`references/gate3-archive.md`](references/gate3-archive.md) 并执行步骤 14–20（含 17.5 预检、18/18b Move 前合并、closeout）。  
   **完成：** `--check-closeout` 与 `--check-doc-anchors` exit 0；已提示用户 commit。

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 栈变更写 `Living Docs: no-op` | reversal 禁止 no-op | 同步 README/AGENTS/architecture/openspec |
| 已改 pattern/cap 仍写 no-op | false no-op | 改为 `updated`/路径 |
| 约束引用有 pattern 却写 Experience Reuse: none | 读闭环逃逸 | 写 `Experience Reuse: <path>` |
| capability-map blind append | 未 dry-run | 先 `extract_capability_index.py --dry-run` |
| pitfall 未反哺技能 | 飞轮断裂 | 流程类 pitfall 更新 gotchas-index；**UI DOM 经验写 docs/patterns** |
| Table-First UI 缺陷只改技能不写 patterns | 下需求无法约束引用复用 | B 类确认后更新 `docs/patterns/*`；对照参照 Panel + guard |
| 公共封装只改代码不写 pattern | Gate-1 未列文档切片；触发表无共享层规则 | 看 B 类共享层建议（`app/common/`、`composables/`）后确认或显式跳过；确认则按 `async-job-progress.md` 结构写 `docs/patterns/` |
| patterns 更新后下需求检索不到 | README 索引未同步 | 更新 `docs/patterns/README.md`；Experience Reuse 与约束引用一致 |
| patterns 与源码/guard 不一致 | 沉淀过时 | 以参照 Panel + guard 为准 **改 patterns**，非复制进 SKILL |
| 业务 closeout 被 experience-distill 阻断 | 标记不全 | 写齐 Patterns/Pitfalls/Living Docs/Flow/Domain |
| 黄+混合+A\|B 只写 AGENTS | 误读「仅 red 写 domain」 | 更新 context-map + `Domain: updated` |
| 有 INV 却只有 context-map、无 `domain/<bc>/` | 误读「黄档不强制 domain-model」 | 首次建夹并写 domain-model；Domain 行带上该路径 |
| 跳过 --gate3-trigger-report 直接写 no-op | 无 Agent 触发表 | 步骤 0 硬停；preflight/resolve-gate 会提醒 |
| Patterns 指 ADR 不写 docs/patterns | 落点混淆 | B 类须人确认后写 pattern；ADR 只承载权衡 |
| INV 只写在 ADR | 四问落点错位 | ADR 留权衡；INV 进 `domain/<bc>/domain-model.md` |
| inbox 未移 shipped | 未走归档 | gate3-archive 步骤 18 |
| 「磁盘消失」后 rebuild shipped | 跳过预检 | 17.5 `Test-Path` / `--check-gate3-preflight` |
| shipped Write Permission denied | `.cursorignore` | inbox 改齐→Move；改 shipped 用 Python |
| Task 全量写 shipped | improvisation | stop-and-report |
| Gate-2 签字后停轮追问「是否归档」 | 违反同轮链式 | CTA：**请你：无（Agent 继续）**；B 类 patterns 先 trigger 预填，Move 前确认或跳过 |
| closeout 后再改 cap | 18b 过晚 | 18b 挂 18.3，Move 前 |
| 未确认术语写 domain | 违反停审 | stop-and-report |
| untracked cap/flow 写 no-op | false-noop | `updated（修订记录；…）` + safe-file-write |
| PS 改 shipped 后乱码 | 编码/换行 | Write/Python + `verify_utf8.py` |
| `updated（…no-op）` 仍判 no-op | 说明含 `no-op` 子串 | 见 safe-file-write 标记模板 |

# 约束

- 所有档位强制执行本技能。
- **仅 red** 且可提升时做 OpenSpec→`docs/domain/<bc>/*` **契约提升**；黄/绿业务|混合仍须按 domain-merge 8–13 维护 context-map，并在有 INV/术语时**直写** `docs/domain/<bc>/`。
- 过程文档收尾后离场（见 `50-context-engineering.mdc`）。
- 回灌优先增量；新术语/BC/INV 须用户确认。
