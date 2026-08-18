# 缺陷登记细节（Step 1–6）

落盘缺陷 inbox 前**必须** Read 本文件。骨架：`.cursor/templates/requirements/defect-template.md`。

## Gate-0 简化（缺陷专用）

满足以下即 `complete`（不必填完整数据流闭环表）：

- 复现步骤（GIVEN/WHEN/THEN 或等价）
- 期望行为
- 至少一条 Gate-1 验收标准 AC
- 发现环境（dev/staging/prod）

正文写「缺陷修复无新增数据流」可触发 guard 简化；若改变 Source/Process/Sink，则填 Gate-0 数据流闭环表。

缺复现或期望、无法形成 AC → `partial`，列出缺失项并 stop-and-report。

## Step 1：解析缺陷报告

抽取：现象、复现与环境、期望、版本/trace/日志、是否 hotfix（基于 `main` 修 prod）。  
AskQuestion 一次最多补 1–2 个关键缺口。

**完成：** 复现 + 期望 + 环境已齐，或已标 partial 缺口。

## Step 2：codegraph 落点（推荐）

MCP 可用时：症状 → 候选类/函数/文件；引用扫描（共享模块 ≥2 引用者标回归风险）。回填 Gate-1 实现方案复用映射 / 回归点。  
MCP 不可用：标 `[MCP不可用]`，留人工候选；勿伪造路径。

**完成：** 落点已填或已标 MCP 不可用/跳过。

## Step 3：知识预检索

按触达文件/BC 检索 `docs/pitfalls/`、`docs/patterns/`；命中写入约束引用或回归点；未命中写 `约束引用: none`。  
不执行 `score_docs`（Gate-3 再对 Experience Reuse 命中 path `--judge-doc`）。

**完成：** 约束引用行已写。

## Step 4：分级判型

- 类型：固定 `缺陷`
- 分级：默认 `绿`；纯配置/文案/样式单点 → `绿-轻量`（写「本需求无新增数据流（green-trivial）」）
- 跨 BC / 核心业务重构 → stop-and-report，建议升黄/红或拆需求

**完成：** 分级/类型已写入 YAML 理由字段。

## Step 5：落盘 inbox

1. 复制 `defect-template.md` 为骨架（不移动模板）
2. 14 位时间戳 `<YYYYMMDDHHMMSS>`
3. 路径：`docs/requirements/inbox/<YYYYMMDDHHMMSS>-<缺陷简述>.md`
4. YAML：基础字段 + `分级理由`、`类型判型结论`、`DDD主类: D`
5. 填 Gate-0 复现与期望 / 范围 / 数据流（或无新增声明）及 Gate-1（无原型+UI 触达时 **`## 页面布局预览`** → `## 验收标准` + `## 实现方案`；规则见 `.cursor/templates/requirements/gate1-plan-template.md` / `section-fragments.md` § Gate-1 / 页面布局预览）；勿另建独立 H1 验收标准
6. Gate-0/1/2：Gate-0 为 complete 或 partial；Gate-1/2 待批/待验，签字时回填 git 身份与日期

回写前加载 `xijia-safe-file-write`。

**完成：** 文件存在且 `verify_utf8.py` exit 0。

## Step 6：校验与交接

```bash
python .cursor/hooks/pipeline_guard.py --check-intake --req <file>
```

```markdown
缺陷文档已落盘：<path>
下一步：`/xijia:start <path>` 进入修复链路（Gate-1 批准后开始改代码）
```

hotfix：提醒合入 `main` 后必须回合 `dev`（`46-git-branching.mdc`）。

**完成：** intake exit 0（或 partial 已 stop-and-report）；交接说明已输出。

## 输出格式

```markdown
## 缺陷登记状态

- 文件: docs/requirements/inbox/<YYYYMMDDHHMMSS>-<简述>.md
- 完整性: complete | partial
- 分级: 绿 | 绿-轻量
- 类型: 缺陷
- Hotfix: 是 | 否
- Codegraph: 完成 | MCP不可用 | 跳过
- Gate-0: complete | partial（缺失：<…>）
- 下一步: /xijia:start <file>
- 阻塞项: 无 | <列表>
```
