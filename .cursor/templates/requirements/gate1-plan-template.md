# Gate-1 方案与验收（字段骨架）

> **首次写入**：`/xijia:prd`（或缺陷落盘）按分档写满——见 `.cursor/templates/requirements/gate1-by-tier.md`。  
> **增量补全**：仅当 `--check-plan` fail 时由 A.0.5 + `writing-plans` merge。  
> `refinement` / Gate-0 回补 **禁止**写满本节。  
> 参考密度：tysfrz `051-预置查询导出语句`。  
> Gate-1 H2 顺序：**页面布局预览**（无原型+UI 时）→ **验收标准** → **实现方案**。

## 页面布局预览

> **触发**：Gate-0 `## 原型对齐与偏离` 为「无原型对照」（或无附件路径），且数据流「前端入口」≠ `—`。  
> **豁免**：有原型且 Step 1.2 已完成 → **禁止**本节；纯后端 / `类型=技术|缺陷` 且无 UI → 写 `不适用（无 UI 触达）`。  
> **与 brainstorming**：ASCII 预览用于 Gate-1 落盘共识；**不替代** brainstorming 浏览器 wireframe（Gate-0 方案对比）。禁止在 requirement md 内嵌 HTML/Mermaid。  
> **红档 OpenSpec**：本节留在 inbox Gate-1 供批准；`design.md` 可引用，**不以 OpenSpec 替代** inbox 布局预览。

````markdown
## 页面布局预览
> 无原型 + 有前端入口时必填。Toolbar = Panel 内 `menu-page-toolbar` + `PageHeadBar`；Dashboard 外层 `page-toolbar` 对该 Tab **关闭**（见 Gate-1 复用映射 `Dashboard 排除 TabId`）。

路由: `/w/system-roles`  |  menuKey: `system-roles`  |  pattern: Table-First 分页平表 + Drawer
Dashboard 排除 TabId: `system-roles`

```text
路由: /w/system-roles  |  pattern: Table-First 分页平表 + Drawer

┌ Sidebar ────────┬─ Worktabs: [仪表盘] [系统角色*] ─────────────────────┐
│ · 仪表盘        │ PageFrame（Dashboard page-toolbar 已关闭）               │
│ · 系统管理 ▾    │ ┌ menu-page-toolbar + PageHeadBar ───────────────────┐ │
│   · 系统角色    │ │ 面包屑 · 单行说明                    [+ 新增]        │ │
│                 │ ├ Filter ──────────────────────────────────────────────┤ │
│                 │ │ [关键词____] [查询] [重置]                           │ │
│                 │ ├ Table (v-loading) ───────────────────────────────────┤ │
│                 │ │ □ │ 列A      │ 列B      │ 状态   │ 操作             │ │
│                 │ └──────────────────────────────────────────────────────┘ │
│                 │ 分页: 显示 1–10 共 N 条  [10/页▼]  [< 1 2 3 >]           │
└─────────────────┴──────────────────────────────────────────────────────────┘
                          ┌ Drawer (新建/编辑) ──────┐
                          │ 标题 / 说明        [×]   │
                          │ [表单字段区]             │
                          │ [保存]  [取消]  (删除)   │
                          └──────────────────────────┘
```

| 区域 | 主要控件/行为 | 对应 AC（复杂页推荐） |
|---|---|---|
| Toolbar | [+ 新增] | AC-UI-1 |
| Drawer | 表单保存 | AC-UI-2 |

布局待确认：none | `[待确认] 指向歧义登记 OQ-xxx`
````

**参照现有页快捷写法**（PRD/约束引用已明确骨架同某 Panel/View 且差异 ≤3 点时可用，**须列参照 Panel 路径 + 差异**）：

```markdown
## 页面布局预览
参照 Panel：`frontend/src/components/AuthTemplatePanel.vue`（Table-First 分页平表 + Drawer）
Dashboard 排除 TabId: `<tab-id>`
差异：① … ② …
```

**多路由**：单篇含多个前端入口时，用 `### /w/xxx` 分块各一幅 ASCII（或主页面 + 从属区说明）。

**变体**（按需裁剪，勿臆造 PRD 未声明区域）：

| 变体 | 要点 |
| --- | --- |
| 只读列表 | 无 `[+ 新增]`、无 Drawer；行操作「详情」或纯展示 |
| Master-Detail | 上/左类型 Table + 下/右数据 Table（字典） |
| 页顶卡片 | Toolbar 上方卡片区；**说明仍合并进 PageHeadBar.description**，禁止 toolbar 内第二说明块 |
| 树表 | 无分页脚；一次拉树 + 前端筛选 |

规则：

1. 元信息须含路由 / menuKey（可取自数据流「前端入口」）与 pattern 变体名。
2. 主 ASCII ≤35 行；超出用区域说明表或「参照现有页」缩写。
3. 禁止臆造 PRD / In Scope 未声明的区域或控件；布局歧义标 `[待确认]` 并链 Gate-0 歧义登记。
4. Gate-1 批准前用户布局异议：仅改本节 + 联动 `AC-UI-*`；**不回退** Gate-0（除非影响 In Scope）。
5. **禁止**只写「同 XX」无任何差异说明。
6. Table-First CRUD 布局预览须覆盖 **完整分页脚**（summary + `[< 1 2 3 >]` / 每页条数）与 **Drawer 打开态**；具体 DOM/class 以需求「约束引用」已列 pattern 与参照 Panel 为准。
7. Table-First + `PageHeadBar` 时，元信息或复用映射 **必填** `Dashboard 排除 TabId`；缺失须在 Gate-1 批准前 **AskQuestion** 确认处置（补映射 / 修 patterns / Deferred）。

## 验收标准

```markdown
## 验收标准
> 绿/黄/无 OpenSpec 包红档必填；红且有 OpenSpec 包可写：摘要 + 链 `docs/openspec/changes/<name>/specs/`。
> `green-trivial` 可写：`不适用（green-trivial）`。
- [ ] 覆盖要求：每条 In-Scope 能力至少 正常/空/错误/无权限；≥1 条可执行断言
- [ ] **AC-1**：GIVEN <初态> WHEN <操作> THEN <末态>
  - **反例（本 AC 排除）**：<看似实现但应判失败的行为>
- [ ] **AC-2**：…
  - **反例（本 AC 排除）**：…
- [ ] **AC-UI-1**（约束引用含 UI pattern 时必填）：GIVEN … WHEN … THEN …
  - **反例（本 AC 排除）**：…
```

规则：

1. Gate-1 `## 验收标准` 是**可执行验收真相源**；Gate-0 In Scope 只声明能力边界。
2. 每条 In-Scope 能力 ≥1 条 `AC-*`；有 UI/状态交互时至少一条完整 GWT（初态≠末态）。
3. 每条 AC 必须附「反例（本 AC 排除）」；写不出反例即无区分力。
4. Gate-2 验收记录 AC 列只引用本节编号（`AC-1`、`AC-UI-1`…）。
5. **三态勾选**（进度真相源；Cursor/GitHub 预览可能不渲染半选样式，以 `[~]` 文本为准）：

   | Markdown | 语义 | 何时写入 | 谁改 |
   | --- | --- | --- | --- |
   | `- [ ] **AC-*`** | **未检** | Gate-1 批准时默认；或无自动化证据、尚未人工验 | 初始 / 未覆盖 |
   | `- [~] **AC-*`** | **半选（程序已检）** | verify 后：对应测试/命令 exit 0，证据已写入「验收记录」 | Agent（verify 阶段） |
   | `- [x] **AC-*`** | **全选（人工已验收）** | Gate-2 签字后 | Agent（Gate-2 同轮）或验收人 |

   - **禁止**在 Gate-2 未签字时将 AC 标为 `[x]`。
   - 无自动化覆盖的 AC（如纯视觉 hover）：verify 阶段保持 `[ ]`；Gate-2 人工确认后直接 `[x]`（可跳过 `[~]`）。
   - 半选 `[~]` 须在「验收记录」找到对应 AC 的自动化证据；否则不得标半选。

## UI 验收证据约定

> **触发**：Gate-1 待批准且触达 UI（含 `AC-UI-*`、实现方案指向 `frontend/src/`、或数据流「前端入口」≠ `—`）。  
> **CTA**：`--format cta` 在待批准且触达 UI 时须含「UI 验收证据」提醒与批准口令（默认组件测试；可选 Playwright / 集成测试）。  
> **Agent**：可用 `AskQuestion` 补充询问是否升级档位；用户未确认升级则默认 **组件测试**（Vitest）。  
> **落盘**：Gate-1 **批准前不要写** `UI验收证据`；批准同轮写入 frontmatter `UI验收证据: 组件测试|Playwright|集成测试`，并与实现方案切片 `Done` 命令一致。

| 档位 | verify 主证据 | 验收记录须含 |
| --- | --- | --- |
| 组件测试（默认） | Vitest 组件测 | 「组件测试」或 `frontend/tests/` 路径 + 命令结果 |
| Playwright | `webapp-testing` / e2e | `Playwright` / `webapp-testing` / `frontend/e2e` |
| 集成测试 | 全栈联调 | `集成` / `parity` / `with_server` / `verify-frontend` |

纯后端 / `green-trivial` 无 UI：不写 `UI验收证据`。

## 实现方案

```markdown
## 实现方案
> 绿/黄必填完整。红档：首段说明 OpenSpec 变更名/目录/建包时机（见 gate1-by-tier.md）；无包时同黄档写满草案。
> **禁止**空洞占位：「红档以 OpenSpec 产物为准（黄档无）」且无路径。

- 架构 / 关键改动：…
- 涉及技术点：…
- 复用映射 / 代码落点：

  | 已有模块/服务 | 可复用接口/函数/表 | 关系类型 | 精确坐标 |
  |---|---|---|---|
  | … | … | 直接调用 / 扩展 / 新建 | `backend/...` 或 `frontend/...` |

- 影响面与回归范围：
  - 受影响共享模块/入口：…
  - 回归验证点：…
- 切片拆解：
  > **绿 / 绿-轻量（可执行切片）**：每条须含 Files / Test / Steps / Done；批准后按此执行，勿只写能力一句话。  
  > **黄**：允许摘要级 `[AC-*] …`，缺口由 A.0.5 补可执行密度。  
  > **红（无包草案）**：同黄；有包后以实现 `tasks.md` 为准。
  1. [AC-1]
     - Files: `backend/app/...` ; Test: `backend/tests/...`
     - Steps: 红测 → 最小实现 → 绿测
     - Done: `cd backend && pytest tests/... -q` 通过
  2. [AC-2]
     - Files: `...` ; Test: `...`
     - Steps: 红测 → 最小实现 → 绿测
     - Done: `...`
  3. [AC-UI-1]
     - Files: `frontend/src/...`
     - Test: Playwright 场景或组件测路径
     - Steps: 失败断言 → 实现 → 复跑
     - Done: <可执行前端/浏览器验证命令>
- 交互语义：布局见上方 `## 页面布局预览`（若有）。`<用户操作>` → `<状态变化>`；不适用时写原因
- 回归验证点：
  - `cd backend && pytest <paths> -q`
  - `cd frontend && npm run build`
- 关键权衡 / ADR：无 | 链 ADR
```

规则：

1. 必须含「复用映射 / 代码落点」「切片拆解」（≥1 条编号项或 AC 映射表）「回归验证点」（可执行命令）。
2. 切片项用 `[AC-*]` 映射 Gate-1 验收标准。
3. **绿 / 绿-轻量**：切片须为可执行切片（Files + Done 必填；Test/Steps 宜填）；禁止仅有「表 + API」类摘要而无路径与完成命令。
4. 禁止 `TODO` / `TBD` / `待填充` / `<...>` 占位（模板示例角括号除外；落盘正文不得保留）。
5. 绿 / 绿-轻量：本节即批准后唯一执行计划；禁止另写 `docs/plans/` 或 `docs/superpowers/plans/`。
