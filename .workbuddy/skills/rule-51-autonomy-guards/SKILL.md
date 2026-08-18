---
name: rule-51-autonomy-guards
description: "自治执行护栏（预算熔断 + 可恢复状态）"
agent_created: true
---

# 目标

避免长链自治任务失控，确保可恢复、可中断、可解释。

# 规则

1. 多步任务必须声明预算：token/成本/时间窗口。
2. 达到预算阈值必须 `stop-and-report`，等待用户确认继续。
3. 以 `tasks.md` 勾选状态 + `openspec status` 作为恢复检查点。
4. 非终止性任务需周期性输出进度与剩余预算。

# 输出模板

```text
自治护栏状态：
- budget: token=... cost=... time=...
- used: token=... cost=... time=...
- checkpoint: task X/Y
- action: continue | stop-and-report
```
