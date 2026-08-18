---
name: xijia-backfill-index
description: "Load when /xijia:backfill-index, 回填索引, INDEX_STALE."
agent_created: true
---

# Xijia Backfill Capability Index

## 目标

将 `docs/requirements/shipped/*.md` 中已确认的数据流闭环表 **merge** 进 `docs/capability-map.md`（去重、UPDATE 同主键，非 blind append）。

## 何时使用

- 老项目 capability-map 为空但 shipped 已有业务需求
- PRD Step 1.7 报 `INDEX_STALE` 且需批量重建索引

## 何时不用

- 日常 Gate-3（用 `extract_capability_index.py --req <single-shipped>`）
- 无 shipped 业务需求时

## 执行步骤

1. 确认 `docs/requirements/shipped/` 存在且有 `*.md`
2. 预览：
   ```bash
   python .cursor/hooks/extract_capability_index.py --backfill --dry-run
   ```
3. **stop-and-report** 预览结果（ADD/UPDATE 行数、跳过原因），请求用户确认
4. 用户确认后落盘：
   ```bash
   python .cursor/hooks/extract_capability_index.py --backfill
   ```
5. 可选：根据 `--json` 输出的 `cross_module_hints` 人工确认后 UPDATE `docs/domain/context-map.md`

## 规则

- 默认跳过 YAML properties 标记 `种子: true` 的工程基线需求
- 行主键：`moduleKey` + `前端入口`
- 修订记录追加在 capability-map 文末表

## 输出格式

```markdown
## Backfill Index Status

- Shipped scanned: <n>
- Skipped: <list + reason>
- Merge preview: ADD <a> | UPDATE <u> | SKIP <s>
- Written: docs/capability-map.md | dry-run only
- Next: /xijia:overview 验证；后续 PRD 走 Step 1.7
- Blockers: <none or list>
```

## GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| 未 dry-run 直接 backfill | blind append 风险 | 先 `--dry-run` + 用户确认 |
| 把 backfill 当日常 Gate-3 | 职责混淆 | 单需求用 `--req` 提取 |
| 工程种子混入业务索引 | 未按 `种子: true` 过滤 | 仅扫描业务 shipped |
