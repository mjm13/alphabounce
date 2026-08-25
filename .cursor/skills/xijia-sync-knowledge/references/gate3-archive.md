# 活文档、归档与 closeout（步骤 14–20）

进入归档前**必须** Read 本文件。写文档前**必须**加载 `xijia-safe-file-write`。

## 14. 活文档增量修正

命中即改；未命中在「实现记录与沉淀（Gate-3）」写 `Living Docs: no-op`。

| 文档 | 何时改 |
| --- | --- |
| `README.md` | 技术栈摘要、快速开始；须与 `docs/architecture.md` 一致（栈 reversal 须更新，勿写 no-op） |
| `AGENTS.md` | dev/build/test/deploy、栈版本、安全边界、提交约定（**有限度追加**，见下） |
| `docs/README.md` + `docs/llms.txt` | 文档树或「先读什么」；`llms.txt` 只链活文档 |
| `docs/openspec/config.yaml` | 栈/后端根变化时更新 `context` |
| `docs/capability-map.md` | 业务/混合默认更新（见 18b）；否则 `Capability Index: no-op` |
| `docs/flow.md` | 业务主流程变化才更新；否则 `Flow: no-op` |

清除失效链接与已删命令引用。

**`AGENTS.md` 追加限度**（每轮全量进上下文）：先就地替换同一事实再考虑新增；仅单一领域/阶段需要的内容写入对应 doc 或 rule、此处只留一行指针；新增 ≥3 行时同轮评估能否下沉等量旧内容。细则见 `docs/process/knowledge-maintenance.md`「AGENTS.md 追加限度」。

**完成：** Living Docs / Flow / Capability Index 标记与 git 触及面一致。

## 15. 代码↔文档漂移

轻量检查 delta spec vs domain/capability-map；guard 有 drift 提醒时在「实现记录与沉淀」写处置结论。

**完成：** 无未处置 drift，或已记录结论。

## 16. Experience Reuse 判定事件

对主文步骤 3 识别的每篇经验文档（一篇一条）：

```bash
python .cursor/skills/xijia-docs-score/scripts/score_docs.py --judge-doc <doc-path> --judge-session <需求stem> --judge-verdict useful|neutral|misleading --judge-reason "<reason>"
```

**完成：** 每篇命中文档均有 judge 事件，或清单为空。

## 17. docs 卫生评分（可跳过）

全量 `score_docs.py` 改在 `/xijia:release` 或周度执行。

**完成：** 跳过或已执行。

## 17.0. Gate-3 触发表（硬停，写沉淀前）

```bash
python .cursor/hooks/pipeline_guard.py --gate3-trigger-report --req <inbox-path>
# JSON：追加 --json
```

- 输出 A 强制 / B 建议 / C 可 no-op；B 类 patterns/pitfalls **须人确认**后再写盘。
- 会话与 inbox 须写 **`### 沉淀候选（Gate-3）`** 表格（待确认→已确认/跳过）。

**完成：** 报告已跑；B 类已确认或显式跳过。

**Table-First / 新 Panel 写盘自检（更新 `docs/patterns/*` 时）：**

- [ ] `frontend-butter-shell`：Dashboard `page-toolbar` 与 Panel `PageHeadBar` 互斥、TabId 排除清单
- [ ] `table-first-list-page`：`menu-panel` 包裹筛选+表+foot；`menu-page-toolbar` + PageHeadBar 单行说明；foot 含 `role-panel-foot__pager`；`.guard.yaml` 与 §结构门禁 同步
- [ ] `standard-page-checklist`：上述检查项已列入
- [ ] `docs/patterns/README.md` 索引已同步，便于下轮 `constraint-discovery` 命中

**公共/共享层写盘自检（触发表命中 `backend/app/common/` 或 `frontend/src/composables/` 建议且确认沉淀时）：**

- [ ] pattern 含「何时使用 / 整套能力落点（层→路径表）/ 第二业务接入步骤 / 反例」四段（对照 `async-job-progress.md` 结构）
- [ ] 与既有 pattern 的边界写清（例：长时异步 vs `global-loading-overlay` 互斥）
- [ ] `docs/patterns/README.md` 索引已加行

## 17.5. Gate-3 预检（硬停，Move 前）

```bash
# PowerShell
Test-Path docs/requirements/inbox/<file>.md
# 或
python .cursor/hooks/pipeline_guard.py --check-gate3-preflight --req <inbox-path>
```

- 勿用 Cursor `Glob`/`Read` 对 `docs/requirements/shipped/` 的空结果判定「不存在」（`.cursorignore`）。
- inbox 不存在 → stop-and-report（附 `git status --short docs/requirements/`、`--resolve-gate`）；须用预检恢复，勿会话全量重建 shipped，勿 Task 子 Agent 重写全文。

**完成：** preflight exit 0 且 inbox 路径存在。

## 18. 过程文档归档（inbox 内三步，Move 最后）

1. 加载 `xijia-safe-file-write`（OS 分支 + Gate-3 标记 + `verify_utf8.py`）。
2. **inbox 改状态**（Write/StrReplace）：`状态: 已交付`；`Gate-2:` → `已验收` + 审批人/日期（= git user.name）。
3. **inbox 写总结**：补全验收记录；回填 Experience Reuse / Living Docs / Flow / Patterns / Pitfalls / Capability Index / **Domain**；**须含 `### 沉淀候选（Gate-3）`（步骤 0 预填，人确认后更新）**；同步活文档（步骤 3–16 / 14）。`Domain:` 若领域影响含 INV，路径须含 `docs/domain/<bc>/domain-model.md`（见 domain-merge §11b）。归档前：
   ```bash
   git status --short docs/capability-map.md docs/flow.md
   ```
   若 untracked 或本次触及：写 `updated（修订记录；…）`（说明内勿含子串 `no-op`），勿写对应 no-op。**本步完成 18b（Move 前）**。
4. **归档移动（唯一方式）**：
   ```bash
   powershell -File scripts/archive-requirement.ps1 -InboxPath docs/requirements/inbox/<file>.md
   ```
   对 shipped：用 Move / 脚本归档；改 shipped 正文用 Python（见 safe-file-write）。须完成步骤 2–3（含 18b）再 Move；Move 后勿再改 Gate/状态。
5. `python .cursor/skills/xijia-safe-file-write/scripts/verify_utf8.py <shipped-path>`（脚本已跑且 exit 0 可跳过）
6. `python .cursor/hooks/pipeline_guard.py --check-closeout --req <shipped-path>`（`--req` 必须为 shipped）
7. `python .cursor/hooks/pipeline_guard.py --check-doc-anchors`

红档 OpenSpec：确认已 archive 至 `docs/openspec/changes/archive/<name>/`。spike 长文移入 `docs/archive/spikes/` 或随 requirement 归档。

**完成：** shipped 路径存在且步骤 5–7 可复用或已 exit 0。

## 18b. capability-map 动态合并（Move 前，挂 18.3）

`类型=业务|混合` 且非 `green-trivial`；否则写 `Capability Index: no-op`。

```bash
python .cursor/hooks/extract_capability_index.py --req docs/requirements/inbox/<file>.md --dry-run
# 确认后去掉 --dry-run；行主键 moduleKey+前端入口；勿 blind append
```

- 闭环表缺「前端入口/相关表」时，可用 comment-sync 的 `[业务菜单]`/`[涉及数据表]` 补列。
- `--json` 的 `cross_module_hints` → `context-map.md` Relationship Matrix **UPDATE**；沉淀段须一行人工确认（Pattern 默认 Conformist）。
- 能力下线：行 `状态=已废弃`（DEPRECATE）。

**完成：** dry-run 已审且落盘（或显式 no-op）。

## 19. closeout 自检

若 18 的 5–7 已由 `archive-requirement.ps1` 跑过且 exit 0，可复用。

```bash
python .cursor/hooks/pipeline_guard.py --check-closeout --req <shipped-requirement-path>
python .cursor/hooks/pipeline_guard.py --check-doc-anchors
```

exit≠0 → 勿宣告完成、勿开下一需求。

**完成：** 两命令 exit 0。

## 20. Commit 提醒

commit 由用户触发；未 commit 勿进入下一需求。

**完成：** 已向用户提示 commit。
