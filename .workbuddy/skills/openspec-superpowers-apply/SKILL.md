---
name: openspec-superpowers-apply
description: "OpenSpec apply 与 Superpowers 强制联动实现入口（含 xijia-quality-judge 门禁）。"
agent_created: true
---

# OpenSpec + Superpowers Apply

将 OpenSpec 的任务编排与 Superpowers 的实现方法绑定为单一入口。

## 强制技能链

1. `openspec-apply-change`
2. `test-driven-development`
3. `xijia-backend-test` / `xijia-frontend-test`（按触达栈二选一或都用）
4. `systematic-debugging`（失败时）
5. `xijia-comment-enhancer`（verify 阶段：若触达核心业务代码，见 `44-comment-sync.mdc`）
6. `verification-before-completion`
7. `requesting-code-review`
8. `xijia-quality-judge`（新增，最终门禁）

## 执行步骤（简版）

1. 读取 change 上下文（proposal/design/tasks/spec）。
2. 建立 AC↔Test 追溯表；Gate-1 `## 验收标准`（或 OpenSpec specs）中的 AC 必须映射测试。
3. 按触达栈启用测试门禁（后端优先 `xijia-backend-test`，前端优先 `xijia-frontend-test`）。
4. 按任务循环：TDD -> 实现 -> 验证 -> 勾选。
5. 全任务完成后执行：
   - 若触达核心业务代码：`xijia-comment-enhancer`（先内部层再端点层）
   - `verification-before-completion`（含注释同步检查）
   - code-review
   - xijia-quality-judge（输出 `pass|revise`）
   - 人工验收说明
   - sync -> archive -> sync-knowledge
6. commit 由用户触发；未 commit 不得进入下一需求。

## 质量门禁

- `xijia-quality-judge = revise` 时，必须回到任务修正，禁止宣告完成。
- 仅当 judge 为 `pass` 且验证证据完整，才能进入收尾。
