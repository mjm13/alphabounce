# 发布检查清单（Release Checklist）

> 活文档：`/xijia:release` 与 Release Gate 人审时使用。init 为占位；首次真实发布前须填完整可执行项。

## 发布信息

| 项 | 值 |
| --- | --- |
| 版本号 | <semver，如 1.2.0> |
| 目标分支 | `main`（自 `dev` 合并） |
| 发布负责人 | meijianming |
| 计划发布日期 | 2026-08-18 |
| Release Gate | 状态:待批准/已批准；审批人:；日期: |

## 客观项（`/xijia:release` 审计）

运行：

```bash
python .cursor/hooks/pipeline_guard.py --check-release-readiness
```

- [ ] 审计 exit=0 或已知豁免已记录
- [ ] `AGENTS.md` 中 test/build 命令已填写（非 `<待补充>`）
- [ ] CI 配置存在或已在 AGENTS / 本 checklist 声明「仅本地 CI」及等价命令

## 需求与代码

- [ ] `docs/requirements/inbox/` 无未完成需求（或已明确延期入 backlog）
- [ ] 本次发布范围的需求均已 Gate-3 + `--check-closeout` 通过
- [ ] `dev` 上 verify 证据齐全（测试/构建）

## 数据库与迁移

- [ ] 迁移脚本已 review；生产执行顺序与回滚方案已确认
- [ ] 无未批准的破坏性 DB 操作（见 `22-db-destructive-safety.mdc`）

## 变更说明

- [ ] 变更日志 / Release Notes 已撰写（链接或路径：）
- [ ] 需用户知晓的配置/环境变量变更已列出

## 部署与回滚

- [ ] 部署步骤见 `AGENTS.md` 或 runbook（<待补充>）
- [ ] 回滚步骤已验证或演练（<待补充>）
- [ ] 环境晋升路径：dev → staging → prod（<待补充>）

## 发布后

- [ ] 冒烟检查清单已执行（<待补充>）
- [ ] 监控/告警无新增 CRITICAL（<待补充>）
- [ ] Release Gate 人工签字完成
