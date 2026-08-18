---
name: rule-43-correction-learning
description: "用户纠正学习（验证后沉淀到知识文档 / ADR）"
agent_created: true
---

# 触发条件

当用户明确纠正 AI 口径，且纠正涉及术语、边界、流程、规则或数据语义时触发。

# 执行要求

1. 先用代码或文档证据验证纠正内容。
2. 验证成立后，按纠正类型选择去向：
   - 业务/领域语义：追加到 `docs/domain/*`、`docs/decisions/*`（ADR）或对应 requirement（不覆盖历史）。
   - 可复用失败模式：写入 `docs/pitfalls/*`。
   - 门禁/流程失效：除 pitfall 外，必须同步修正对应 `.cursor/rules/*` 或 `.cursor/skills/*`，不得只记录案例而保留失效流程。
3. 每次沉淀需附最小证据摘要：入口/契约/执行点/数据落点。
4. 无法闭环验证时标记 `[待确认]`，不得作为已确认事实写入。
5. 修改 rules/skills 后必须运行 `python .cursor/hooks/policy_flow_drift_check.py`；涉及 guard 时还须运行 `.cursor/hooks/tests/`。

# 输出模板

```text
纠错学习记录：
- 用户纠正：...
- 验证证据：入口... / 契约... / 执行点... / 数据落点...
- 知识去向：docs/domain/... | docs/decisions/... | docs/pitfalls/... | 对应 requirement | .cursor/rules|skills/...
- 状态：confirmed | 待确认
```
