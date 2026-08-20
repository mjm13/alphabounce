# Step 1.6 约束引用检索规则

> **原则**：本文件与技能只写 **检索规则**；具体 `docs/patterns/*.md` 路径写入需求 `## 约束引用` 表，不在流程中硬编码文件名。

## 输入

从 Gate-0 提取 **触达面关键词**：

- 数据流闭环表「前端入口」列（路由 / menuKey）
- `## 范围与切片` In Scope 能力简述
- UI 形态关键词：列表 / Drawer / 壳层 / Table-First / EP 边界 / 分页 / CRUD 等

## 检索步骤

1. **Read** [`docs/patterns/README.md`](../../../../docs/patterns/README.md) 索引（不维护技能内 path 清单）。
2. **Read** [`.cursor/templates/requirements/gate0-intake.md`](../../../templates/requirements/gate0-intake.md) §约束引用维度 5。
3. 按触达面 **主动检索**：
   - `docs/patterns/`
   - `docs/pitfalls/`
   - `docs/decisions/`
   - `docs/domain/`
   - `docs/requirements/shipped/` top-N 相关历史
4. 结合 Step 1.5 codegraph 探针，确定 **参照 Panel** 源码路径。

## 输出（写入需求）

`## 约束引用` 表：

| 相关项 | 匹配依据与关联点 | 本需求处置 |
|---|---|---|
| `docs/patterns/<file>.md` | 触达面命中理由 | 复用 / 规避 / 无关 |

- 未命中：`约束引用: none（已检索，触达面：模块|BC|关键词）`（业务/混合须非空触达面）。
- UI pattern 命中 → Gate-1 `## 验收标准` 衍生 `AC-UI-*`（见 `45-requirement-intake.mdc`）。
- Gate-1「复用映射」**须含** ≥1 行 **参照 Panel**（如 `frontend/src/components/AuthTemplatePanel.vue`），禁止只写「复用 list.css」无坐标。
- Table-First / 新 Panel Tab：复用映射 **还须含** `Dashboard 排除 TabId: <id>`（对应 `DashboardView.vue` `page-toolbar` v-if 排除）。
- UI pattern 命中 → Gate-1 `## 验收标准` 须有 `AC-UI-*`（见 `45-requirement-intake.mdc`）。

## 禁止

- 在 SKILL / guard / rules 正文中写「SSOT: Read `docs/patterns/…`」或维护与 README 重复的「必读三件套」path 列表（path 只写入需求 `约束引用` 表）。
- 约束引用写了 pattern 但实现方案无参照 Panel 路径。
- 引用仓库中不存在的 path（`--check-intake` 会 blocking）。
