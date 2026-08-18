# Table-First Panel 文档加载顺序

> path 真相源：当前需求 `## 约束引用` 表 + Gate-1 复用映射。本文件只描述顺序，不维护 path 清单。

1. [docs/patterns/README.md](../../../docs/patterns/README.md) — 确认约束引用 path 存在且用途匹配
2. 需求 `## 约束引用` 已列的 patterns 文档（通常含 `table-first-list-page.md`）
3. [table-first-list-page.guard.yaml](../../../docs/patterns/table-first-list-page.guard.yaml) — 结构 token（guard 对齐）
4. Gate-1「复用映射」**参照 Panel** 源码全文 — DOM 复制坐标
5. [frontend-butter-shell.md](../../../docs/patterns/frontend-butter-shell.md) — Dashboard `page-toolbar` 互斥（若 Gate-1 含 Dashboard 排除 TabId）
