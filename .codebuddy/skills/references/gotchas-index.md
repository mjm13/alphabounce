# GOTCHAS 索引（技能 ↔ pitfall）

Gate-3 `xijia-sync-knowledge` 新增 `docs/pitfalls/*` 时，在此登记并反哺对应技能 `## GOTCHAS`。

| pitfall / 主题 | 关联技能 | 技能内 GOTCHAS |
| --- | --- | --- |
| `living-doc-outside-gate3.md` | xijia-sync-knowledge, xijia-project-init | README 栈漂移 |
| `soft-delete-unique-key-conflict.md` | xijia-ops-pipeline (apply) | DB 迁移 Approval Gate |
| 会话摘要 Stage 漂移 | xijia-ops-pipeline | `--resolve-gate` |
| PowerShell commit 乱码 | xijia-git-commit | UTF-8 文件 commit |
| PRD 原型硬停 | xijia-prd-to-requirement | Step 1.2 |
| 无原型缺布局预览 | xijia-prd-to-requirement | Step 4a / `.codebuddy/templates/requirements/gate1-plan-template.md` |
| 模板双源 | 任意 | 禁止在 `docs/requirements/` 维护 `*-template.md`；SSOT 见 `.codebuddy/templates/requirements/` |
| 流程三重维护 | xijia-policy-drift-check | drift check + eval |

| skill description 双载 / workflow-in-desc | xijia-ops-pipeline, skill-authoring-checklist | CSO；跑 run_skill_evals + audit_skill_metrics |
| Gate-3 写协议 | xijia-safe-file-write, xijia-sync-knowledge | safe-file-write `gate3-markers`/`shipped-write` + sync `gate3-archive` |
| Gate-3 触发表 | xijia-sync-knowledge, xijia-ops-pipeline | `--gate3-trigger-report` 步骤 0 |
| 黄档有 INV 无 `domain/<bc>/` | xijia-sync-knowledge | 「有 INV 却只有 context-map」；domain-merge §11b + closeout |
| feature/ops NL 同义词双载 | xijia-feature-pipeline | NL 只挂 ops；alias desc 极短 |
| comment 格式 vs 强制触发混淆 | xijia-comment-enhancer, 44-comment-sync | rule=触发；skill=格式 |
维护：pitfall 新增 → 更新本表 + 目标技能 GOTCHAS 一行。
