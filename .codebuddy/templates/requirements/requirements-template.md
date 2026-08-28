---
标题: {{requirement_title}}
状态: 待处理
负责人: {{author}}
创建时间: {{date}}
分级: 绿 | 绿-轻量 | 黄 | 红
类型: 业务 | 技术 | 混合
openspec变更: <kebab-case-or-empty>
分级理由: <命中/未命中触发器及证据>
类型判型结论: <业务/技术/混合；判型依据>
DDD主类: <A/B/C/D>
Gate-0: 状态:待确认
Gate-1: 状态:待批准
Gate-2: 状态:待验收
---

# {{requirement_title}}
> Gate 状态与审批只维护在 YAML properties；`待*` 态仅写状态，其它状态须写 `审批人:<git user.name>；YYYY-MM-DD`。触达 UI 时 **Gate-1 批准前不要写** frontmatter `UI验收证据`（可省略该键）；批准同轮再写入 `UI验收证据: 组件测试|Playwright|集成测试`（默认组件测试）。按需片段见 `.codebuddy/templates/requirements/section-fragments.md`。Gate-1 字段见 `.codebuddy/templates/requirements/gate1-plan-template.md`；PRD 分档见 `.codebuddy/templates/requirements/gate1-by-tier.md`。

# Gate-0 澄清与范围
## 原始诉求（verbatim，禁止改写）
> <逐字粘贴用户/PRD 原话>

## 歧义登记
歧义登记: none（已逐句复核，触达面：…；确认人:<git user.name>；日期:{{date}}）

## 业务目标
- …

## 用例 / 用户故事
1. 作为 …，我希望 …，以便 …

## 范围与切片
背景（可选）：{{project_goal}}
> In Scope 只写**能力边界**（一句话/条），不写 GWT。可执行验收见 Gate-1 `## 验收标准`。
**In Scope**
- …
**Out of Scope**
- <排除项>（原因：...；重开触发：...）
**Open Questions / Deferred**
> `DEF-*`：本期明确排除/延期（**不**触发 Gate-0「部分通过」）。「部分通过」仅当歧义登记 / 数据流闭环表 / OQ 仍有 `[待确认]` 或未闭环单元格。
- OQ-001：<问题> → 结论：[待确认]
- DEF-001：<延期项>

## 约束引用
> 业务/混合：`约束引用: none` 必须含非空「触达面」；命中则填下表路径。apply 前只读本表已列路径并打 `Experience Reuse`。UI pattern 命中时，在 Gate-1 `## 验收标准` 衍生 `AC-UI-*`。
约束引用: none（已检索，触达面：模块|BC|关键词）
| 相关项 | 匹配依据与关联点 | 本需求处置 |
|---|---|---|
| — | — | 复用 / 规避 / 无关 |

## 数据流闭环表
> `green-trivial` 可改写为：`本需求无数据流（green-trivial）`。行名用**能力简述**（与 In Scope 一致），不用 AC-*。
> 行主键供 Gate-3 `capability-map`：`moduleKey` + **前端入口**（路由/菜单 path，如 `/w/system-roles`）；无 UI 填 `—`。
| 能力 | 来源(Source) | 加工(Process) | 去向(Sink) | 前端入口 | 相关表 | 闭环 |
|---|---|---|---|---|---|---|
| <能力简述> | `<真实来源 + 落点>` | `<校验/规则/直通>` | `<表/状态/返回/展示>` | `<路由或—>` | `<表名或—>` | 待确认 |

## 原型对齐与偏离
无原型对照。

# Gate-1 方案与验收
## 页面布局预览
> 无原型且有前端入口时必填 ASCII 布局（或「参照现有页+差异」）；有原型或纯后端写「不适用（…）」。规则见 `gate1-plan-template.md`「页面布局预览」。

## 验收标准
> `/xijia:prd` 落盘时按分档写满（见 `gate1-by-tier.md`）。`green-trivial` 可写 `不适用（green-trivial）`。
> 三态勾选：`[ ]` 未检 → verify 后 `[~]` 程序已检 → Gate-2 签字后 `[x]`。详见 `gate1-plan-template.md` 规则 5。
- [ ] 覆盖要求：每条 In-Scope 能力至少 正常/空/错误/无权限；≥1 条可执行断言
- [ ] **AC-1**：GIVEN … WHEN … THEN …
  - **反例（本 AC 排除）**：…
- [ ] **AC-UI-1**（若约束引用含 UI pattern）：…

## 实现方案
> 绿/黄：满密度。红：首段说明 OpenSpec 变更名/目录/`openspec-propose` 时机；无包时同黄档写满草案。禁止空洞「红档以 OpenSpec…(黄档无)」。
- 架构 / 关键改动：…
- 复用映射 / 代码落点：

  | 已有模块/服务 | 可复用接口/函数/表 | 关系类型 | 精确坐标 |
  |---|---|---|---|
  | … | … | 直接调用 / 扩展 / 新建 | `path` |

- 影响面与回归范围：…
- 切片拆解：
  1. [AC-1] …
- 交互语义：布局见上方 `## 页面布局预览`（若有）。`<用户操作>` → `<状态变化>`；不适用时写原因
- 回归验证点：`cd backend && pytest …` / `cd frontend && npm run build`

# Gate-2 验收
## 验收记录 — <切片名> {{date}}
- 变更文件（来自 `git diff`）：...
| AC | 结论 | 验证方式 | 证据（类型 + 出处） | 结果摘要 |
|---|---|---|---|---|
| AC-1 | 通过 / 未过 / 未执行 | `<命令或步骤>` | 命令输出 / 截图 / 组件测试 / 用户实机确认；`<出处>` | — |
- 遗留 / 风险 / Deferred：none
- 一条可复跑验证命令：`<command>`

# Gate-3 沉淀
## 实现记录与沉淀
> 标题须为 `## 实现记录与沉淀`（H2；guard 亦兼容历史 H1）。已改对应活文档时禁止 false `no-op`。
> **green-trivial**：可整段保持下列 no-op / none，禁止扩写。
- Experience Reuse: none（已检索，触达面：…）｜或 `docs/patterns|pitfalls/<file>.md`（文档真相源；约束引用已列路径时禁止 none）
- Capability Index: no-op
- Living Docs: no-op
- Flow: no-op
- Patterns: no-op
- Pitfalls: no-op
