# 会话恢复、当前门禁与输出契约

## 阶段前置校验

- 🔴 apply 前：`docs/openspec/changes/<name>/` 须有 proposal、tasks、specs、domain（business/hybrid）
- `python .codebuddy/hooks/pipeline_guard.py --check-apply --change <name> --tier red`
- 绿黄：Gate-1 已批 + `--check-plan` 通过

## 会话恢复（摘要不可信）

1. 读 requirement frontmatter `分级`/`类型`
2. `python .codebuddy/hooks/pipeline_guard.py --audit`（仅用户说「展开诊断」时）
3. 文件证据优先于摘要 Stage
4. verify 三件套无记录 = 未完成
5. **漂移恢复**：代码已有但 Gate-1 待批 → 当前仅 Gate-1
6. 续聊：**必须** `--resolve-gate --req <path> --format cta`（用户已指定 path）；未指定则 `--resolve-gate --format cta` 仅提醒指定

## 当前门禁（不可跳级）

| 条件 | 当前门禁 | Agent 动作 |
|---|---|---|
| Gate-0 未 complete / 部分通过 / intake fail | Gate-0 | 加载 `xijia-requirement-refinement`（**仅 Gate-0**） |
| 红档 + openspec 包 scope/目录不匹配 | Gate-0 / OpenSpec | `openspec-propose` 新建 change + 更新 frontmatter |
| Gate-0 已通过且 `--check-plan` fail | Gate-1（方案缺口） | A.0.5 + `writing-plans` 增量补全 |
| Gate-0 已通过、plan OK、Gate-1 非已批准 | Gate-1 | 提请文字批准 |
| Gate-1 已批准且验收记录无执行证据 | **实现** | **同轮** OpenSpec apply / Gate-1 切片 TDD + verify（**禁止**反问是否开工） |
| Gate-2 非已验收且 verify 证据已写入验收记录 | Gate-2 | 提请验收签字 |
| Gate-2 已验收且在 inbox | Gate-3 | `xijia-sync-knowledge` |
| shipped + closeout pass | 无（待 commit） | — |

多篇 inbox 规则见 [`multi-inbox.md`](multi-inbox.md)。

## CTA 优先输出契约（默认）

**硬约束**：用户已指定 path 时：

```powershell
python .codebuddy/hooks/pipeline_guard.py --resolve-gate --req <path> --format cta
```

用户**未**指定 path 时：

```powershell
python .codebuddy/hooks/pipeline_guard.py --resolve-gate --format cta
```

| 块 | 规则 |
| --- | --- |
| **标题行** | `{子态含 Gate-x(中文)} · {需求简称}（{分级} · {类型}）` |
| **阻塞** | intake/plan/openspec/release fail 时出现；**无阻塞整段省略**（不写「无」） |
| **本步指令** | 默认可执行单行；与 **请你** 重复时省略（Gate-1 待批准只保留请你口令） |
| **请你 / 然后** | 各 1 行；**然后** mandatory，禁止删除 |
| **字段换行** | **UI 验收证据 / 本步指令 / 请你 / 然后** 之间必须空一行（否则 Markdown 合成一段） |
| **附录** | Gate-1 批准摘要 / full path / Gate-2 快速验收提示；可选 |

首屏 ≤8 行；长诊断（Tier Matrix、探针全文）归 `/xijia:status` 或用户说「展开诊断」。

### 示例：未指定 path

```markdown
## 请指定需求文档

进行中：901 系统参数设置 · Gate-1 | 902 系统字典管理 · Gate-1 | …

**请你：** 在 `/xijia:start` 后带上 inbox 路径或文件名，例如 `docs/requirements/inbox/20260806100901-系统参数设置.md`

**然后：** Agent 对该篇执行 `--resolve-gate --req <path> --format cta` 并照贴输出
```

### 示例：Gate-1 待批准

```markdown
## Gate-1(方案审核) 待批准 · 901 系统参数设置（黄 · 混合）

**UI 验收证据：** 本需求触达 UI。请在批准时声明档位（默认组件测试）。可选：Playwright / 集成测试。

**请你：** 审阅 Gate-1（页面布局预览 → 验收标准 → UI 验收证据约定 → 实现方案）后回复 → `批准 Gate-1` 或 `批准 Gate-1；UI验收证据: 组件测试|Playwright|集成测试`

**然后：** Agent 同轮切片 TDD → comment-sync → verify → 提请 Gate-2（不再问是否开工）

### 附录

- 需求路径：`docs/requirements/inbox/20260806100901-系统参数设置.md`
```

### 示例：Gate-0 阻塞

```markdown
## Gate-0(需求澄清) · 901 示例模块（黄 · 业务）

**阻塞：**
- 数据流未闭环 / AC-1 / 闭环状态: 待确认 → 补闭环表后重跑 `--check-intake`

**请你：** 确认歧义/OQ/闭环表断点（逐条文字回复）

**然后：** Agent 回写 Gate-0 → `--check-intake --req <file>` → 再输出 CTA
```

### 示例：Gate-1 方案缺口

```markdown
## Gate-1(方案审核) 方案缺口 · 902 字典管理（黄 · 混合）

**阻塞：**
- 缺 切片拆解 → Agent 执行 A.0.5 + writing-plans

**请你：** 无（Agent 继续）

**然后：** Agent 执行 A.0.5 + writing-plans 补 Gate-1 → `--check-plan` → 再输出待批准 CTA
```

### 示例：Gate-2 待验收

```markdown
## Gate-2(人工检查) 待验收 · 901 系统参数设置（黄 · 混合）

**漂移刷新：** 若 Gate-2 待验收期间 `git diff` 仍有 frontend/backend 变更，Agent **须**先刷新「验收记录」一屏验收包再提请签字；AC 文本与实现不一致时在验收记录加 **AC 漂移说明** 一行。

**本步指令：** 你：回复「Gate-2 验收通过，审批人 <git config user.name>，YYYY-MM-DD」

**请你：** 回复「Gate-2 验收通过，审批人 <git config user.name>，YYYY-MM-DD」（简写「验收通过」时 Agent 可补审批人，须在验收记录注明「签字格式 advisory：已按 git config 补全」）

**然后：** Agent 同轮更新 frontmatter Gate-2 → `--gate3-trigger-report` → `--check-gate3-preflight` → `xijia-sync-knowledge` → `archive-requirement.ps1` → `--check-closeout`（shipped 路径）；**禁止**签字后跑 `--check-release` 并停轮
```

### 门禁变体速查（本步指令 / 请你 / 然后）

| 子态 | **本步指令（摘要）** | **请你** | **然后** |
| --- | --- | --- | --- |
| Gate-0 | 你确认歧义 → Agent `--check-intake` | 确认歧义/OQ | 回写 → `--check-intake` |
| Gate-1 方案缺口 | Agent A.0.5 补方案 | 无（Agent 继续） | A.0.5 → `--check-plan` |
| Gate-1 待批准 | （省略，口令见请你） | `批准 Gate-1` 或带 UI验收证据 | 同轮 TDD → verify → Gate-2 |
| 实现中 | Agent verify + 填验收记录 + `--check-release` | 无（Agent 继续） | 切片 + verify + release |
| Gate-2 待验收 | 你回复 Gate-2 签字句 | `Gate-2 验收通过，审批人 …` | trigger-report → preflight → sync → Move → closeout |
| Gate-3 | Agent sync + Move | 无（Agent 继续） | trigger-report → sync → Move |
| 绿-轻量收尾 | 无（Agent 继续） | 按切片 verify → Gate-2 |
| 缺陷快路径 | 按 Gate-1/2 同上 | 绿档修复 + verify |
| 🧪 spike | 确认探针结论 | 非交付；重跑 Gate-0 或 Deferred |
| 红档 OpenSpec 不匹配 | 确认新 change 名 | propose → analyze → Gate-1 |
| Approval Gates 命中 | 文字批准（含目标库+操作） | 批准后继续当前门禁 |

> **Gate-1 → 实现 / Gate-2 → Gate-3 同轮链式**：用户文字批准/签字并落盘后，写 `**请你：** 无（Agent 继续）`，同轮执行 **然后** 行动作链；禁止二次口令。

### Gate-3 命令块（可复制）

顺序硬约束：**触发表 → 预检 → inbox 改状态与写总结 → Move**；`--check-closeout` 的 `--req` 必须是 **shipped** 路径。

```powershell
python .codebuddy/hooks/pipeline_guard.py --gate3-trigger-report --req docs/requirements/inbox/<file>.md
python .codebuddy/hooks/pipeline_guard.py --check-gate3-preflight --req docs/requirements/inbox/<file>.md
powershell -File scripts/archive-requirement.ps1 -InboxPath docs/requirements/inbox/<file>.md
```

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 手写 CTA 漏 **然后** | 未跑 `--format cta` | 必须照贴 guard stdout |
| CTA 字段挤成一段 | 相邻 `**label：**` 行无空行 | guard `--format cta` 字段间空一行；照贴勿删空行 |
| Gate-1 待批准本步指令与请你重复 | 两行都写审阅路径+批准口令 | 省略 **本步指令：**，只保留 **请你：** |
| Gate-1 批准后只确认留痕 | 误把批准当检查点 | **然后** 行含 TDD 链 |
| 无阻塞仍写「阻塞：无」 | 旧四段模板 | 整段省略阻塞 |
| 长诊断占首屏 | 默认展开 Intake/探针 | 仅 status / 「展开诊断」 |
| 多篇 inbox 批错需求 | start 未指定 path 却 auto-pick | 未指定时只跑 `--format cta` 无 `--req` |
| Gate-2 签字后只改 frontmatter 即结束 | 未链式 Gate-3 | 同轮 `--check-gate3-preflight` → sync → Move |
| Gate-2 **后**首次跑 `--check-release` 并停轮 | 误用 release 为 Gate-3 入口 | release 仅 Gate-2 **前**（步骤 4）；签字后 blocking 在 Gate-3 链内修 |
| 签字后追问「是否继续 Gate-3」 | 违反同轮链式 | CTA：**请你：无（Agent 继续）** |

## Approval Gates（命中即停）

破坏性 DB、清库、新关键依赖、下线能力、权限/密钥变更、跨 BC 大规模架构调整。阻塞段写「须文字批准：目标库+操作」；**请你**=批准句。
