# 知识维护（Living Docs）

附录限度（AGENTS.md 引用）：
1. 同一事实已在文中 → 改写原句，不新增段落。
2. 仅单一领域/阶段需要 → 写入对应 doc 或 rule，AGENTS.md 只留一行指针。
3. 新增 ≥3 行时同轮评估能否下沉等量旧内容。
4. 禁止镜像目录树、代码文件清单、文档树路由。

## 沉淀触发
- Gate-3 关闭需求时，按类型判型决定是否沉淀：
  - 业务/混合（business/hybrid）：须更新 capability-map、domain、ADR、Patterns/Pitfalls。
  - 技术（technical）：仅要求归档一致 + 活文档无断链 + 无栈漂移；可声明 no-op。
- false-noop 校验：标记 no-op 但本轮实际改动对应活文档 → 报错，须改为 updated 或补文档。
