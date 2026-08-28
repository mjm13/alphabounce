# verify 与 closeout 子流程

## E.0 apply-time comment-sync

编辑核心业务文件前判定触发范围 → 调用 `xijia-comment-enhancer`（新增即写、修改即更新 `[修改记录]`）。不得推迟到 verify。

## E. verify

0. **实现中（Gate-1 切片）**：按 [`AGENTS.md`](../../../../AGENTS.md)「Gate-1 切片 verify 顺序」——单文件/Spec 测优先，**禁止**首个切片未完成前全量 `pytest -q`；测试命令前台执行。
1. **Pattern 对照自检**（改 `frontend/src/components/*Panel.vue` 时，**跑测试前**）：对照 **该需求「约束引用」已列 pattern** + Gate-1 复用映射 **参照 Panel**，输出骨架对照表到终端/PR（不写回 inbox）。未通过 → 不得 `--check-release`。
2. `verification-before-completion`
3. 前端能力变更必须执行 `xijia-frontend-test`；UI 可见行为须按 frontmatter `UI验收证据` 档位留可复跑证据（默认 **组件测试** = Vitest；用户 Gate-1 确认 Playwright/集成测试时按档位），lint/build 不得代替运行时证据
4. Table-First Panel 变更：`python .codebuddy/hooks/pipeline_guard.py --check-ui-pattern [--base HEAD]`
5. `python .codebuddy/hooks/pipeline_guard.py --check-comment-sync`
6. 未触达核心业务：声明 `Comment Sync: skipped — <原因>`
7. 代码评审：🔴 强制 `requesting-code-review`；绿黄跨模块/API/权限则建议
8. `xijia-quality-judge`：🔴 revise 阻断；绿黄 advisory。输出须含 **Product Drift Findings**（见 skill rubric 维度 8–10）；code-review 保持技术向，不重复产品层检查
9. Gate-2 前：在 requirement「验收记录」生成**一屏验收包**（能力A，技能层 Markdown，非 guard）——变更文件(按模块) + 逐条 AC 状态、证据类型、证据出处与结果 + **Pattern 合规**（对照需求约束引用 path + `--check-ui-pattern` 结果）+ 遗留/风险/Deferred + 一条可复跑命令 + **产品层审查（引用 quality-judge，粘贴 Product Drift Findings，不二次生成）**；未执行 AC 不得标「通过」。**同一条可复跑命令须同步写入会话输出的 `### 下一步命令（Agent）`**（见 `session-recovery.md`）。
   - **漂移刷新**：`Gate-2: 状态:待验收` 期间若相对上次验收记录写入仍有 frontend/backend 代码变更，**须**刷新一屏验收包后再提请 Gate-2；AC 文本与实现不一致时加 **AC 漂移说明**（如「AC-UI-8 列定义已调整，以 diff 为准」）。
   - **三态勾选**：verify 通过后，Gate-1 `## 验收标准` 中有自动化证据的 AC 改为 `[~]`（程序已检）；无自动化覆盖的保持 `[ ]`；**禁止** Gate-2 未签字时标 `[x]`。Gate-2 签字同轮将全部 AC 改为 `[x]`。
10. Gate-2 前：`python .codebuddy/hooks/pipeline_guard.py --check-release --req <file>`。若 Gate-2 前已有 blocking，应在提请 Gate-2 前尽量修复；若 Gate-2 签字后仍 blocking，**不得停轮**，在 Gate-3 链内修复后继续 Move。

## Gate-2 签字后同轮 Gate-3

Gate-2 留痕后 **同轮**输出 Gate-3 执行摘要（trigger/preflight/sync/Move/closeout），禁止仅回复「下一步请确认 Gate-3」。`--check-release` 不得在 Gate-2 后作为停轮理由；blocking 在 Gate-3 链内修复。

## 完成判定

1. 验证通过 2. comment-sync 完成或合法跳过 3. xijia-quality-judge 留痕 4. AC 有验证
5. 人工验收说明 6. Gate-2 签字 7.「实现记录与沉淀（Gate-3）」已回填且 closeout exit=0 8. commit 状态明确

需求完成 ≠ 可发布（另走 F. 发布路由）。

## C. 放弃

`xijia-abandon-change`：回滚代码与数据影响，requirement 的 Gate-1 重置为「待批准」；不建 `dropped/`、不改 `inbox/README`；不污染 `docs/domain`。

## 可选增强

- `using-git-worktrees`：🔴 长周期或并行需求
- `review-security`：权限/密钥/破坏性 DB/新外部依赖
