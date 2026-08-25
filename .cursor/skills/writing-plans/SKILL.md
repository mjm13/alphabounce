---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Xijia project override（`xijia-ops-pipeline` / `/xijia:start` 触发时）

当由 **A.0.5 Plan 探针**或绿/黄档 pipeline 调用本技能时（**缺口补全**，非 PRD 首次起草）：

- **前置**：`/xijia:prd` 应已按分档写过 Gate-1（见 `.cursor/templates/requirements/gate1-by-tier.md`）。**仅当 `--check-plan` fail** 才进入本技能；exit=0 时禁止调用（绿/绿-轻量计划已是批准后唯一执行源）。
- **禁止**写入 `docs/superpowers/plans/` 或 `docs/plans/`。
- **必须**将计划 **增量 merge** 进当前 requirement 文档 Gate-1；顺序：**先** `## 页面布局预览`（若 Gate-0 无原型、数据流前端入口 ≠ `—`、且文档缺该节）**再** `## 验收标准` + `## 实现方案`；骨架见 `.cursor/templates/requirements/gate1-plan-template.md` / `.cursor/templates/requirements/section-fragments.md`。
- 探针级内容（`复用映射/代码落点`、`影响面与回归范围`、`切片拆解`、`回归验证点`）若已存在则**补缺**，勿整节覆盖、勿重复粘贴 Gate-0 闭环表。
- **验收标准**：每条 In-Scope 能力 ≥1 条 `AC-*` +「反例（本 AC 排除）」；UI/状态交互至少一条 GWT。
- **实现方案**补齐：`切片拆解`（绿/绿-轻量补成可执行切片：Files/Test/Steps/Done；黄可先摘要）、`回归验证点`（含 `pytest` / `npm run build` 等可执行命令）。
- **禁止**占位：「红档以 OpenSpec 产物为准（黄档无）」无路径、「待填充」「TODO/TBD」。红档无包时同黄档写满；红档须保留 OpenSpec 说明段。
- 完成后运行 `python .cursor/hooks/pipeline_guard.py --check-plan --req <file>` 直至 exit=0，再提请 Gate-1。

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

If critical unknowns block decomposition (e.g., data source undefined, prototype mismatch unresolved, acceptance shape unclear), do NOT force a fake implementation plan. Create a short **spike task block** first and mark implementation tasks as blocked until spike evidence is available.

### Spike-first rule for plans

- Detect unknowns early during scope/file-structure pass.
- Add a dedicated pre-task:
  - Goal
  - Timebox
  - Minimal experiments
  - Evidence expected
  - Exit criteria (`continue` / `partial` / `reject`)
- Only then create implementation tasks for confirmed scope.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review
