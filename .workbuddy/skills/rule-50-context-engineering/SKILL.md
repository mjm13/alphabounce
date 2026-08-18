---
name: rule-50-context-engineering
description: "上下文工程门禁（按 BC just-in-time 加载，避免上下文污染）"
agent_created: true
---

# 目标

把信息放在正确上下文面，避免一次性塞入全量文档导致漂移与误判。

# 规则

1. 关键规则前置：约束与安全规则优先加载。
2. **默认不加载归档区**：禁止默认读取 `docs/requirements/shipped/`、`docs/openspec/changes/archive/`、`docs/archive/`；修历史 bug 或追溯 AC 时须显式 `@` 引用。
3. **默认加载白名单**：活文档（`README.md`、`AGENTS.md`、`docs/README.md`、`docs/llms.txt`、`docs/constitution.md`、`docs/architecture.md`、`docs/flow.md`、`docs/roadmap.md`、`docs/capability-map.md`、`docs/requirements/backlog.md`、`docs/domain/*`、`docs/decisions/*`、`docs/patterns/*`、`docs/pitfalls/*`）+ 当前 `docs/requirements/inbox/` 中的本需求 +（red）当前活跃 `docs/openspec/changes/<name>/`（不含 `archive/`）。
4. 领域文档按 BC 即时加载：优先 `docs/domain/<bc>/**`，禁止默认整包读取 `docs/domain/**`。
5. 仅在跨 BC 分析时补读 `docs/domain/context-map.md`。
6. 探索型任务优先使用 subagent，隔离上下文污染。
7. 长任务在 checkpoint 将关键决策沉淀到对应 requirement / ADR 文档（**默认真相源**）。
8. **`docs/memory/`（可选）**：仅当 init 启用 optional memory 模板时使用 `xijia-memory` 写 episodic 草稿；**不得**与 requirement/ADR 重复；稳定结论须经 Gate-3 提升到 `docs/decisions` / `docs/domain`（见 `xijia-sync-knowledge`）。未启用 memory 时，规则 7 已足够。
9. 经验文档复用评分（`xijia-docs-score`，默认 patterns/pitfalls/decisions）按**发版/周度**执行，非每需求；报告只列复用/修订候选，不自动删除；废弃长文移入 `docs/archive/` 并标 `deprecated`。
10. **实现前装载检查（checklist）**：已加载 capability-map 命中行 + 触达 BC 的 `docs/domain/<bc>` + **当前需求 Gate-0「约束引用」表内已列 path**；命中 cap 行时再 `@` 该行「需求来源」最近 1 条 shipped（定点，非整目录）。Gate-0 已填 path apply 前必须 Read，**禁止从技能/memory 另取未写入需求的 pattern path**。读闭环细则见 `living-docs.md`。
11. **Table-First Panel 实现（Gate-1 已批准 + 改 `frontend/src/components/*Panel.vue`）**：本规则只管**装载**——Load `xijia-table-first-panel`，Read 该需求 `## 约束引用` 已列 path 与 Gate-1「复用映射」指定的参照 Panel 全文。实现步骤与结构清单是该技能的 SSOT，本处不复制；verify 前跑 `python .cursor/hooks/pipeline_guard.py --check-ui-pattern`。

# 输出

装载情况只在**跨 BC** 或**未按 checklist 装齐**时说明，写清当前 BC、已加载/未加载及原因即可；正常装齐时不需要逐项自述。
