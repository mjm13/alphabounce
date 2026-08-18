---
name: rule-31-table-first-panel
description: "Table-First *Panel.vue 实现门禁（结构 SSOT 见 docs/patterns/） [globs:- frontend/src/components/*Panel.vue]"
agent_created: true
---

# Table-First Panel

改 `frontend/src/components/*Panel.vue` 且 Gate-1 约束引用含 Table-First pattern 时：

1. **Load** `xijia-table-first-panel` 技能
2. **结构 SSOT**：当前需求 `## 约束引用` 已列的 `docs/patterns/*` path（索引见 `docs/patterns/README.md`）；机器清单见 `table-first-list-page.guard.yaml`
3. **禁止**自创未在 `list.css` / pattern §结构门禁 登记的容器 class（如 `menu-filter-bar`）
4. verify：`python .cursor/hooks/pipeline_guard.py --check-ui-pattern`

实现坐标（参照 Panel 路径）**只**来自 Gate-1 复用映射，不在本规则硬编码。
