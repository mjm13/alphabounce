---
name: xijia-feature-pipeline
description: "Load when xijia-feature-pipeline alias; immediately load xijia-ops-pipeline."
agent_created: true
---

# Feature Pipeline

立即加载并严格遵循 **`xijia-ops-pipeline`**；行为等同 `/xijia:start`（含 `--resolve-gate --format cta` CTA 输出）。本文件不维护编排细节。

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 裸跑 `openspec-apply-change` | 未走 superpowers 联动 | 仅用 `openspec-superpowers-apply` |
| 本文件与 ops-pipeline 步骤不一致 | 双份维护漂移 | 只改 `xijia-ops-pipeline`；跑 `policy_flow_drift_check.py` |
| 自然语言触发却走 init/release | 路由误判 | description 区分「推进需求」vs「冷启动/发版」 |
