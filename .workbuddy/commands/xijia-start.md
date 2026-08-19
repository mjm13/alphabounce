---
name: /xijia-start
id: xijia-start
category: Workflow
description: Xijia unified R&D entrypoint (tiering -> type -> execution loop)
---

Use `xijia-ops-pipeline` as the single orchestration entry for this request.

## Goal

Run the requirement through a complete and consistent workflow with mandatory human-review stop gates:

1. Tiering: `green | green-trivial | yellow | red`
2. Change type classification: `business | technical | hybrid`
3. Route to the right pipeline branch
4. Enforce closeout (all tiers run xijia-sync-knowledge; `--check-closeout`; red additionally archive)

## Related commands (not this entry)

| Command | When |
| --- | --- |
| `/xijia:init` | Empty repo bootstrap |
| `/xijia:adopt` | Historical multi-module adoption |
| `/xijia:overview` | Project snapshot |
| `/xijia:backfill-index` | One-time capability-map bootstrap |
| `/xijia:defect` | Register bug → inbox |
| `/xijia:release` | Batch release dev→main |
| `/xijia:status` | Lightweight snapshot only |

## Input

The argument after `/xijia:start` can be:

- A requirement description
- An existing change name
- A path to an inbox requirement (active-req)
- A request to continue current work

## Mandatory behavior

- Always follow `.cursor/rules/00-workflow.mdc`
- Always invoke and follow `xijia-ops-pipeline`
- **续聊/输出 start 回复前必须**（硬约束）：

**用户已指定 inbox path/文件名时：**

```powershell
python .cursor/hooks/pipeline_guard.py --resolve-gate --req <path> --format cta
```

以 stdout **作为回复正文**（可追加 `### 附录`）；禁止从零手写 CTA；**禁止**输出「另有 N 篇 inbox」等多篇噪音。

**用户未指定 path 时：**

```powershell
python .cursor/hooks/pipeline_guard.py --resolve-gate --format cta
```

仅输出「请指定需求文档」提醒 CTA（含一行 inbox 摘要）；**禁止**自动选篇、禁止输出单篇 Gate 进度/附录。

- **Gate-0 verdict 前必须先** `--check-intake`；exit≠0 不得标「已通过」（机器 exit 优先于文档自评）
- Gate-0 通过后：`--check-plan`；fail → A.0.5 + writing-plans（无非文档代码变更）
- Gate-1 文字批准后 **同轮** 实现；`**请你：** 无（Agent 继续）`；禁止问「是否开始实现」
- Gate-2 签字后 **同轮** Gate-3；禁止同回合 solicit 多 Gate
- verify：`--check-comment-sync`；`xijia-quality-judge`；Gate-3：`xijia-sync-knowledge` + `--check-closeout`
- **Single-gate UX**：每回合仅 solicit 当前门禁；禁止把 `--audit` 全文当用户 checklist
- 长诊断（Tier Matrix、探针）仅当用户说「展开诊断」或 `/xijia:status`

## Output format

**CTA 优先**（见 `session-recovery.md`）。guard `--format cta` 已含标题 + **请你** + **然后**（字段间空一行；**本步指令：** 与请你重复时省略）；Agent 照贴，可补附录。

禁止：外层 markdown 围栏；HTML `<details>`；无阻塞时写「阻塞：无」；删除 **然后** 行；删掉 CTA 字段间空行；未指定 path 时输出单篇 Gate CTA。

Gate-2 AC 表放 `### 附录` 或附录之后，不能代替 **然后**。多篇规则见 `multi-inbox.md`（start 不 auto-pick）。
