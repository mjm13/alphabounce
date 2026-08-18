---
name: xijia-project-adopt
description: "Load when /xijia:adopt, 历史项目接入, 多模块 adopt. Not for /xijia:init."
agent_created: true
---

# Xijia Project Adopt

## 目标

在**已有代码、多子模块**工作区接入 xijia 流程：

1. 文档基座（复用 init 模板子集 + manifest + ADR-0002）
2. codegraph preflight（逐模块 init）
3. 代码扫描产草稿（manifest / AGENTS / architecture / DDD `_draft/`）
4. 人工 content 确认
5. Adoption Readiness verify → 交接 `/xijia:start`

**禁止**：code-shell、创建工程基线种子需求、覆盖活文档、未经确认进入 verify。

## 触发时机

- `/xijia:adopt`
- 「历史项目接入」「多模块 adopt」

## Guard（与 init 相反）

| 条件 | 行为 |
| --- | --- |
| 无 `.cursor/rules/` | **hard block**（先完成 Step 2 复制 xijia-base） |
| `adopt.stage=done` | 拒绝 verify；提示 `/xijia:start` |
| 无 `docs/` | 允许 scaffold |
| 有 `docs/` 无 manifest | supplement-scaffold（仅补缺失） |
| 有非空代码目录 | **预期**；不报错 |

## Interview（scaffold 前必做）

1. 项目名称、一句话目标
2. **Git 拓扑**：`single-repo` | `multi-repo-copy` | `symlink`
3. `skip-codegraph`：是/否（是则 discover 仅 L0–L2，H11 用 skipped+理由）
4. `ddd_required`：是/否（是则 content 须提升 context-map + 术语，verify 启用 H12）
5. MCP/DB：按需（**禁止**复制 init 模板默认 mysql 凭据）
6. 技能策略：`auto install` | `recommendation-only`（≤10）

Manifest Confirm 后执行。

## 渐进披露

| 阶段 | 文件 |
| --- | --- |
| scaffold → preflight → discover → content → verify | [`references/stages.md`](references/stages.md) |

**状态机**：读 `docs/workspace-manifest.yaml` → `adopt.stage`

**完成判据**：`--check-adopt-readiness` 通过 + Adoption Gate 文字签字 + `adopt.stage=done`；Next → `/xijia:prd` 或 `/xijia:start`。

## 中断恢复

读 `docs/workspace-manifest.yaml` → `adopt.stage`（见 `05b-project-adopt.mdc`）。

## 输出格式

```markdown
## Xijia Adopt Status

- Stage: <scaffold|preflight|discover|content|verify|done>
- Mode: <adopt|supplement-scaffold>
- AdoptStage: <yaml adopt.stage>
- Modules: <n>
- Codegraph: <summary>
- Readiness: <pass|fail>
- Next: <command>
- Blockers: <none|list>
```

## 脚本参考

| 脚本 | 用途 |
| --- | --- |
| `scan_workspace.py --discover-modules-only` | L0 |
| `scan_workspace.py --preflight-codegraph` | codegraph init + mcp.json |
| `scan_workspace.py --discover` | 全量 discover |
| `pipeline_guard.py --check-adopt-readiness` | Step 5 机器检 |

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 误用 /xijia:init | 路由错误 | 历史项目用 adopt |
| verify 前未 content | H10 | 确认 discovery.status |
| codegraph 未 init | H11 | preflight |
| 包名当 BC 终稿 | propose-not-mint | content 确认 |
| 重复 verify | stage=done | /xijia:start |

## Install Enforcement

- codegraph 安装须用户 Approval Gate
- 安装方式：PATH 可用的 `codegraph` CLI（具体安装文档在 adopt 时 stop-and-report 给出）
