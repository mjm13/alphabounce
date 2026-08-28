---
标题: <缺陷简述>
状态: 待处理
负责人: {{author}}
创建时间: {{date}}
分级: 绿 | 绿-轻量
类型: 缺陷
openspec变更:
分级理由: 单点修复；无跨 BC 改造
类型判型结论: 缺陷；按缺陷修复流程处理
DDD主类: D
Gate-0: 状态:待确认
Gate-1: 状态:待批准
Gate-2: 状态:待验收
---

# <缺陷简述>

> Gate 初始仅写状态；人工确认通过后才追加 `审批人:<git user.name>；YYYY-MM-DD`（Gate-0 通过写 `已通过`）。按需片段见 `.codebuddy/templates/requirements/section-fragments.md`。

# Gate-0 复现与范围

## 原始诉求（verbatim，禁止改写）

> <逐字粘贴缺陷报告>

## 歧义登记

歧义登记: none（已逐句复核，触达面：…；确认人:<git user.name>；日期:{{date}}）

## 业务目标

不适用（类型=缺陷）

## 用例 / 用户故事

不适用（类型=缺陷）

## 背景

- 环境 / 版本 / 提交：...
- trace_id / 日志：...

## 复现与期望

1. GIVEN ...
2. WHEN ...
3. THEN ...（实际错误行为）

期望：...

## 范围与切片

> In Scope 只写能力边界（修复后行为边界），不写细 GWT。可执行验收见 Gate-1 `## 验收标准`。

- **In Scope**：修复后目标行为；相关模块回归
- **Out of Scope**：非本缺陷根因的重构（原因：控制修复边界；重开触发：确认其为根因或独立立项）
- **OQ/Deferred**：OQ-001 ... / DEF-001 ...

## 约束引用

约束引用: none（已检索，触达面：<模块/BC/关键词>）

## 数据流闭环表

> 无新增数据流时声明：`缺陷修复无新增数据流`。行名用能力简述。

> 行主键供 Gate-3：`moduleKey` + **前端入口**（无 UI 填 `—`）。

| 能力 | 来源(Source) | 加工(Process) | 去向(Sink) | 前端入口 | 相关表 | 闭环 |
|---|---|---|---|---|---|---|
| 修复后目标行为 | 现有请求/数据 | 修正既有逻辑 | 既有返回/展示 | — | — | 已确认 |

## 原型对齐与偏离

无原型对照。

# Gate-1 方案与验收

## 页面布局预览

> UI 缺陷且无原型时必填（见 `.codebuddy/templates/requirements/gate1-plan-template.md` / `section-fragments.md`）；纯后端或样式单点可写 `不适用（无 UI 触达）`。

## 验收标准

- [ ] **AC-1**：修复后 GIVEN ... WHEN ... THEN ...
  - **反例（本 AC 排除）**：...
- [ ] **AC-2**：相关模块回归验证通过
  - **反例（本 AC 排除）**：无关模块失败被误判为本缺陷未修

## 实现方案

| 切片 | 覆盖 AC | 代码落点 | 验证命令 |
|---|---|---|---|
| 修复与回归 | AC-1, AC-2 | `path/to/file` | `<可执行验证命令>` |

- 复用映射 / 代码落点：...
- 切片拆解：
  1. [AC-1] 修复根因
  2. [AC-2] 回归
- 回归验证点：`<可执行验证命令>`

# Gate-2 验收

## 验收记录 — {{date}}

- 变更文件（来自 `git diff`）：...

| AC | 结论 | 验证方式 | 证据（类型 + 出处） | 结果摘要 |
|---|---|---|---|---|
| AC-1, AC-2 | 通过 / 未过 / 未执行 | `<命令或步骤>` | 命令输出 / 截图 / 组件测试 / 用户实机确认；`<出处>` | — |

- 遗留 / 风险 / Deferred：none
- 一条可复跑验证命令：`<command>`

# Gate-3 沉淀

## 实现记录与沉淀

- Experience Reuse: none（已检索，触达面：缺陷修复）
- Capability Index: updated | no-op
- Living Docs: updated | no-op
- Flow: updated | no-op
- Patterns: `<docs/patterns/*.md>` | no-op
- Pitfalls: `<docs/pitfalls/*.md>` | no-op

> hotfix 基于已发布 `release/<版本>` 修复时，合入后必须回合 `master`。
