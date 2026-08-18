---
name: xijia-abandon-change
description: "Load when 放弃 change, abandon, 回滚实现."
agent_created: true
---

# 目标

停止推进时，安全撤销该需求的**代码 + Gate-1 YAML + 数据库结构（Schema）+ 本需求 Redis 键**；**最小文档改动**——仅将 Gate-1 重置为「待批准」，不做 dropped 归档留痕。

**禁止**只 revert git 而遗留 DDL（下一版同表 `CREATE TABLE` 会失败或出现 alembic at-head 与 schema 漂移）。

# 输入

- requirement 路径（优先）：`docs/requirements/inbox/<file>.md`（或 shipped，若已实现）
- 或 OpenSpec change 名（`openspec变更` / `docs/openspec/changes/<name>/`）
- 放弃原因（仅会话输出，**不写进** requirement md）

# 执行步骤

1. **准入**：确认未 Gate-2 签字 / 未 shipped 归档；已上线 → stop，改走「下线能力」流程（须人工确认）。
2. **划定触达面**（只读 requirement，**不写**）：
   - Gate-1 `实现方案` → `Files` / `Done` / 迁移编号
   - `git log --oneline -- <paths>` 补漏
   - Grep 共享引用（pattern 被其它 inbox 引用则**不删**）
3. **解析 Schema 触达面**（只读 requirement / migration 文件）：
   - 列出本需求 `CREATE TABLE` / `ALTER` / 种子涉及的表名
   - 记录 Alembic `revision` 与 `down_revision`（如 `0006_sys_config` → `0005_sys_user_button_seed`）
   - 若无 migration，Schema 回滚步骤可写 n/a
4. **回滚代码**（git 层）：
   - 删除本需求新增文件；已改文件 `git checkout <base> -- <path>` 或按 Files 选择性 revert
   - 必含：Alembic `versions/` + `baseline/sql/`、router/service/model、前端 api/view、专属 pytest
   - **禁止**整 commit revert 若混有多需求或其它无关改动
   - **禁止**修改 `docs/requirements/**`（步骤 8 除外）、**禁止**新建 `dropped/`
5. **回滚数据库结构（必做，分库策略）**（遵守 `22-db-destructive-safety.mdc`）：

   | 库 | 策略 | 硬约束 |
   | --- | --- | --- |
   | `metric_hub_test` | `DATABASE_URL` 指向测试库后 `alembic downgrade <down_revision>` | **禁止跳过**；失败则 abandon **BLOCKED** |
   | `metric_hub` | 输出：受影响表、downgrade/DROP 命令、数据是否可丢、回滚方案 | **必须提请用户文字批准**（库名+命令+影响）；**批准后必须执行** |
   | Redis | 按需求文档前缀 DEL（如 `mh:config:*`） | 禁止 `FLUSHDB` |

   - 无 migration 时：测试库仍须确认 `alembic_version` 与代码链一致；dev 须确认无 orphan 表
   - **禁止**在 dev schema 未回滚时宣告 abandon 完成

6. **Schema 回滚验证**（测试库必做；开发库在步骤 5 执行后必做）：

   ```sql
   -- 示例：abandon 的表应不存在
   SELECT 1 FROM information_schema.tables
   WHERE table_schema = DATABASE() AND table_name = '<table>';
   -- 期望：无行
   SELECT version_num FROM alembic_version;
   -- 期望：与 down_revision 或代码仍存在的 migration 链一致
   ```

   - dev 未获批准 destructive 操作 → abandon **BLOCKED**；输出「dev schema 未回滚，禁止同路径重启 Gate-1」

7. **OpenSpec**（若存在 `docs/openspec/changes/<name>/`）：`git rm -r` 整个 change 目录；**不**执行 `/opsx:sync`、**不**写入 archive
8. **重置 Gate-1（唯一允许的 docs 写入）**：
   - 路径保持 `docs/requirements/inbox/<file>.md`；若在 `dropped/` 则 `git mv` 回 inbox
   - YAML 仅改一行：`Gate-1: 状态:待批准`（`待*` 态不写审批人/日期，见 `45-requirement-intake.mdc`）
   - **保留** Gate-1 正文（验收标准 / 实现方案 / 页面布局预览）
   - **禁止**：`状态:dropped`、`放弃原因`、文首 abandon 横幅、`git mv` 到 `dropped/`、改 `inbox/README`
   - 写前加载 `xijia-safe-file-write`；写后 `verify_utf8.py`
9. **验证**：跑 requirement `Done` 中最小 pytest/build；schema 探针通过；确认无 orphan import / 无缺失 revision
10. **会话输出**（不写 docs）：

```markdown
## Abandon Result
- Requirement: <path>
- Gate-1 reset: 待批准
- Code reverted: <file list>
- Schema test: alembic downgrade <rev> → OK | BLOCKED
- Schema dev: <命令> → 已执行 | 未批准 BLOCKED
- Schema verify: <table> absent in information_schema → OK | FAIL
- Redis: <prefix keys deleted> | n/a
- OpenSpec: deleted <name> | n/a
- Tests: <command + exit code>
```

# 约束

- 若 change 已上线或已归档，应改用「下线能力」标准流程（REMOVED requirements）
- 遇到删除已上线能力时必须触发人工确认
- abandon **只动 Gate-1 YAML 一行**；不得改 Gate-0 / Gate-2 / 正文 `状态`
- 开发库 destructive 仍须用户文字批准，但 skill 要求**必提请 + 批准后必执行**；未批准则整体 **BLOCKED**

# GOTCHAS

| 症状 | 根因 | 修复 |
| --- | --- | --- |
| commit 混有多需求 | 整 commit revert | 按 Files 选择性 revert |
| pattern 被其它 inbox 引用 | 误删共享 pattern | 只回滚代码 |
| 测试库 revision 孤儿 | migration 文件已删但 DB 仍 stamp | `metric_hub_test` 上 alembic downgrade |
| 下一版同表 1054 Unknown column | abandon 未 downgrade/DROP dev 旧表 | abandon 必须完成 dev schema 回滚后再开 Gate-1 |
| alembic at head 但列不存在 | 旧表遗留 + startup 跳过 upgrade | dev: downgrade + upgrade；见 `db_migrate.py` drift 探针 |
| Gate-1 仍带审批人 | 未清 `待*` 态字段 | 改为 `Gate-1: 状态:待批准` 单行 |
| 误改 inbox README | 旧 dropped 流程 | abandon 禁止改 README |
| 误改 Gate-0/Gate-2 | 范围过大 | 仅 Gate-1 YAML |
| 只 revert 代码 | §5 被跳过 | Schema 回滚与验证为硬停 |
