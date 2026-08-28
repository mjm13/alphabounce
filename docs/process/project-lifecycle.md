# 项目生命周期（project lifecycle）

对应入口与阶段：

| 场景 | 入口 |
| --- | --- |
| 推进需求（默认） | /xijia:start 或自然语言 → xijia-feature-pipeline |
| 工程基线（init 后首批） | inbox 种子需求 |
| 登记缺陷 | /xijia:defect |
| 项目速览 | /xijia:overview |
| 采纳历史项目 | /xijia:adopt |
| PRD→需求 | /xijia:prd |
| 发版/封版 | /xijia:release |
| 回填索引 | /xijia:backfill-index |
| 状态查看 | /xijia:status |

## 需求目录
- requirements/inbox/：新登记、Gate-0/1 进行中
- requirements/active/：已实现未闭环
- requirements/shipped/：Gate-3 已交付（待 release）
- requirements/archive/：已发版/废弃
