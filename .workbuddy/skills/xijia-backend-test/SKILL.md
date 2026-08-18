---
name: xijia-backend-test
description: "Load when 写后端 AC 测前, backend TDD, Gate-1 后端验收标准."
agent_created: true
---

# 目标

以 **红-绿-重构** 循环驱动后端实现：先写失败验证（RED），再写最小实现（GREEN），最后清理（REFACTOR）。实现前须有可失败的测试。

与 `openspec-superpowers-apply` 联动：每条 Gate-1 `AC-*` 须有对应测试或明确可运行验证命令，否则不得勾选任务。

# 栈无关测试门禁

## 1) 判定测试类型

- 触达持久化、事务、权限、数据范围、唯一性等业务规则：真实数据库行为验证（集成测试优先）。
- 纯计算或纯转换：可用单元测试，外部依赖按需 mock。
- 外部系统调用（HTTP/RPC/消息）：可 mock。

## 2) 强制规则

- **数据库真值**：用真实 DB 语义验证；勿用 mock 数据访问层返回值替代。
- 测试数据须满足业务不变量和契约约束。
- 验证冲突时以可执行测试为准，并回写设计/契约文档。

## 3) 执行步骤（RED -> GREEN -> REFACTOR）

1. RED：先写失败测试（正向、负向、边界至少一组）。  
   **完成：** 测试失败且失败原因对应该 AC。
2. GREEN：补最小实现使测试通过。  
   **完成：** 相关测试 exit 0。
3. REFACTOR：清理重复与命名，保持测试全绿。  
   **完成：** 重构后同一测试集仍 exit 0。

# 最小验收清单

- [ ] 每条 Gate-1 AC-* 至少有 1 个测试或明确验证命令
- [ ] 正向、负向、边界均有覆盖
- [ ] 持久化相关测试使用真实数据库行为
- [ ] 外部依赖隔离策略明确（可 mock）
- [ ] 回归验证可重复执行

**完成：** 上表全勾后才勾选对应 tasks。

# 与本项目的关系（METRIC HUB）

- **后端根目录**：`backend/`；集成测试库 `metric_hub_test`（pytest 会话自动 migrate）
- **回归命令**：`cd backend && pytest`；系统模块：`pytest tests/system -v`
- **Mock 边界**：外部 HTTP 可 mock；数据库业务语义用真实库
- **测试产物**：`tests/artifacts/trace-report.txt`

# 与技术栈技能的关系

本技能定义测试原则与门禁；上表为本仓库已确认的可执行命令。
