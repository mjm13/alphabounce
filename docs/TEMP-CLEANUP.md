# 临时文件清理清单（已清理）

> 本清单记录验收/构建过程中生成的临时文件，原计划"后续统一删除"。
> 清理已于 2026-08-31 执行（具体路径删除，未递归工作区、未动 `.codebuddy` 主目录）。

## 已删除（均为 .gitignore 排除的非提交产物）

- game/build_result.txt
- game/start2.txt
- r05_ac_result.txt
- r06_ac_result.txt
- r06_logcat_filtered.txt
- r07_ac_result.txt
- scripts/_check.gd
- scripts/_r05_import.py
- scripts/_r05_reexport.py
- strip_bom.ps1
- game/.export_presets.cfg （带点的陈旧副本；正式无点 export_presets.cfg 保留）
- .codebuddy/teams/557f1eb30a344d26b75704b1e7a8374c （本次会话 team 瞬态会话数据）

## 保留（原清单误判，实际非临时）

- `.workbuddy/mcp.json`：含 MySQL 凭据（`MYSQL_PASS`）与工具路径的**真实 MCP 服务配置**，不可删。
  原清单将其列为"运行时瞬态目录"有误，已从此清单移除。

## 结论

临时文件清理完成，工作区无遗留构建/草稿产物。`.workbuddy/` 与 `.codebuddy/`
主目录（hooks/rules/skills）均保留。请勿使用 `git clean -fdx`（会误删 tools/ 等被忽略依赖）。
