---
name: xijia-policy-drift-check
description: "Load when 改了 rules/skills/commands 后宣告流程已同步. Policy flow drift check."
---

# Policy Drift Check

## 目标

针对流程规则文档做轻量巡检，确保关键门禁与状态字段在以下文件中一致：

- `.codebuddy/rules/00-workflow.mdc`
- `.codebuddy/rules/45-requirement-intake.mdc`
- `.codebuddy/skills/xijia-ops-pipeline/SKILL.md`
- `.codebuddy/skills/xijia-feature-pipeline/SKILL.md`
- `.codebuddy/commands/xijia-start.md`

> 术语漂移由 `drift_guard_scan.py` hook 执行；本技能仅负责流程语义一致性。

## 同步字段登记表

| 类别 | 必须出现的字段/语义 |
| --- | --- |
| Gate | Gate-0 / Gate-1 / Gate-2 |
| CTA 输出 | `**请你：**` / `**然后：**`（`--resolve-gate --format cta`） |
| Probe | `xijia-spike-probe` 引用与触发条件 |
| Deferred | `partial/reject` 需入 `docs/requirements/backlog.md` |
| Comment Sync | 写代码阶段 `xijia-comment-enhancer`；verify `--check-comment-sync` |
| Quality | `xijia-quality-judge` 与 `通过|需修订` |
| Release Gate | `47-release-lifecycle`、`/xijia:release`、`--check-release-readiness` |
| Tier Variant | `green-trivial` 与无数据流声明 |

## 巡检步骤

1. `rg "Gate-0|Gate-1|Gate-2|complete\\|partial\\|reject" .codebuddy/rules .codebuddy/skills .codebuddy/commands`
2. 检查状态模板、probe、Deferred、comment-sync、xijia-quality-judge 字段
3. 运行 `python .codebuddy/hooks/policy_flow_drift_check.py`
4. 修改 skill description 前：`python .codebuddy/skills/evals/scripts/run_skill_evals.py`

## 到期审计（每个模型代际一次，或随 `/xijia:release` 批次）

harness 里每一条都编码了一个「模型自己做不到什么」的假设，假设会随模型变强而过期。本节让「已经到期」变得可检出。

判别式：**一条规则若因「模型记不住 / 不会主动做 / 容易漏」而存在，它已在到期队列里**；因「只有我们知道」或「只有人能承担」而存在的（验收判据、Gate、授权边界、内部工具用法、模块 gotcha），不会到期。

步骤：

1. 逐条读 `.codebuddy/rules/*.mdc` 的 frontmatter `defends:`（缺失项由 `drift_guard_scan.py` 报出，见 `06-rule-drift-guard.mdc`）。
2. 对每条问 **what can I stop doing**：`defends` 写的那个失败，现在还复现吗？
   - 有可执行复现路径（guard 命令 / pitfall / eval 用例）→ 跑一遍，仍失败则保留。
   - 已不复现 → 列为删除候选。
   - `defends` 标注「不到期」（L3 不可逆动作与责任边界）→ 跳过，不参与裁剪。
3. 删除候选先做**消融对照**：删前删后各跑 `run_skill_evals.py` + `pytest .codebuddy/hooks/tests -q`，无回归才落地。
4. 同时扫指令层里能沉降到工具层的条目——可表达成 guard / 测试 / lint 的，移到工具层再从规则删除。指令层强度取决于模型当下怎么读它，工具层不取决于。

**完成：** 输出到期候选清单（保留/删除/下沉三态），每条附 `defends` 与复现结论。

## 何时必须执行

- 修改流程 rules/skills/commands 后
- 宣告「流程已同步」前
- `xijia-project-init` self-check 自动运行
- 到期审计：每个模型代际或发布批次（见上节）

## 输出模板

```text
Policy Drift Report:
- verdict: pass|revise
- missing_or_inconsistent: [...]
```

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 只改 00-workflow 未改 ops hub | 三重维护漂移 | 改流程只动 ops-pipeline references |
| 改 description 无 eval | 路由回归 | 先跑 `run_skill_evals.py` |
| xijia-feature-pipeline 恢复长正文 | 别名膨胀 | 保持纯委托 ops-pipeline |
| 宣告 pass 但 drift revise | 未修字段 | 按 required_fixes 补齐 |
