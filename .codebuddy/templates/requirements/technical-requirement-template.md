---
标题: {{technical_requirement_title}}
状态: 待处理
负责人: {{author}}
创建时间: {{date}}
分级: 绿 | 绿-轻量 | 黄 | 红
类型: 技术
openspec变更:
分级理由: <命中/未命中触发器及证据>
类型判型结论: 技术；<判型依据>
DDD主类: D
Gate-0: 状态:待确认
Gate-1: 状态:待批准
Gate-2: 状态:待验收
---

# {{technical_requirement_title}}

> Gate 初始仅写状态；人工确认通过后才追加 `审批人:<git user.name>；YYYY-MM-DD`。按需片段见 `.codebuddy/templates/requirements/section-fragments.md`。

# Gate-0 澄清与范围

## 原始诉求（verbatim，禁止改写）

> <逐字粘贴原始技术诉求>

## 歧义登记

歧义登记: none（已逐句复核，触达面：…；确认人:<git user.name>；日期:{{date}}）

## 业务目标

不适用（类型=技术）

## 用例 / 用户故事

不适用（类型=技术）

## 范围与切片

> In Scope 只写能力边界，不写 GWT。可执行验收见 Gate-1 `## 验收标准`。

- **In Scope**：…
- **Out of Scope**：<排除项>（原因：...；重开触发：...）
- **OQ/Deferred**：OQ-001 ... / DEF-001 ...

## 约束引用

约束引用: none（已检索，触达面：…）

## 数据流闭环表

> 纯配置/文档类 `绿-轻量` 可声明：`本需求无数据流（green-trivial）`。行名用能力简述。

> 行主键供 Gate-3：`moduleKey` + **前端入口**（无 UI 填 `—`）。

| 能力 | 来源(Source) | 加工(Process) | 去向(Sink) | 前端入口 | 相关表 | 闭环 |
|---|---|---|---|---|---|---|
| <能力简述> | ... | ... | ... | `<路由或—>` | `<表名或—>` | 已确认 |

## 原型对齐与偏离

无原型对照。

## 质量属性（按需）

- 性能/容量、可靠性、安全/权限、兼容/迁移/回滚、配置差异、可观测性、风险/ADR：...

# Gate-1 方案与验收

## 页面布局预览

> 无 UI 触达写 `不适用（无 UI 触达）`；有 UI 且无原型见 `gate1-plan-template.md`。

## 验收标准

> `/xijia:prd`（或技术需求落盘）时写满。`green-trivial` 可写 `不适用（green-trivial）`。

- [ ] **AC-1**：GIVEN ... WHEN ... THEN ...（含可度量技术指标）
  - **反例（本 AC 排除）**：...

## 实现方案

- 架构 / 关键改动：...
- 复用映射 / 代码落点：...

| 切片 | 覆盖 AC | 代码落点 | 验证命令 |
|---|---|---|---|
| Slice-1 | AC-1 | `path/to/file` | `<可执行验证命令>` |

- 切片拆解：
  1. [AC-1] ...
- 回归验证点：`<可执行测试/构建命令>`

# Gate-2 验收

## 验收记录 — <切片名> {{date}}

- 变更文件（来自 `git diff`）：...

| AC | 结论 | 验证方式 | 证据（类型 + 出处） | 结果摘要 |
|---|---|---|---|---|
| AC-1 | 通过 / 未过 / 未执行 | `<命令或步骤>` | 命令输出 / 截图 / 组件测试 / 用户实机确认；`<出处>` | — |

- 指标 / 故障与回滚验证：...
- 遗留 / 风险 / Deferred：none
- 一条可复跑验证命令：`<command>`

# Gate-3 沉淀

## 实现记录与沉淀

- Experience Reuse: none（已检索，触达面：技术需求）
- Capability Index: updated | no-op
- Living Docs: updated | no-op
- Flow: updated | no-op
- Patterns: `<docs/patterns/*.md>` | no-op
- Pitfalls: `<docs/pitfalls/*.md>` | no-op
