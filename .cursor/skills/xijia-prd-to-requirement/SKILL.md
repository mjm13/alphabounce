---
name: xijia-prd-to-requirement
description: "Load when PRD转需求, 需求拆分, PRD转inbox, 把PRD拆成需求文档."
---

# xijia-prd-to-requirement

PRD → `docs/requirements/inbox/<YYYYMMDDHHMMSS>-<中文>.md`；对齐 `45-requirement-intake.mdc`；不实现代码、不输出排期。

**对齐 tysfrz**：落盘时按分档**写满 Gate-1**（无原型+UI 时 **`## 页面布局预览`** → `## 验收标准` + `## 实现方案`），不是只留空骨架。`/xijia:start` A.0.5 仅做 `--check-plan` 失败时的增量补全。

**执行契约（简单需求）**：`分级=绿` / `绿-轻量` 时，PRD 落盘的 Gate-1「实现方案」（含**可执行切片** Files/Test/Steps/Done）即 Gate-1 **批准后的唯一执行计划**——批准后按切片 TDD，禁止再开 `writing-plans` 重写或另建 `docs/plans/`。黄档允许 A.0.5 补密度；红档批准后执行真相源为 OpenSpec `tasks.md`。

## When NOT

- 推进已有 inbox 实现 → `/xijia:start`
- 仅修 Gate-0 → `xijia-requirement-refinement`
- 缺陷登记 → `/xijia:defect`

## 触发

PRD 拆分、PRD 转 inbox、贴 PRD 要求落盘。人天/甘特图 → 说明本技能不提供。

## 前置

读 `00-workflow.mdc`、`45-requirement-intake.mdc`、`.cursor/templates/requirements/requirements-template.md`。Gate-1 前仅文档变更。默认**按模块多篇**拆分。

**写任何 inbox 文件前**必须先 Read 并遵循 `xijia-safe-file-write`（直接 Write 各目标 inbox；或 `write_utf8.py`；写后 `verify_utf8.py`；禁止 Shell heredoc / 默认再造 `_gen_*.py`）。

## 渐进披露（硬 pointer）

| 内容 | 必须 Read |
| --- | --- |
| Gate-0 清单 | [`references/gate0-checklist.md`](references/gate0-checklist.md) |
| **约束引用检索规则** | [`references/constraint-discovery.md`](references/constraint-discovery.md) |
| **Gate-1 按分档** | [`.cursor/templates/requirements/gate1-by-tier.md`](../../templates/requirements/gate1-by-tier.md) |
| codegraph 探针 | [`references/codegraph-probe.md`](references/codegraph-probe.md) |
| 附录参考模板 | [`references/appendix-templates.md`](references/appendix-templates.md) |
| Gate-1 字段骨架 | [`.cursor/templates/requirements/gate1-plan-template.md`](../../templates/requirements/gate1-plan-template.md) |
| Gate-0 程序 | [`.cursor/templates/requirements/gate0-intake.md`](../../templates/requirements/gate0-intake.md) |

## 流程速记

1. **解析 PRD** → 原始诉求逐字落盘 + 歧义登记 + 能力/原型/接口种子；联动 `brainstorming`。  
   **完成：** 原始诉求 verbatim 已备；边界已确认或已列 OQ。
2. **Step 1.1/1.2**（有原型）：读原型 → 「原型现状」表 + **硬停**等口径确认。  
   **完成：** 用户已确认口径，或无原型跳过。
3. **Step 1.5**：codegraph 探针（**必须** Read `codegraph-probe.md`）→ 回填闭环表 + Gate-1 复用映射。  
   **完成：** 落点已填或已标 `[MCP不可用]`。
4. **Step 1.6**：按 [`references/constraint-discovery.md`](references/constraint-discovery.md) 检索 shipped/decisions/pitfalls/patterns/domain → `## 约束引用`（**path 落盘在需求表，技能不硬编码文件名**）；未命中写 `约束引用: none`。  
   **完成：** 约束引用行已写；引用的 path 在仓库存在；UI pattern 命中时 Gate-1 有 AC-UI-*；复用映射含参照 Panel 坐标。
5. **Step 1.7**：capability-map/context-map →「PRD现状对照」+ 冲突识别（命中写处置）。  
   **完成：** 对照段已写或标不适用。
6. **Step 2**：闭环表；**2.5** 四态缺口；**2.6** 确认卡片；**2.7** 原型落盘。  
   **完成：** 闭环断点已清或 verdict 部分通过有据。
7. **Step 3**：分级/类型；**红** → 填 `openspec变更`（kebab-case）。  
   **完成：** YAML 分级/类型/理由齐全。
8. **Step 4**：落盘前加载 `xijia-safe-file-write` → Write 各 inbox → 每篇 `verify_utf8.py`。Gate-0 写满；Gate-1 **必须**按 [`.cursor/templates/requirements/gate1-by-tier.md`](../../templates/requirements/gate1-by-tier.md) 写满。  
   - **4a**（无原型 + 数据流前端入口 ≠ `—`）：写 `## 页面布局预览`（ASCII 或「参照现有页」快捷写法；见 `.cursor/templates/requirements/gate1-plan-template.md`）。Table-First 时复用映射 **须含** `Dashboard 排除 TabId` + 参照 `*Panel.vue`；缺 Dashboard 排除时 **AskQuestion**（补 Gate-1 / 修 patterns / Deferred）。有原型 **禁止**本节。  
   - **4b**：写 `## 验收标准` + `## 实现方案`。  
   **完成：** 每篇 verify exit 0；Gate-1 非空骨架。
9. **Step 5**：每篇 **必须先** `--check-intake` **再** `--check-plan`（绿/黄/无包红期望双 guard exit 0）→ 仅双 guard 通过后 frontmatter Gate-0 才可标 `已通过` → 交接 `/xijia:start`（`--format cta`）。  
   **禁止**在本技能输出 Tier Matrix / 代码探针 / 实施切片；CTA 由 start 的 guard 生成。  
   **完成：** 两 guard exit 0；未手写 CTA。

## 章节映射（摘要）

| PRD | 需求文档 |
|---|---|
| 背景/目标 | Gate-0 `## 业务目标` |
| 用例/用户故事 | Gate-0 `## 用例 / 用户故事` |
| 范围 | Gate-0 `## 范围与切片`（能力边界，无 GWT） |
| 验收标准 / GWT | Gate-1 `## 验收标准`（**本技能落盘时写满**） |
| 方案与验证 | Gate-1 `## 实现方案`（**本技能落盘时按分档写满**） |
| 无原型 UI 页布局 | Gate-1 `## 页面布局预览`（无原型+前端入口时；有原型跳过） |
| 原型 | Gate-0 `## 原型对齐与偏离` |
| 接口/数据 | Gate-0 `## 数据流闭环表`（行名=能力简述；含前端入口/相关表列） |
| 分级/审批 | YAML properties（红必填 `openspec变更`） |

## 硬性约束

1. 不臆造；新增标 `[研发补充]`
2. 数据流闭环后才标 `已通过`
3. Deviation `approved` 后才写入 In-Scope
4. 有原型须 Step 1.2 口径确认后再 1.5/落盘
5. 触达面后须 Step 1.6；capability-map 存在时须 Step 1.7
6. 动态行为以人工文字确认为准；静态 HTML/图片只作展示参考
7. **落盘走 `xijia-safe-file-write`**：先加载再写 inbox；win32 用 Write/Python，不用 `python <<` / PS here-string
8. **验收标准至少 1 条可执行断言**（端点/写库/UI GWT）；Gate-1 须含可跑 AC，不只留标题
9. **红档**：实现方案写明 OpenSpec 变更名、目录、何时 `openspec-propose`（须有路径，勿空喊「以 OpenSpec 为准」）
10. **绿 / 绿-轻量可执行切片**：每条含 Files + Done（及宜填的 Test/Steps）；产出即批准后唯一执行计划
11. **无原型 + 前端入口**：Step 4a 须写 `## 页面布局预览`；纯后端写 `不适用（无 UI 触达）`；有原型禁止重复写预览
12. **UI验收证据**：触达 UI 时 **Gate-1 批准前不要写** frontmatter `UI验收证据`（省略该键）；批准同轮再按用户声明写入（默认组件测试）

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 多篇落盘但无原型对照表 | 跳过 Step 1.2 | 硬停；verdict 不得 已通过 |
| 伪造 codegraph 路径 | MCP 不可用未标注 | 标 `[MCP不可用]` + spike |
| 选「分批」却标 已通过 | 口径误解 | 未确认切片标部分通过；DEF 入 backlog |
| 因有 DEF 就标部分通过 | 混淆延期与待确认 | DEF≠部分通过；无待确认断点且 intake OK → 已通过 |
| 约束引用缺失 | 跳过 1.6 | 写 `约束引用: none` 或表格 |
| 约束引用幽灵 path | 未 Read README 索引 | 只写仓库存在的 path；`--check-intake` 校验存在性 |
| 约束引用无参照 Panel | 复用映射只写 list.css | Step 4b 补 `frontend/src/components/*Panel.vue` 坐标 |
| Step 2.6 首次发现 PRD↔原型差异 | 应在 1.2 完成 | 回退 1.2 重新确认 |
| 静态原型判「一致」但实现走偏 | 用 Agent 的解释对照原型，而非用原话识别歧义 | 回退 Step 1.2，登记至少两种读法并人工确认 |
| 落盘 Shell ParserError / 文件未生成 | 跳过 safe-file-write，在 PS 用 bash heredoc | 加载 `xijia-safe-file-write`；直接 Write 各 inbox + `verify_utf8.py` |
| 落盘先造 `_gen_*.py` | 误把应急绕行当推荐 | 删临时脚本；Write 目标 md |
| Gate-1 空骨架导致 check-plan fail | 误以为 A.0.5 才写 Gate-1 | 本技能按 `.cursor/templates/requirements/gate1-by-tier.md` 写满后再交接 |
| 绿档切片只有「表 + API」无 Files/Done | 当成摘要方案而非执行计划 | 按可执行切片补路径与 Done 命令后再交 `/xijia:start` |
| 批准后又写一份 plans | 未把 PRD Gate-1 当唯一计划 | 绿/绿-轻量禁止；仅 check-plan fail 才 A.0.5 增量 |
| 无原型有 UI 却缺布局预览 | 跳过 Step 4a | 补 `## 页面布局预览`（ASCII 或参照现有页+差异） |
| 批准前已写死 `UI验收证据` | PRD 默认带组件测试，跳过人工选型 | 删掉该键；等批准同轮再写入 |
| 双面包屑风险 | Gate-1 缺 Dashboard 排除 TabId | AskQuestion；复用映射补 `DashboardView` v-if 排除 |
| 重复说明 | Panel 外第二说明块 | 合并进 `PageHeadBar.description` 单行 |
| 缺分页 pager DOM | foot 仅 summary | 参照 Panel 复制 `role-panel-foot__pager` |
| 有原型又写布局预览 | 与 Step 1.2 冲突 | 删除本节；原型为视觉 SSOT |

## 失败兜底

信息不足 → 缺失清单；MCP 不可用 → 人工确认 + 风险标注；未确认过多 → 建议补 PRD。
