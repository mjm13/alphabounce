# 工作流（xijia）

日常需求推进入口：`/xijia:start`（或自然语言 → xijia-feature-pipeline）。

## 闸门（Gates）
- Gate-0 数据闭环：登记即校验约束引用 / 类型判型，OQ 闭环。
- Gate-1 方案审核：页面布局预览 + 验收标准 + 实现方案，须审批人签字。
- Gate-2 收尾聚合：comment-sync + 验收记录 + 经验复用留痕；`python .codebuddy/hooks/pipeline_guard.py --check-release --req <req>`。
- Gate-3 沉淀闭环：Move 需求到 shipped/，更新活文档（capability-map / domain / ADR / Living Docs），`--check-closeout --req <shipped-req>`。

## 阶段对照
- 工程基线（init 后首批）：inbox 种子需求。
- 推进需求（默认）：xijia-feature-pipeline。
- 登记缺陷：/xijia:defect。
- 项目速览：/xijia:overview。
- 采纳历史项目：/xijia:adopt；PRD→需求：/xijia:prd；发版：/xijia:release；回填索引：/xijia:backfill-index；状态：/xijia:status。
