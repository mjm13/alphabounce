---
name: xijia-project-init
description: "Load when /xijia:init, 空仓库, 冷启动. Not for /xijia:start."
agent_created: true
---

# Xijia Project Init

## 目标（初始化边界）

在**空仓库**里通过对话一次性完成冷启动：

1. 流程基座文档（`docs/`、根 `AGENTS.md`，[agents.md](https://agents.md/) 标准章节 + `Xijia workflow` 扩展）
2. 确认技术栈并安装高评分技能
3. **code-shell**：按确认路径创建空代码目录（非可跑业务工程）
4. **种子化**工程基线 technical 需求到 inbox（后端 / 条件满足时前端 / 有 DB 时运行基线）
5. 输出可追溯 Init Report；**Next** 指向 `/xijia:start <YYYYMMDDHHMMSS-…>`

本技能**禁止**：

- 实现业务功能代码
- 在 init 内直接跑框架 CLI（`create-*-app` / Spring Initializr 等）生成可跑工程——交给 `/xijia:start` 推种子需求（Gate-1 后人审）
- 推进 explore/propose/apply（由 `xijia-ops-pipeline` 负责）
- 覆盖已有文件（默认空仓库；补齐模式仅新增）
- 用户未确认技术栈前安装技能

## 触发时机

- 用户说“初始化项目”“从零搭骨架”“生成初始化文档”
- 用户使用 `/xijia:init`

## 强制规则（Hard Gates）

1. 先做仓库保护检查（Guard）：
   - 若存在 `docs/` 或 `AGENTS.md`，默认停止并提示“该 init 面向空仓库”
   - 仅当用户明确允许“补齐缺失且不覆盖”时，才进入补齐模式
2. 初始化前必须完成访谈并复述确认（Manifest Confirm）
3. 技术栈必须由用户确认，模型不可擅自指定
4. 评分与安装必须透明：记录候选、评分、入选理由
5. 技能安装遵循“每个技术栈取评分最高的 2-3 个技能”
6. 安装后必须校验 `SKILL.md` frontmatter：`name` 与目录同名；**项目自建技能**须 `xijia-` 前缀（见 `.cursor/rules/07-xijia-skill-naming.mdc`）
7. 若 `skills` CLI 安装到 `.agents/skills/`，必须搬运到 `.cursor/skills/`
8. 产出初始化锁文件（`skills-lock.json`）时要在报告中说明用途
9. **init 栈相关 skill 总量 ≤10**；找不到/安装失败则跳过，禁止整库或无关 skill 顶替；0 个成功仍可 done（须列 Skills Skipped）
10. **禁止** Stage 名使用 `scaffold` 指文档阶段（用 `docs-render`）；code-shell / 种子需求为独立阶段

## 渐进披露

| 阶段 | 文件 |
| --- | --- |
| Guard → interview → docs-render → skills → code-shell → seed → self-check | [`references/stages.md`](references/stages.md) |

**状态机**：`guard → interview → manifest-confirm → docs-render → skills-bootstrap → code-shell → seed-bootstrap-reqs → self-check → done`

**完成判据**：self-check 全绿（含 `policy_flow_drift_check.py`）；Next 指向 `/xijia:start <首个种子 inbox>`。

## 输出格式（固定）

```markdown
## Xijia Init Status

- Stage: <guard|interview|manifest-confirm|docs-render|skills-bootstrap|code-shell|seed-bootstrap-reqs|self-check|done>
- Mode: <empty-repo|supplement-only>
- Created: <files/directories>
- CodeShell: <created paths|skipped + reason>
- Seeded Requirements: <inbox paths or none>
- Skipped: <existing files kept untouched>
- Stack Confirmed: <summary>
- Skills Selected: <name + score + source>
- Skills Installed: <success list>
- Skills Skipped: <name + reason>
- Next: /xijia:start docs/requirements/inbox/<first-seed>.md
- Blockers: <none or list>
```

## 失败处理

- 非空仓库：中止并提示“使用 `/xijia:start` 或进入补齐模式（仅新增不覆盖）”
- 技能安装失败：记录失败项，不中断文档初始化
- `self-check` 失败：`blocked`，禁止宣告完成

## Install Enforcement（Hard Gate）

- Default：`auto install`；仅用户显式选择时用 `recommendation-only`
- 栈相关 skill **≤10**；禁止整库/乱装；找不到就跳过
- 0 个成功允许 `done`（文档 + code-shell/种子按条件交付即可）

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 非空仓库覆盖文件 | init 禁止覆盖 | 中止或 supplement-only |
| 未确认栈就装技能 | 硬门禁 | 先对话确认技术栈 |
| README 未标 Gate-3 维护 | 活文档遗漏 | 模板 README 含栈同步说明 |
| self-check 失败仍宣告完成 | 未跑 drift check | `policy_flow_drift_check.py` blocked |
| 在 init 内跑框架 CLI | 越界 | 种子需求交给 `/xijia:start` |
| 需求模板中文乱码（鏍囬/鐘舵€） | PowerShell 默认编码误读 UTF-8 `.tmpl` | 用 `render_init_templates.py` 或 Write；禁止无 `-Encoding utf8` 的 Get-Content 管道 |
