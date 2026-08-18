# Skill Routing Evals

Perplexity 方法论：改 description 前先跑路由 eval。静态匹配 skill frontmatter `description` 关键词。

## 运行

```bash
python .cursor/skills/evals/scripts/run_skill_evals.py
python .cursor/skills/evals/scripts/run_skill_evals.py --case ops-load-positive
```

## 用例文件

- `skill-routing.eval.yaml` — 正例 / 负例 / forbidden load

## 触发时机

- 修改 `.cursor/skills/*/SKILL.md` frontmatter description 前
- 新增/重命名自建技能后（须符合 `07-xijia-skill-naming.mdc`）
- `policy_flow_drift_check.py` 通过后（流程语义变更时）
