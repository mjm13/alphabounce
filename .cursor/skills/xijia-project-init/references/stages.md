# Init 执行步骤（SOP）

由 [`../SKILL.md`](../SKILL.md) 渐进披露。

## 执行步骤（SOP）

### 1) 仓库保护检查（Guard）

- 检查是否已存在 `docs/`、`AGENTS.md`
- 若存在，默认中止并提示改用 `/xijia:start`
- 仅当用户明确要求“补齐模式（仅新增不覆盖）”时继续

### 2) 访谈（只问必要项）

至少收集以下字段：

- 项目名称
- 项目一句话目标
- 是否需要前端（是/否）
- 是否需要数据库（是/否）
- 首批模块（1-2 个）
- 技术栈候选（后端、前端、数据库、部署）
- `backend_path` / `frontend_path`（默认 `backend` / `frontend`）

并补充决策项：

- 初始化模式：`空仓库初始化` / `补齐模式（仅新增）`
- 技能安装策略：`自动安装` / `仅生成推荐清单`
- **code-shell**：`创建空目录`（空仓默认） / `跳过`（已有非空代码根）
- MCP 配置（可选）：是否按路径生成 `.cursor/mcp.json`；是否需要只读 DB MCP（需用户提供连接信息，init 不预设凭据）

### 3) 结构预览并确认（Manifest Confirm）

先展示将创建的清单，再请求确认。默认清单：

- `README.md`（根目录人类入口；**活文档**，Gate-3 维护栈摘要）
- `AGENTS.md`
- `docs/constitution.md`
- `docs/README.md`
- `docs/llms.txt`
- `docs/decisions/0001-project-bootstrap.md`
- `docs/domain/README.md`
- `.cursor/templates/requirements/requirements-template.md`
- `.cursor/templates/requirements/technical-requirement-template.md`
- `docs/requirements/backlog.md`
- `docs/requirements/shipped/README.md`（归档区说明）
- `docs/requirements/inbox/README.md`（过程文档入口说明）
- `docs/openspec/config.yaml`
- `docs/openspec/changes/archive/README.md`（归档区说明）
- `docs/archive/README.md`（过程产物归档说明）
- `docs/process/knowledge-maintenance.md`（活文档触发表 + 归档规则）
- `docs/process/project-lifecycle.md`（生命周期与 xijia 入口对照）
- `docs/process/release-checklist.md`（发布检查清单）
- `docs/process/incident-response.md`（事故响应占位）
- `.cursor/templates/requirements/defect-template.md`（缺陷/hotfix 模板 SSOT）
- `.github/workflows/ci.yml`（CI 占位）
- **code-shell**（若 Manifest=创建）：`{backend_path}/`、条件满足时 `{frontend_path}/`
- **种子需求**（条件见 Step 6）：inbox `<时间戳>-后端工程初始化`（frontmatter `种子: true`）等

按需创建（不在 init 预生成）：

- `docs/architecture.md`、`docs/capability-map.md`、domain 详档：需求收尾时创建

### 4) 渲染模板并写入（docs-render）

> 原误称 Stage=`scaffold`。本阶段**只写文档/配置模板**，不建业务代码、不跑框架 CLI。

- 根 `AGENTS.md` 结构契约（与 live 项目对齐）：`Project overview` → `Dev environment tips` → `Build and test commands` → `Testing instructions` → `Observability` → `Security` → `Commit and PR instructions` → `Xijia workflow`（勿恢复旧 §1–§7 编号）
- 使用 `templates/` 内模板生成文件
- 占位符最小集：`{{project_name}}`、`{{project_goal}}`、`{{primary_modules}}`、`{{chosen_stack_summary}}`、`{{author}}`、`{{date}}`、`{{backend_path}}`、`{{frontend_path}}`
- 非空仓库补齐模式下：只创建缺失文件，不覆盖已存在文件
- **MCP（按需）**：用户确认后从 `templates/.cursor/mcp.json.tmpl` 渲染；未确认则跳过
- 可选只读 DB MCP：用户显式提供连接信息后单独追加

#### UTF-8 编码（Hard Gate，Windows 必读）

`templates/` 源文件为 **UTF-8**。中文 Windows 上若用 PowerShell 默认 `Get-Content` / `Copy-Item` 管道写 `.md`，会按系统 ANSI（GBK）误读 UTF-8，产生「标题→鏍囬」类乱码。

**推荐（按优先级）**：

1. **Agent 写文件工具**：读取 `.tmpl` 内容后在 IDE 侧直接 Write（天然 UTF-8）
2. **本技能脚本（跨平台、可自检）**：

```bash
python .cursor/skills/xijia-project-init/scripts/render_init_templates.py \
  --project-name "指标平台 (METRIC HUB)" \
  --project-goal "企业级指标资产管理、开发运维与数据治理平台" \
  --primary-modules "指标目录、数据源管理" \
  --chosen-stack-summary "后端 Python FastAPI + 前端 React/Astryx + MySQL" \
  --author "$(git config user.name)" \
  --date "2026-07-29" \
  --backend-path backend \
  --frontend-path frontend \
  --seed-timestamp 20260729141500 \
  --seeds backend,frontend,runtime
```

补齐模式追加：`--supplement-only`。脚本末尾会跑 **encoding-check**（检测常见 mojibake 片段）；失败则 docs-render 不得 `done`。

3. **必须用 Shell 时（PowerShell 7+ / 显式编码）**：

```powershell
# inbox 复制骨架 SSOT 在 .cursor/templates/requirements/（init 不渲染到 docs/）
# 读：必须 -Encoding utf8
Get-Content -Path ".\.cursor\templates\requirements\defect-template.md" -Raw -Encoding utf8
```

**禁止**：

- `Get-Content` / `Copy-Item` 后 `-replace` 再 `Set-Content -Encoding UTF8` 且**未**指定读入 `-Encoding utf8`
- 在 `docs/requirements/` 再维护 `*-template.md` 副本（SSOT 见 `.cursor/templates/requirements/`）
- 对公共区三份 inbox 骨架预填 `{{author}}`/`{{date}}`（须保留占位符供 `/xijia:prd` / `/xijia:defect` 复制）

**docs-render 后抽检**：确认 `.cursor/templates/requirements/` 三份骨架 frontmatter 首行应为 `标题:` 而非乱码；`docs/requirements/` 下不应出现 `*-template.md`。

### 5) 技术栈确认后安装技能（skills-bootstrap）

流程：

1. 列出候选技能来源（`skills.sh`/GitHub）
2. 对每个候选计算评分（0-100）
3. 每个技术栈选择 Top 2-3（去重）
4. **全局硬上限：init 阶段最多安装 10 个 skill**
5. 安装到 `.cursor/skills/`（必要时从 `.agents/skills/` 搬运）
6. 校验 `SKILL.md` + frontmatter 一致性
7. 生成安装报告

**找不到就不装**：跳过并写入 `Skills Skipped`；0 个成功仍可继续。

### 6) code-shell（空代码目录）

条件：Manifest `code-shell=创建`，且目标路径不存在或为空。

执行（本阶段内联完成，无独立命令入口）：

1. 创建 `{backend_path}/.gitkeep` 或一句 README（「后端工程根；可跑骨架见 inbox 工程初始化需求」）
2. 若需要前端：创建 `{frontend_path}/` 同理
3. 增量更新 `AGENTS.md` **Project overview**：写入 manifest 路径锚点（Backend root / Frontend root 填 `{backend_path}`/`{frontend_path}`；UI reference 保持 `<待补充>`）；列出顶层目录职责；**Build and test commands** 仍可为 `<待补充>`（由后续种子需求 Gate-3 填实）
4. 若路径已存在且非空：**跳过**创建，并**不**种子化「从零工程初始化」需求（见 Step 7）

**禁止**：在本步生成可跑业务工程或安装业务依赖。

### 7) 种子化工程基线需求（seed-bootstrap-reqs）

在 docs-render + skills-bootstrap + code-shell 判定之后，按条件从 `templates/docs/requirements/inbox-seed/` 渲染到 `docs/requirements/inbox/`。

| 文件（示例名） | 条件 |
| --- | --- |
| `<时间戳>-后端工程初始化.md` | 需要后端（默认是）且 backend 路径为空/新建（非已有非空工程） |
| `<时间戳>-前端工程初始化.md` | 需要前端=是 且 frontend 路径为空/新建 |
| `<时间戳>-本地运行与CI基线.md` | **需要数据库=是**（默认规则；用户 Manifest 显式勾选「生成运行基线」亦可） |

规则：

1. 命名取创建时刻 14 位时间戳 `<YYYYMMDDHHMMSS>`（同秒则后一篇 +1s；无需 counter/序号）
2. frontmatter：`类型: 技术`，`分级: 黄`，`状态: 待处理`，**`种子: true`**（供 capability-index 跳过种子）
3. 使用 inbox-seed 模板（含固定 AC）；占位符含路径与 `{{chosen_stack_summary}}`
4. **已有非空代码根**：不创建对应「从零初始化」种子；可选在 Init Report 提示后续用对齐类需求
5. **不**自动 `/xijia:start`；只落盘
6. Init Report 写明推荐顺序：后端 → 前端 → 运行基线；业务 PRD 须在工程基线 Gate-3 后再拆

### 8) 交付报告（Init Report）

至少包含：

- 初始化模式与 Guard 结论
- 创建文件/目录清单（含 code-shell、种子需求路径）
- AGENTS format: agents.md 标准区 + Xijia workflow 扩展
- 技术栈确认摘要
- 技能评分与安装结果
- 种子需求清单与推荐执行顺序
- 下一步：**明确** `/xijia:start docs/requirements/inbox/<时间戳-后端工程初始化>.md`（若无后端种子则指向实际首个种子或说明跳过原因）
- 提醒：工程基线完成并 Gate-3 后，再用 `xijia-prd-to-requirement` 拆业务 PRD；**勿**在 AGENTS 堆流程路由，日常入口为 `/xijia:start`

### 9) 自检（Self-Check，进入 done 前强制执行）

1. `requiredFiles`：最小交付集（同前；含 defect-template、lifecycle、ci 占位等）
2. `frontmatterValidity`
3. `entrypointAvailability`：含 `/xijia:start`、`/xijia:release`（无 `/xijia:scaffold` 独立命令）
4. `driftScan`
5. `policyFlowDrift`：`python .cursor/hooks/policy_flow_drift_check.py`
6. `agentsFormat`：根 `AGENTS.md` 含 `Build and test commands` 与 `Testing instructions` 章节标题（允许中英文副标题）；含 `Gate-1 切片 verify 顺序` 子节（可选检查 init 产出）

任一失败 → `blocked`，不得 `done`。

