# Gate-0 闭环执行细节（Phase 0–3）

进入细化对话/回写前**必须** Read 本文件。程序字段细节另见 [`.codebuddy/templates/requirements/gate0-intake.md`](../../templates/requirements/gate0-intake.md)。

## Phase 0：加载与初评（只读）

1. 读取目标 requirement 全文 + frontmatter；核对 Gate-0「原始诉求」与歧义登记。
2. 读取关联 PRD 片段、触达 BC 的 patterns/pitfalls/domain。
3. codegraph 探针（触达前后端时）：术语→实体、可复用落点（供后续 A.0.5，本技能不写进 Gate-1）。
4. 跑 intake（不阻断对话）：
   ```bash
   python .codebuddy/hooks/pipeline_guard.py --check-intake --req docs/requirements/inbox/<file>.md
   ```
5. 输出 Re-eval 摘要（见下方模板）。

**完成：** Re-eval 摘要已输出；P0 Gate-0 缺口已列出。

## Phase 1：brainstorming 式细化

按 brainstorming：**一次只问一个**；优先选择题。

| 触达面 | 优先问题 |
| --- | --- |
| 通用 | Q0 原话歧义；范围 In/Out；OQ/闭环断点 |
| UI / 状态机 | 列表列与按钮；初态/末态；可关闭/可恢复会话 |
| 外部集成 | 数据来源；本地 vs 外部字段；读/写路径；同步语义 |

**完成：** 用户已回答当前断点；未改代码、未写满 Gate-1。

## Phase 2：回写（用户批准后）

回写前加载 `xijia-safe-file-write`。仅更新 Gate-0 相关：

| 章节 | 更新内容 |
| --- | --- |
| YAML properties | 必要时修订分级/类型、DDD 主类与 Gate-0 日期 |
| 原始诉求 / 歧义登记 | 原话保留；多义片段记读法、结论、确认人/日期 |
| 业务目标 / 用例 | 业务/混合非空；技术/缺陷可写不适用 |
| 范围与切片 | 背景、In/Out/Deferred；In Scope 只写能力边界 |
| 领域影响 | 业务/混合：BC、术语、INV |
| 约束引用 | patterns/pitfalls/ADR；无则 `约束引用: none` |
| `OQ-*` | 每条闭合：`结论 + 确认人 + 日期` |
| 数据流闭环表 | 断点清零则 `verdict: 已通过` |
| 原型对齐与偏离 | 已确认口径与 Deviation 审批 |

勿写满 Gate-1「验收标准」/「实现方案」；勿删除 Gate properties；勿在无用户确认时把 `[待确认]` 写成确定结论。

**完成：** Gate-0 章节已回写；`verify_utf8.py` exit 0。

## Phase 3：自检与交接

```bash
python .codebuddy/hooks/pipeline_guard.py --check-intake --req <file>
```

intake OK → 下一步 `/xijia:start`（Gate-1 已满则提请批准；`--check-plan` fail 则 A.0.5）。本技能不提请 Gate-1、不调用 writing-plans。

**完成：** `--check-intake` exit 0；交接说明已输出。

## Re-eval 报告模板

```markdown
## 需求 Re-eval：<标题>

### Gate-0
- 机器校验：intake（pass/fail）
- verdict 建议：已通过 | 部分通过 | 已驳回

### P0 缺口（Gate-0 必补）
- ...

### 下一步
- 补 Gate-0 / `/xijia:start`（A.0.5 仅 plan 缺口时）
```

## 外部集成触达面清单

- [ ] SQL 读 / HTTP 写凭证分离
- [ ] 冗余字段与同步水位
- [ ] 改绑后：同步状态 ≠ 触发执行
- [ ] Spike：外部列名在环境验证
