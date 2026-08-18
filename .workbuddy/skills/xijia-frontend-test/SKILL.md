---
name: xijia-frontend-test
description: "Load when 写前端 AC 测前, UI Playwright, Gate-1 前端验收标准."
agent_created: true
---

# 目标

以 **红-绿-重构** 循环驱动前端实现：先写失败验证（RED），再写最小实现（GREEN），最后清理（REFACTOR）。实现前须有可失败的验证。

与 `openspec-superpowers-apply` 联动：每条 Gate-1 `AC-*` 须有对应测试或明确可运行验证命令，否则不得勾选任务。

# 栈无关测试门禁

## 1) 判定测试类型

> **档位 SSOT**：requirement frontmatter `UI验收证据`（Gate-1 用户确认；默认 **组件测试**）。见 `gate1-plan-template.md`「UI 验收证据约定」。

| AC 类型 | 验证手段 |
| --- | --- |
| 纯函数与数据转换 | 单元测试优先 |
| 无真实浏览器也可证伪的状态逻辑（store / 守卫） | 组件或 store 测试 |
| **UI 可见行为（默认档位：组件测试）** | **Vitest 组件测** + 验收记录写命令/结果 |
| **UI 可见行为（`UI验收证据: Playwright`）** | **强制 `webapp-testing`（Playwright）** |
| **跨页/全栈联调（`UI验收证据: 集成测试`）** | **with_server / parity / verify-frontend** |
| 语法 / 类型 / 构建 | `lint` + `build`（**单独不足作为 UI AC 证据**） |

Gate-1 待批准时 Agent 须 `AskQuestion` 询问是否需 Playwright 或集成测试；用户未确认则按组件测试执行。

## 2) 强制规则

- 前端行为与已确认契约一致（字段语义、错误语义、权限可见性）。
- 业务真值以后端为准；前端勿硬编码替代。
- 契约冲突时先升级规格/契约再改代码。
- **UI 可见 AC 的 Gate-2 证据**须匹配 `UI验收证据` 档位：默认 Vitest 组件测（exit 0 + 验收记录）；Playwright 档位须 `webapp-testing`；集成档位须联调命令。正式证据用可复跑脚本，不用口头点测或仅 `cursor-ide-browser` MCP。

## 3) 执行步骤（RED -> GREEN -> REFACTOR）

1. RED：先写失败验证。UI 可见 AC 的 RED = 失败 Vitest 用例（默认）或失败 Playwright 脚本（Playwright 档位）。  
   **完成：** 验证失败且对准该 AC。
2. GREEN：补最小实现使测试通过。  
   **完成：** 相关脚本/测试 exit 0。
3. REFACTOR：收敛重复，保持可读。  
   **完成：** 同一验证集仍 exit 0。

# Gate-1 切片 verify 顺序（实现阶段）

Gate-1 已批准且需求含可执行切片时，**须**按 [`AGENTS.md`](../../../AGENTS.md)「Gate-1 切片 verify 顺序」执行：

1. 禁止首个切片完成前全量 `pytest -q`（或等价全量命令）
2. 顺序：单文件/单模块测 → `npm run test -- <Spec>`（Vitest 档位）→ 最后全量 + `--check-ui-pattern`
3. pytest 前台运行（`block_until_ms` ≥ 90000）；禁止 `| Select-Object -Last N` 作为唯一输出
4. Vitest 档位禁止后台 `npm run dev`；Playwright/集成档位才用 `with_server` / parity

`init_db` / bootstrap 改动后先跑一个 DB smoke，再扩全量。

# webapp-testing 门禁

**仅当** frontmatter `UI验收证据: Playwright`（Gate-1 用户确认）时**必须**执行本节。

1. **加载技能**：Read `.cursor/skills/webapp-testing/SKILL.md`。  
   **完成：** 已按决策树选定路径。
2. **未安装则先安装**（落点 `.cursor/skills/webapp-testing/`）：
   ```bash
   npx skills add https://github.com/anthropics/skills --skill webapp-testing
   ```
3. **黑盒调用 helper**：先对 `scripts/with_server.py` 跑 `--help`。本项目联调：
   ```bash
   python .cursor/skills/webapp-testing/scripts/with_server.py \
     --server "cd backend && uvicorn app.main:app --host 0.0.0.0 --port 8080" --port 8080 \
     --server "cd frontend && npm run dev" --port 5173 \
     -- python <playwright_script.py>
   ```
4. **路径**：脚本 `frontend/e2e/*.py`；产物 `frontend/e2e/artifacts/`。
5. **验收留痕**：requirement 验收记录写明可复跑命令与证据路径。  
   **完成：** 命令 + 证据路径已写入验收记录。
6. **MCP 边界**：`cursor-ide-browser` 仅侦察；Gate-2 UI AC 证据以 `webapp-testing` 为准。

# 最小验收清单

- [ ] 每条 Gate-1 AC-* 至少有 1 个测试或明确验证命令
- [ ] 关键交互、异常路径、边界场景均覆盖
- [ ] API 契约对齐有可执行验证
- [ ] 回归可重复执行
- [ ] UI 可见 AC 证据匹配 `UI验收证据` 档位（默认：Vitest + 验收记录；Playwright/集成按档位）
- [ ] 未用 lint/build 或人工点测冒充 UI AC 通过

## Table-First 组件测（触发条件）

**当且仅当** Gate-1 `## 验收标准` 有 `AC-UI-*` **且** Gate-1「复用映射」含 `frontend/src/components/*Panel.vue` 时，组件测须覆盖（结构 SSOT：`docs/patterns/table-first-list-page.md` §结构门禁）：

| 维度 | 必断言 |
| --- | --- |
| 面板容器 | `.menu-panel` 存在 |
| 筛选栏 | `.menu-panel-head` 或 `.role-panel-head`，且 `.role-search-field` 存在 |
| 分页 | `.role-panel-foot__pager` 或 `data-testid="*-pagination"`（仅 `.role-panel-foot` 不够） |
| Drawer 打开 | 点击编辑/新增后 `.menu-drawer.is-on` 可见（禁止仅对屏外 Drawer `setValue`） |
| CRUD 链 | 保存后 mock API / 列表刷新 |
| builtin 保护 | 若 AC 提及：删除 disabled 或 409 路径 |

双面包屑：若 AC-UI 涉及页头，验收记录须说明壳层 `page-toolbar` 与 Panel `PageHeadBar` 不叠加（Gate-1 应含 `Dashboard 排除 TabId`）。

**完成：** 上表全勾且 `--check-ui-pattern` exit 0 后才勾选对应 tasks。

# 与本项目的关系（METRIC HUB）

- **前端根目录**：`frontend/`；UI 参考 DEMO；壳层 pattern 等路径以 **当前需求「约束引用」** 为准，不在本技能硬编码
- **静态回归**：`cd frontend && npm run lint && npm run build`
- **UI 运行时**：`powershell -File scripts/verify-frontend-parity.ps1`（或等价 with_server + e2e）
- **契约**：`frontend/src/api/` 与后端 auth/契约对齐

# 实现结束硬停（verify 前再提请 Gate-2）

当 `--resolve-gate` 返回 `current_gate=实现` 时：

1. 先跑 `cd frontend && npm run lint && npm run test && npm run build`（默认组件测试档位）；Playwright 档位再跑 `scripts/verify-frontend-parity.ps1` 或等价 e2e
2. 先把逐条 AC 结论与证据路径写入「验收记录」
3. 再跑 `--check-release` / `--resolve-gate`；仅当 `current_gate=Gate-2` 才 solicit 签字

**完成：** resolve 为 Gate-2 且验收记录非空，才提请 Gate-2。
