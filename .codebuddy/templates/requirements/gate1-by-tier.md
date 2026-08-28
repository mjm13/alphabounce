# Gate-1 按分档落盘（PRD 阶段）

> 对齐 tysfrz：`/xijia:prd` **首次**写满 Gate-1；`/xijia:start` A.0.5 仅在 `--check-plan` fail 时增量补全。  
> 字段骨架见 [`.codebuddy/templates/requirements/gate1-plan-template.md`](gate1-plan-template.md)。  
> **绿 / 绿-轻量**：本文件落盘的 `## 实现方案`（含可执行切片）即 Gate-1 批准后的**唯一执行计划**；批准后按切片勾选推进，禁止另建 `docs/plans/` / `docs/superpowers/plans/`。

## 分档写什么

| 分级 | `## 页面布局预览` | `## 验收标准` | `## 实现方案` | frontmatter |
| --- | --- | --- | --- | --- |
| **绿** | 无原型+UI：ASCII 或参照现有页+差异；有原型跳过；无 UI：`不适用` | 满密度：覆盖要求 + 每条 In-Scope ≥1 条 `AC-*` + 反例；UI/状态机 GWT；约束引用衍生 `AC-UI-*` | 满密度：架构、复用四列表、影响面、**可执行切片**（见下）、交互语义、可执行回归命令、ADR 或「无」 | `分级`；`openspec变更` 留空 |
| **黄** | 同绿 | 同绿满密度 AC | 同绿字段；切片可用摘要级 `[AC-*]`（批准前允许 A.0.5 补可执行密度） | `分级`；`openspec变更` 留空 |
| **绿-轻量** | 无 UI：`不适用`；有 UI 同绿 | 可写 `不适用（green-trivial）` | 可与「实施与验证」合并：可执行切片（Files/Done 至少一项）+ **可执行**验证命令 | 声明无数据流 `(green-trivial)` |
| **红** | 无原型+UI：inbox ASCII 草案（OpenSpec design 可引用，不替代）；有原型跳过 | 仍写可执行 AC（GWT + 反例）；并注明与 OpenSpec `specs/` 对齐 | **首段说明 OpenSpec 路径与职责**（见下）；再写复用映射/切片/回归**草案**（无包时同黄档密度，使 `--check-plan` 可过）。批准后执行真相源为 OpenSpec `tasks.md` | **必填** `openspec变更: <kebab-case>` |

## 绿 / 绿-轻量：可执行切片（PRD 必写）

切片不得只写能力一句话（禁止仅有「表 + 按键读 API」而无 Files/Done）。每条切片映射 ≥1 个 `AC-*`，并含：

| 字段 | 要求 |
| --- | --- |
| `Files` | 将创建或修改的路径（可多条；来自 codegraph / 复用映射） |
| `Test` | 对应测试文件路径（无自动化时写原因 + 手工 Done 命令） |
| `Steps` | 一句话顺序：红测 → 最小实现 → 绿测（或等价） |
| `Done` | 可执行完成命令（须能出现在回归验证点中） |

```markdown
- 切片拆解：
  1. [AC-1]
     - Files: `backend/app/...` ; Test: `backend/tests/...`
     - Steps: 红测 → 最小实现 → 绿测
     - Done: `cd backend && pytest tests/... -q` 通过
  2. [AC-UI-1]
     - Files: `frontend/src/...`
     - Test: `frontend/...` 或 `webapp-testing` 场景名
     - Steps: 红测/失败断言 → 实现 → 复跑
     - Done: <Playwright 或组件测命令>
```

密度介于「摘要切片」与 `writing-plans` 全量 Task/Step 之间：批准后应能**直接按切片 TDD**，无需再拆计划。

## 红档实现方案首段（必写）

```markdown
## 实现方案
> **OpenSpec（红档）**：本需求 Gate-1 详细 design/tasks/specs 以 OpenSpec 包为准。
> - 变更名：`<openspec变更>`
> - 目录：`docs/openspec/changes/<openspec变更>/`（proposal / design / tasks / specs[/domain]）
> - 何时建包：`/xijia:start` 进入红档链路时执行 `openspec-propose`（若目录尚未存在）
> - 与本文关系：下文为落盘草案（复用/切片/回归）；包齐备后 `--check-plan` 可跳过本文内容校验，批准依据为 OpenSpec 产物；**实现按 `tasks.md` 执行**。

- 架构 / 关键改动：…
- 复用映射 / 代码落点：…（四列表）
- …
```

禁止只写空洞句「红档以 OpenSpec 产物为准（黄档无）」而不给路径、变更名与后续动作。

## 写入时机

1. **PRD Step 4 落盘**：与 Gate-0 同文件一次写齐。Gate-1 顺序：**4a** `## 页面布局预览`（无原型+UI）→ **4b** `## 验收标准` + `## 实现方案`（codegraph 探针结果回填复用表/影响面/**可执行切片 Files**）。
2. **A.0.5**：仅当 `--check-plan` 报缺字段或占位时增量 merge；**先**补布局预览（若缺且无原型有 UI）**再**补 AC/方案。禁止另建 `docs/plans/`。`--check-plan` 已过则**禁止**再跑 `writing-plans` 重写计划。
3. **refinement / Gate-0 回补**：**禁止**写满 Gate-1（只修 Gate-0）。

## 交接校验

```bash
python .codebuddy/hooks/pipeline_guard.py --check-intake --req <file>
python .codebuddy/hooks/pipeline_guard.py --check-plan --req <file>   # 绿/黄/无包红：期望 exit=0
```

intake 与 plan 均通过后提示 `/xijia:start <file>`（Gate-1 批准后按实现方案切片执行）。
