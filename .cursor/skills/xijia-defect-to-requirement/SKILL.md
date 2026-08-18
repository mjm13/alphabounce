---
name: xijia-defect-to-requirement
description: "Load when /xijia:defect, 报缺陷, 登记bug, 缺陷转inbox."
---

# xijia-defect-to-requirement

## 目标

把缺陷现象转换为本项目可执行的缺陷需求文档：

- 落盘 `docs/requirements/inbox/<YYYYMMDDHHMMSS>-<缺陷简述>.md`
- 基于 `.cursor/templates/requirements/defect-template.md`
- frontmatter `类型: 缺陷`；默认 `分级: 绿` 或 `绿-轻量`
- 不实现代码；Gate-1 前勿改非文档代码

登记细节与输出模板：**必须** Read [`references/defect-registration.md`](references/defect-registration.md)。

## 与相邻入口

| 入口 | 何时用 |
| --- | --- |
| **`/xijia:defect`** / 本技能 | **新建**缺陷 inbox |
| `xijia-prd-to-requirement` | 从 PRD 新建功能需求 |
| `xijia-requirement-refinement` | 已有 inbox 上细化 Gate-0 |
| `/xijia:start` | 文档就绪后推进修复 |

## 触发判定

- 「报缺陷」「登记 bug」「缺陷转 inbox」或 `/xijia:defect`
- 提供复现步骤 + 错误现象（或等价）

若已在修代码且 inbox 尚无文档：先本技能落盘，再 `/xijia:start`。

## 前置约束

1. 先读 `00-workflow.mdc`、`45-requirement-intake.mdc`、`defect-template.md`
2. 仓库须已 init；否则提示 `/xijia:init`
3. Gate-1 批准前勿改非文档代码/迁移/依赖/配置

## 主路径

1. **必须** Read [`references/defect-registration.md`](references/defect-registration.md)，执行 Step 1–4（解析、codegraph、预检索、分级）。  
   **完成：** 分级已定；复现/期望齐或已 partial。
2. 按 Step 5 落盘（`xijia-safe-file-write`）。  
   **完成：** inbox 路径存在且 `verify_utf8.py` exit 0。
3. 按 Step 6：`--check-intake` 后交接 `/xijia:start`。  
   **完成：** intake exit 0 或 partial 已 stop-and-report；交接说明已输出。

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 跳过落盘直接修 bug | 无留痕 | 先 defect inbox + Gate-1 |
| 缺陷文档写成 PRD 长篇 | 模板误用 | 保持 defect-template |
| 默认升 red | 过度分级 | 单点修复绿/绿-轻量 |
