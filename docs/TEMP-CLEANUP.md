# 临时文件清理清单（Deferred）

以下为验收与构建过程中生成的临时文件与草稿，已通过 .gitignore 排除（不会被提交），待后续统一删除。请勿使用 git clean -fdx（会误删 tools/ 等被忽略的依赖目录）。

## 构建/测试临时产物
- game/build_result.txt
- game/start2.txt
- r05_ac_result.txt
- r06_ac_result.txt
- r06_logcat_filtered.txt
- r07_ac_result.txt

## 草稿与辅助脚本
- scripts/_check.gd
- scripts/_r05_import.py
- scripts/_r05_reexport.py
- strip_bom.ps1

## 陈旧/重复配置
- game/.export_presets.cfg （带点的陈旧副本；Godot 实际使用无点的 export_presets.cfg）

## 运行时瞬态目录
- .workbuddy/
- .codebuddy/teams/

后续统一删除时仅移除上述具体路径，不要递归清理整个工作区。
