# Gate-0 检查清单（PRD 转需求）

完整程序见 [`.codebuddy/templates/requirements/gate0-intake.md`](../../templates/requirements/gate0-intake.md)。
Gate-1 分档见 [`.codebuddy/templates/requirements/gate1-by-tier.md`](../../templates/requirements/gate1-by-tier.md)。

## PRD 特有硬停

- **Step 1.2**：有原型时须「原型现状（相对 PRD）」+ 口径（以PRD为准|以原型为准|分批）确认前禁止落盘
- **歧义登记**：用户/PRD 原话须逐字落盘；多义片段至少列两种读法并人工文字确认。静态原型不能确认交互时序或状态变化
- **Step 1.6**（能力B 主动检索）：按模块/BC/关键词检索 shipped/decisions/pitfalls/patterns/domain，产出 top-N 相关历史填「相关历史（主动检索）」表；或写 `约束引用: none`
- **Step 1.7**：在 Gate-0「约束引用」下按需记录 PRD 现状对照与冲突识别结论
- **Step 2**：数据流闭环表每行来源/加工/去向 `已确认`；业务/混合须填 **前端入口**（路由/菜单 path，无 UI 填 `—`）与相关表（供 Gate-3 capability-map 主键）
- **Step 2.6**：一次性确认卡片（含原型结论引用，不得首次发现差异）
- **Step 4 落盘**：先加载 `xijia-safe-file-write`；直接 Write 各 inbox（或 `write_utf8.py`）；每篇 `verify_utf8.py`；禁止 win32 Shell heredoc；禁止默认 `_gen_*.py`
- **Step 4 Gate-1**：顺序 **页面布局预览**（无原型+UI）→ **验收标准** + **实现方案**（见 `.codebuddy/templates/requirements/gate1-by-tier.md` / `gate1-plan-template.md`）；红档首段说明 OpenSpec

## 章节落点（相对旧平铺模板）

| 内容 | 落点 |
| --- | --- |
| 业务目标 | Gate-0 `## 业务目标` |
| 用例 / 用户故事 | Gate-0 `## 用例 / 用户故事` |
| 范围 In/Out/DEF | Gate-0 `## 范围与切片`（能力边界，无 GWT） |
| 无原型 UI 布局 | Gate-1 `## 页面布局预览`（无原型+前端入口；有原型跳过） |
| 验收标准 GWT + 反例 | Gate-1 `## 验收标准`（**PRD 落盘时写满**） |
| 实现方案 | Gate-1 `## 实现方案`（**PRD 落盘时按分档写满**） |

## 校验

```bash
python .codebuddy/hooks/pipeline_guard.py --check-intake --req <file>
python .codebuddy/hooks/pipeline_guard.py --check-plan --req <file>
```

两者均通过后再提示 `/xijia:start`。A.0.5 仅在 plan fail 时增量补全。交接时「下一步」段落后追加一行：**具体指令：** 审阅 Gate-1（**页面布局预览** → 验收标准 → 实现方案）后文字回复「批准 Gate-1」（审批人=git user.name；落盘 `Gate-1: 状态:已批准`）。

## Intake 弱项与 verdict

| 情况 | verdict |
| --- | --- |
| 歧义登记 / 闭环表 / OQ 仍有 `[待确认]` 或未闭环 | `部分通过`（指引用户确认这些断点） |
| 未决 OQ / Deviation open | 不得 `已通过` |
| 仅有 `DEF-*`、正文无待确认断点、`--check-intake` OK | 可标 `已通过`（**禁止**因 DEF 标部分通过） |
| 选「分批」且对应能力仍未确认 | 未确认部分标 `部分通过`；已确认切片可 `已通过` |
| MCP 不可用且探针结论未人工确认 | `部分通过` + 人工确认模式 |
