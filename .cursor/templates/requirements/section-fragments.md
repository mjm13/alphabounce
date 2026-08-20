# 需求文档按需片段

主模板只保留各 Gate 的最小可解析骨架。命中以下场景时，将对应片段插入所属二级环节；未命中不要保留空表。

## Gate-0 / 歧义登记

多义表述必须列出至少两种读法，并由用户文字确认。静态原型不能确认动态行为。

```markdown
| 原话片段 | 读法A | 读法B | 消歧证据 | 结论 | 确认人/日期 |
|---|---|---|---|---|---|
| `<原话>` | `<读法A>` | `<读法B>` | 用户文字确认 / 既有行为 / ADR | [待确认] | `<git user.name；YYYY-MM-DD>` |
```

## Gate-0 / 业务目标与用例

`类型=业务|混合` 必填；`类型=技术|缺陷` 可写 `不适用（类型=技术|缺陷）`。

```markdown
## 业务目标
- …

## 用例 / 用户故事
1. 作为 …，我希望 …，以便 …
```

## Gate-1 / 页面布局预览（无原型）

Gate-1 H2 顺序：**本片段**（命中时）→ `## 验收标准` → `## 实现方案`。  
由 `/xijia:prd`、缺陷落盘或 A.0.5 写入；`refinement` **禁止**写本节。完整规则见 `gate1-plan-template.md`「页面布局预览」。

**命中**：Gate-0「无原型对照」且数据流「前端入口」≠ `—`。  
**跳过**：有原型（Step 1.2 已完成）；纯后端 / 无 UI → 写不适用。

````markdown
## 页面布局预览
> 壳层：`frontend-butter-shell`；列表：`table-first-list-page`。

路由: `/w/...`  |  menuKey: `...`  |  pattern: Table-First … + Drawer

```text
（ASCII ≤35 行，box-drawing 字符画）
…
```
````

不适用（无 UI 触达）：

```markdown
## 页面布局预览
不适用（无 UI 触达；数据流前端入口为 —）
```

参照现有页（差异 ≤3 点）：

```markdown
## 页面布局预览
骨架：同 `frontend/src/views/UserManageView.vue`（Table-First 分页平表 + Drawer）
差异：① … ② … ③ …
```

## Gate-1 / 验收标准

由 `/xijia:prd` 按分档写满（`gate1-by-tier.md`）；A.0.5 仅补缺口。完整骨架见 `gate1-plan-template.md`（其前可选「页面布局预览」）。  
**禁止**另建独立 H1 `# 验收标准`（须为 Gate-1 下 H2）。`refinement` 禁止写本节。

```markdown
## 验收标准
> 三态勾选：`[ ]` 未检 → verify 自动化通过后 `[~]` 程序已检 → Gate-2 签字后 `[x]` 人工已验收。详见 `gate1-plan-template.md` 规则 5。

- [ ] 覆盖要求：每条 In-Scope 能力至少 正常/空/错误/无权限；≥1 条可执行断言
- [ ] **AC-1**：GIVEN … WHEN … THEN …
  - **反例（本 AC 排除）**：…
```

## Gate-0 / 相关历史与冲突识别

按模块、BC、关键词检索 shipped、decisions、pitfalls、patterns、domain 后填写 top-N。

```markdown
| 相关项 | 匹配依据与关联点 | 本需求处置 |
|---|---|---|
| `docs/...` | `<模块/BC/关键词；约束或冲突>` | 复用 / 规避 / 改需求 / Deviation / ADR / 无关 |

冲突识别结论: 无冲突（已对照 capability-map / domain / decisions）
```

## Gate-0 / 领域影响

仅 `类型=业务|混合` 时插入。

```markdown
### 领域影响

- 限界上下文：...
- 关键领域概念：...
- 领域规则与不变量：INV-xxx ...
```

## Gate-0 / 原型对齐与偏离

有原型时替换主模板中的“无原型对照”。静态 HTML/图片只能证明外观与布局。

```markdown
| 维度 | PRD 描述 | 原型 `<path>` 实际 | 差异类型 |
|---|---|---|---|
| — | — | — | 一致 / PRD有原型无 / 原型有PRD无 / 双方不同 |
| 原型无法表达的动态行为 | `<PRD 期望>` | 原型不表达 | 需人工确认 |

已确认口径：以 PRD 为准 / 以原型为准 / 分批（确认人:；日期:）

| 偏离单号 | 原型差异点 | 建议方案 | 审批 |
|---|---|---|---|
| DEV-... | ... | ... | open / approved / rejected |
```

## Gate-2 / 变更文件

变更较多、单行清单不可读时插入。

```markdown
| 模块/BC | 文件 | 变更摘要 |
|---|---|---|
| — | — | 新增 / 修改 / 删除 |
```
