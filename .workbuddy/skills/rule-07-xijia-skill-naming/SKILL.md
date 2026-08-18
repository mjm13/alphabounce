---
name: rule-07-xijia-skill-naming
description: "项目自建技能命名：目录与 name 须 xijia- 前缀；第三方技能除外 [globs:- '.cursor/skills/**' - '.cursor/commands/**']"
agent_created: true
---

# 自建技能命名（硬约束）

凡**本项目自建**、纳入 xijia 研发流程的技能：

1. **目录名**：`.cursor/skills/xijia-<kebab-case>/`
2. **frontmatter `name:`**：与目录名**完全一致**（小写、连字符、无空格）
3. **description**：路由触发器（`Load when …`），非能力说明书

新建或重命名技能前，确认未与下列**例外**冲突。作者规程见 [`.cursor/skills/references/skill-authoring-checklist.md`](../skills/references/skill-authoring-checklist.md)。

## Description 预算与 CSO

| 类型 | 预算 | 要求 |
| --- | --- | --- |
| 高频 model-invoked | ≤ ~120 字符 | 症状 / 命令 / 路径；distinct branches |
| 命令驱动 | ≤ ~80 字符 | 以 `/xijia:*` 为主 + 1–2 互斥词（Cursor 薄 slash ≈ user-invoked） |
| Alias | 极短 | 不双载 NL 同义词 |

**禁 workflow-in-desc**：不得在 description 复述流程（如 Orchestrates、Outputs、步骤摘要）。过程只写正文 / `references/`。

## 例外（禁止强加 xijia- 前缀）

| 类别 | 判定 | 原因 |
| --- | --- | --- |
| Superpowers 上游 | `using-superpowers`、`brainstorming`、`writing-plans`、`test-driven-development` 等 | 第三方包原名 |
| OpenSpec 上游 | `openspec-propose`、`openspec-explore`、`openspec-superpowers-apply` 等 | `openspec-*` 命名空间 |
| 第三方 / 生态技能 | 目录与 `name` **无** `xijia-` 前缀、且来自外部生态包 | 不得强行改名；具体名单见 skill-authoring-checklist（仅示例，不构成基线约束） |

## 本项目自建技能（须 xijia-）

编排、门禁、测试、探针、DDD、发布等流程技能均已统一为 `xijia-*`（如 `xijia-ops-pipeline`、`xijia-feature-pipeline`、`xijia-spike-probe`、`xijia-backend-test`）。

## 校验

- 改 `description` 前：`python .cursor/skills/evals/scripts/run_skill_evals.py`
- 改流程文件后：`python .cursor/hooks/policy_flow_drift_check.py`
- 批次剪枝 / 瘦身后：`python .cursor/skills/evals/scripts/audit_skill_metrics.py`
- 新增自建技能后：目录名 = `name:` = `xijia-<topic>`，并更新 `evals/skill-routing.eval.yaml` 用例
- 未跑 eval **禁止**宣称「路由已同步」

## 与命令的关系

`/xijia:*` 命令可保持现有命名；命令正文应指向对应 `xijia-*` 技能路径，勿再引用无前缀别名。
