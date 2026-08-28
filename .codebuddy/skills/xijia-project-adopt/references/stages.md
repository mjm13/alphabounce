# Adopt 执行步骤（SOP）

由 [`../SKILL.md`](../SKILL.md) 渐进披露。

## 执行步骤（SOP）

### scaffold

1. Guard + Interview
2. docs-render：复用 `xijia-project-init/templates/`（mode=adopt）；跳过 code-shell / seed
3. 写入 `docs/workspace-manifest.yaml`（自 `templates/workspace-manifest.yaml.tmpl`）
4. 写入 `docs/decisions/0002-project-adoption.md`
5. 渲染 `.cursorignore`（`templates/.cursorignore.adopt.tmpl` + 模块 path 行）
6. 追加 `.gitignore` snippet（若无则创建）
7. skills-bootstrap（同 init，≤10）
8. `adopt.stage=scaffold`
9. self-check 子集：requiredFiles、policy_flow_drift

**Next**: `/xijia:adopt preflight`

### preflight

```bash
python .codebuddy/hooks/scan_workspace.py --preflight-codegraph [--dry-run] [--skip-codegraph]
```

1. L0 模块发现 → 预填 manifest.modules（draft）
2. codegraph CLI 检查；缺失 → Approval Gate 安装
3. 逐 backend/frontend 模块：`codegraph init --path <module>`（用户批准后）
4. 渲染 `.codebuddy/mcp.json`（`codegraph-<moduleKey>` per ready module）
5. `adopt.stage=preflight`
6. init_failed 且无豁免 → blocked

**Next**: `/xijia:adopt discover`

### discover

```bash
python .codebuddy/hooks/scan_workspace.py --discover [--skip-codegraph]
python .codebuddy/hooks/scan_workspace.py --ddd-discovery
```

产出：

- `docs/.generated/adopt-discovery.json`
- `docs/.generated/ddd-discovery.json`
- `docs/workspace-manifest.yaml`（modules/commands draft）
- `docs/architecture.md`（draft）
- `docs/capability-map.draft.md`
- `docs/domain/_draft/**`（术语表已分层：主表=核心聚合+关键支撑；基础设施/DTO 折叠附录不丢弃。分类见 `ddd-discovery.json.classification_summary`；实体扫描覆盖 Java `@Entity` 与 Python `models.Model`）
- `docs/flow.draft.md` + `docs/.generated/adopt-entrypoints.json`（行为驱动业务流程草稿：从 API/任务/命令入口生成，每条带 anchor 与 `[待确认：调用链]` 占位，**不臆造**；确认后合入活文档 `docs/flow.md`）

**secrets**：禁止读 `.env*`；discovery.json 不含 secret。

**Next**: `/xijia:adopt content`（stop-and-report）

### content

**分批置信确认（避免 big-bang）**：不得一次性要求用户确认全部术语/流程。按批推进：

- 每批 **≤10 个核心术语（聚合优先，再关键支撑）+ ≤1 条主流程**，逐批 stop-and-report 请用户确认。
- 基础设施/DTO 折叠项默认不逐条确认；用户按需展开附录。
- **`[待确认]` 不得由 Agent 自行提升为已确认**——只有用户明确确认（文字/勾选）才将该术语/流程 `status` 提升；未确认项保留 `[待确认]` 并可跨批延续。
- 每批可只覆盖某 BC 的一部分（**partial-BC**）；不要求一次填满整个 BC。

步骤：

1. 展示 confidence:low、DDD 冲突、codegraph 失败项；标注本批范围（哪个 BC、哪些术语、哪条流程）
2. 用户逐批确认 primary、命令、BC/术语/Pattern/主流程
3. 已确认项 `discovery.status=confirmed`；reject → `rejected`；未确认保留 `[待确认]`
4. DDD `_draft/` → `docs/domain/`（propose-not-mint，仅迁移已确认项）；`flow.draft.md` 已确认流程归并 → `docs/flow.md`
5. 同步 AGENTS Layout + Build commands
6. `adopt.stage=content`（可多轮；全部批次完成前保持 content）

**Next**: `/xijia:adopt verify`

### verify

```bash
python .codebuddy/hooks/pipeline_guard.py --check-adopt-readiness
python .codebuddy/hooks/policy_flow_drift_check.py
python .codebuddy/hooks/pipeline_guard.py --check-doc-links
```

1. 输出 Adoption Readiness Report（L1/L2/W*）
2. 推荐 L3：`--check-intake` on pilot inbox req
3. stop-and-report → **Adoption Gate** 文字签字
4. 写入 `docs/process/adopt-readiness.md`
5. `adopt.stage=done`

**Next**: `/xijia:prd` 或 `/xijia:start`

