# Project Rules（人读索引）

本目录 `.mdc` 由 Cursor 按 frontmatter 注入；**本 README 不会被 rules 系统加载**。

硬约束：rules **不含产品技术栈信息**（框架/库/引擎/语言专属文件名）。栈约定见根目录 `AGENTS.md` 与对应 skills。

## 激活矩阵

| 文件 | 模式 | 触发 |
| --- | --- | --- |
| `00-workflow.mdc` | Always | 每会话 |
| `22-db-destructive-safety.mdc` | Always | 每会话 |
| `20-backend.mdc` | Auto-Attached | `backend/**` |
| `30-frontend.mdc` | Auto-Attached | `frontend/**` |
| `31-table-first-panel.mdc` | Auto-Attached | `frontend/src/components/*Panel.vue` |
| `45-requirement-intake.mdc` | Auto-Attached | `docs/requirements/**` |
| `10-openspec-ddd.mdc` | Auto-Attached | `docs/openspec/**` |
| `47-release-lifecycle.mdc` | Auto-Attached | `docs/process/**` 等 |
| `06-rule-drift-guard.mdc` | Auto-Attached | `.codebuddy/rules/**`、`.codebuddy/skills/**` |
| `07-xijia-skill-naming.mdc` | Auto-Attached | `.codebuddy/skills/**`、`.codebuddy/commands/**` |
| `40` / `41` / `42` / `44` | Agent-Requested | 取证 / 边界 / verify / comment-sync |
| `43` / `46` / `50` / `51` | Agent-Requested | 纠正学习 / git / 上下文 / 自治 |
| `05` / `05b` | Agent-Requested | init / adopt 意图 |

## 漂移扫描

`afterFileEdit` → `python .codebuddy/hooks/drift_guard_scan.py`  
词库与口径见 `06-rule-drift-guard.mdc`。
