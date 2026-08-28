---
name: xijia-docs-score
description: "Load when Gate-3 经验复用判定, --judge-doc, docs 卫生评分."
---

# xijia-docs-score

## 目标

评估 **patterns / pitfalls / decisions** 是否支撑真实研发决策（`useful` / `neutral` / `misleading`），产出复用与修订候选。不自动删除文件。

## When NOT

- 日常编排 → `xijia-ops-pipeline`；本技能作 sync / release 子步骤
- 全量卫生评分在 `/xijia:release` 或周度，非每需求强制
- 活文档 / shipped / inbox / 模板不在默认评分范围（勿当删除清单）

## 数据文件

- 判定事件（主）：`observability/docs_judgments.jsonl`
- 使用事件（辅，可选）：`observability/docs_usage.jsonl`
- 聚合：`observability/docs_score.json`
- 报告：`observability/文档评分报告.md`

> 全部输出集中在仓库根 `observability/`（不在 `docs/` 下，避免使用日志记录自己、报告被自己评分）；说明见 `observability/README.md`。

## 评分口径

- `score = useful - misleading`；`neutral` 不加减分
- **判定优先**：有 `--judge-doc` 即可计入；`--use-doc` / `used_count` 仅辅记
- 默认范围：`docs/patterns/`、`docs/pitfalls/`、`docs/decisions/`；逃生口 `--scope all`

## 建议流程

**每需求（Gate-3，仅命中经验文档）**

1. requirement 写 `Experience Reuse: <path>`（**文档真相源**；closeout 认此行，不认 jsonl）
2. 对命中 `patterns|pitfalls`（及复用到的 decisions）追加判定：
   ```bash
   python .codebuddy/skills/xijia-docs-score/scripts/score_docs.py \
     --judge-doc <path> --judge-session <需求stem> \
     --judge-verdict useful|neutral|misleading --judge-reason "..."
   ```
3. `--use-doc` **可选**，不强制

**发版 / 周度（旁路，非阻断）**

```bash
python .codebuddy/skills/xijia-docs-score/scripts/score_docs.py
# 查看：--top 20 / --never-used（=尚无判定） / --useless-candidates / --negative-candidates
# 勿默认 --scope all
```

人工复核报告后再决定修订；锚点：`pipeline_guard.py --check-doc-anchors`。

## 判定三问

1. 是否支撑了具体开发决策？
2. 不看该文档是否仍会做同样决策？
3. 是否导致错误路径并被证伪？

- useful：是 / 否 / 否  
- neutral：否 / 是 / 否  
- misleading：第三问为是  

## 约束

- 只输出复用/修订候选，不自动删除。
- 结论可追溯到 judgment（及可选 usage）。

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 报告把 constitution/shipped 标未复用 | 用了 `--scope all` 或旧报告 | 默认 scope=experience；重跑脚本 |
| `used_count` 低但有 useful | 正常 | 判定优先；勿强刷 `--use-doc` |
| Gate-0 跑 score_docs | 阶段错误 | 仅 Gate-3 / release |
| 自动删除低分文档 | 违反约束 | 只人工复核候选 |
| Experience Reuse 有路径未 judge | Gate-3 漏步 | 对命中 path 跑 `--judge-doc` |
