# 收尾门禁（9 步，顺序执行）

> 逐步操作见 [`verify-closeout.md`](verify-closeout.md)；本文件为 `00-workflow` 硬约束摘要。

1. **verify**：测试/构建有证据。
2. **注释同步**：触达核心业务代码须在写代码阶段调用 `xijia-comment-enhancer`；verify 跑 `--check-comment-sync`（见 `44-comment-sync.mdc`）。
3. **验收记录（一屏验收包，能力A）**：Gate-2 前由会话依据 `git diff` + verify 输出，在 requirement「验收记录」生成一屏验收包——变更文件（按模块）+ 逐条 AC 状态与验证命令&结果 + 遗留/风险/Deferred + 一条可复跑验证命令 + **产品层审查（引用 quality-judge）**。目标：验收人「读一屏 + 跑一条命令」即可签字。**技能层生成 Markdown，不新增 guard CLI**。`Gate-2: 待验收` 期间代码仍有变更时**须**刷新验收包；AC 与实现不一致加 **AC 漂移说明**。verify 后 Gate-1 `## 验收标准` 有自动化证据的 AC 标 `[~]`，Gate-2 签字后改 `[x]`（三态约定见 `gate1-plan-template.md`）。产品层段只粘贴 judge 结论，不二次生成 findings：

   ```markdown
   ### 产品层审查（引用 quality-judge）
   - Product Drift Verdict: <pass|advisory|blocked>
   - Findings: <粘贴 judge 的 Product Drift Findings 或「无产品漂移」>
   ```
4. **收尾聚合自检**：Gate-2 前 `python .codebuddy/hooks/pipeline_guard.py --check-release --req <file>`。若 Gate-2 前已有 blocking，应在提请 Gate-2 前尽量修复；若 Gate-2 签字后仍 blocking，**不得停轮**，在 Gate-3 链内修复后继续 Move。
5. **Gate-2**：用户人工验收签字后方可状态迁移/归档；回填审批人/日期。**Gate-2 签字与 Gate-3 启动须同一 Agent 回合**（禁止签字后反问「是否归档」）。
6. **Gate-3（强制）**：签字后**同轮**立即 `xijia-sync-knowledge`（非用户二次口令）。inbox 内子序硬约束：
   0. **触发表**：`--gate3-trigger-report --req <inbox>` → 会话「沉淀候选」+ inbox `### 沉淀候选（Gate-3）`（patterns 须人确认）。沉淀候选「跳过/未采用」项**不**单独触发 Experience Reuse 缺口（closeout 已豁免该区）；若实际读过 pattern 仍须在 Gate-3 正文写 `Experience Reuse: <path>（未采用）`。
   1. **预检**：`Test-Path` / `--check-gate3-preflight --req <inbox>`；inbox 不存在 → stop-and-report，**禁止 rebuild shipped**
   2. **改状态**（仍在 inbox）：frontmatter `状态: 已交付`；frontmatter `Gate-2:` → `已验收` + 审批人/日期
   3. **写总结/沉淀**（仍在 inbox）：「实现记录与沉淀（Gate-3）」机器标记 + 活文档增量 + **capability-map（18b，Move 前）**
   4. **Move**：`scripts/archive-requirement.ps1` 或 `Move-Item` inbox→shipped（**唯一**归档方式；**禁止** Cursor Write/StrReplace 写 shipped；**禁止** Move 前未改状态）
7. **过程归档自检**（`--req` 必须为 **shipped** 路径；若 `archive-requirement.ps1` 已跑过可复用）：
   - `python .codebuddy/hooks/pipeline_guard.py --check-closeout --req <shipped-file>`
   - `python .codebuddy/hooks/pipeline_guard.py --check-doc-anchors`
8. **commit**：代码 + Gate-3 产出由用户触发提交。
9. **Deferred**：`partial/reject` 项写入 `docs/requirements/backlog.md`。

未完成 1–9 不得开下一需求。「需求完成」= Gate-3 已执行且已提醒 commit；禁止口头完成。

## green-trivial 快路径（fast-path，减少 trivial 摩擦）

仅当 `分级=绿-轻量` 且已声明「本需求无数据流（green-trivial）」时适用；**不改变任何硬门禁与证据要求**，只压缩仪式：

1. **保留**：step 1 verify（须有可复跑证据）、step 2 comment-sync（触达核心代码时）、step 5 **Gate-2 人工签字**（不可省、不可自签）。
2. **合并 3–4 为精简验收**：一屏验收包压缩为「变更文件清单 + 逐条 AC 结论 + 1 条复跑命令」一小段即可；仍跑 `--check-release --req <file>`。
3. **合并 6–7 为单次收尾**：Gate-2 签字后同一轮内执行 `xijia-sync-knowledge`——**禁止扩写沉淀段**，保持模板预填：`Experience Reuse: none` + `Living Docs`/`Flow`/`Patterns`/`Pitfalls`/`Capability Index: no-op`（已改对应活文档时仍须诚实更新，不得 false no-op）→ inbox 改状态 → Move → 立即 `--check-closeout --req <shipped>` + `--check-doc-anchors`。即**用户只签一次**，sync 与 closeout 自检连续完成。
4. **不适用**：一旦发现涉及数据流/新增能力/跨 BC，即退出快路径，回到完整 9 步。
