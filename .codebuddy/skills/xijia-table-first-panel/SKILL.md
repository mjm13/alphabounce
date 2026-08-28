---
name: xijia-table-first-panel
description: "Load when 新建/改 *Panel.vue、Table-First 列表页、约束引用含 docs/patterns/table-first-list-page"
---

# 目标

实现或重构 **Table-First 标准列表页**（`frontend/src/components/*Panel.vue`）时，以 `docs/patterns/` 为结构 SSOT，避免自创 DOM class 导致样式丢失。

# 何时加载

- Gate-1 已批准且改 `*Panel.vue`
- 当前需求 `## 约束引用` 含 `docs/patterns/table-first-list-page.md`（或 Gate-1 复用映射标注 Table-First）
- 用户要求对齐标准列表页 / 修复页眉、筛选栏、表格样式

# 硬约束

1. **结构 SSOT**：Read 需求 `## 约束引用` 已列的 patterns path；**禁止**从技能正文硬编码 Panel 路径或 patterns 文件清单（索引见 `docs/patterns/README.md`）。
2. **实现坐标**：Gate-1 复用映射 **参照 Panel** 全文 = 复制来源；结构 token = [table-first-list-page.md §结构门禁](../../../docs/patterns/table-first-list-page.md) + [table-first-list-page.guard.yaml](../../../docs/patterns/table-first-list-page.guard.yaml)。
3. **禁止自创容器 class**（如 `menu-filter-bar`）；筛选/表格/foot 须在 `menu-panel` 内。
4. verify 前：`python .codebuddy/hooks/pipeline_guard.py --check-ui-pattern` exit 0。

# 执行步骤

1. Read 当前需求 `## 约束引用` 表中 **已列** 的 `docs/patterns/*` path（从 [README.md](../../../docs/patterns/README.md) 确认，不另维护清单）。
2. Read [table-first-list-page.md](../../../docs/patterns/table-first-list-page.md)：**DOM 骨架** + **§结构门禁**。
3. Read Gate-1「复用映射」**参照 Panel** 全文（路径来自需求，非本技能）。
4. 写代码前输出 **骨架对照表**：

```text
| 项 | 要求 | 计划 |
| --- | --- | --- |
| Dashboard 排除 TabId | Gate-1 映射 | … |
| PageHeadBar 单行说明 | description only | … |
| menu-panel 卡片 | 筛选+表+foot 同容器 | … |
| 筛选栏 | menu-panel-head + role-search-field | … |
| 分页 pager | role-panel-foot__pager 整块 | … |
| Drawer | menu-overlay + menu-drawer.is-on | … |
| 禁止 token | 无 menu-filter-bar 等 | … |
```

5. 实现：foot/drawer/筛选栏从参照 Panel **复制 DOM**；仅业务列/字段差异。
6. 组件测结构断言见 [xijia-frontend-test](../xijia-frontend-test/SKILL.md) Table-First 表。
7. verify：`python .codebuddy/hooks/pipeline_guard.py --check-ui-pattern`。

# 与第三方 skill 边界

- `vue-best-practices` / `element-plus-skills`：Vue/EP API；**不**覆盖本项目 Table-First DOM 约定。
- `frontend-design`：视觉方向；**不**替代 patterns 骨架。

# 参考

- [doc-load-order.md](./references/doc-load-order.md) — 文档加载顺序
- [standard-page-checklist.md](../../../docs/patterns/standard-page-checklist.md)
