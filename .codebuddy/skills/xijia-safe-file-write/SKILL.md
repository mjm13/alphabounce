---
name: xijia-safe-file-write
description: "Load when 写 docs/requirements|.md, BOM, Set-Content, Permission denied, Gate-3 shipped, closeout, requirement, 编码."
---

# 目标

跨平台安全写源码/文档：UTF-8（无 BOM）、LF；Shell 管道/heredoc 易损坏文件时改用 Write/Python。Gate-3 标记与 Read 失败降级见 references。

# 何时强制加载（命中即 Read 本技能再写）

| 场景 | 是否强制 |
| --- | --- |
| 新建/改写 `docs/requirements/inbox|shipped/*.md` | **强制**（含 PRD 多篇落盘） |
| 改 `docs/**/*.md`、活文档、ADR/pattern/pitfall | **强制** |
| Gate-3 改 shipped / capability-map / flow | **强制** |
| 仅改 `backend/` `frontend/` 且不用 Shell 写文本 | 推荐 Write/StrReplace |
| 用 Shell 向任何路径写文本 | **强制**（遵守 §1） |

批量落盘仍须加载本技能。批量 = 多次 Write（或多次 `write_utf8.py`）直接写目标；勿默认先造 `_gen_*.py` 再跑。

# 渐进披露（硬 pointer）

| 主题 | 必须 Read |
| --- | --- |
| Gate-3 沉淀标记 / false-noop | [`references/gate3-markers.md`](references/gate3-markers.md) |
| Permission denied / shipped 协议 | [`references/shipped-write.md`](references/shipped-write.md) |

# 0. 检测 OS

1. 首选 `user_info` 的 `OS Version`（`win32` / `darwin` / `linux`）。
2. 兜底：`python -c "import platform; print(platform.system())"`。
3. 进入对应分支；勿混用（如 win32 上用 bash 假设写 md）。

简记：`OS=<win32|darwin|linux>`。  
**完成：** 已记录 OS。

# 1. 写文件工具优先级

| 步骤 | Windows (`win32`) | macOS / Linux |
| --- | --- | --- |
| **首选** | Cursor **Write** / **StrReplace** | 同左 |
| **批量/大段** | 多次 Write，或 `scripts/write_utf8.py <path>` | 同左 |
| **改已有** | Python `read_text` / `write_text(..., encoding="utf-8", newline="\n")` | 同左 |
| **Shell 写文本** | 改用 Write/Python；勿用 `Set-Content` / `Out-File` / PS `-replace` / heredoc / 默认 `_gen_*.py` | 改用 Write；勿用 bash heredoc 写 requirement |
| **写后验证** | `python .codebuddy/skills/xijia-safe-file-write/scripts/verify_utf8.py <path>` | 同左 |

```python
from pathlib import Path
path = Path("docs/example.md")
text = path.read_text(encoding="utf-8")
path.write_text(text, encoding="utf-8", newline="\n")
```

```bash
# 全文从 stdin 写入（UTF-8 LF）
python .codebuddy/skills/xijia-safe-file-write/scripts/write_utf8.py <path> < content.md
```

**完成：** 目标路径 `verify_utf8.py` exit 0。

# 2. 编码与换行

- UTF-8 **无 BOM**（新写不主动加 BOM）。
- 换行：**LF**（`.gitattributes` `eol=lf`）。
- Windows：勿依赖 PowerShell 默认 CRLF。
- 声称「已修复」前：`verify_utf8.py` exit 0。

**完成：** verify exit 0。

# 3. 终端乱码 ≠ 文件损坏

PowerShell CP936 / 管道乱码只代表显示链路可疑。须先 `verify_utf8.py`（或检查 BOM / 严格 UTF-8 / `U+FFFD`），再决定是否改文件；勿因乱码整文件 `Get-Content | Set-Content`。

详见 `docs/pitfalls/windows-powershell-utf8-bom.md`。  
**完成：** 已区分显示问题与磁盘损坏。

# 4–6. Gate-3 标记与 shipped 降级

写 Gate-3 标记前**必须** Read [`references/gate3-markers.md`](references/gate3-markers.md)。  
Permission denied / 改 shipped 前**必须** Read [`references/shipped-write.md`](references/shipped-write.md)。

**完成：** 两 references 内完成标准均满足（若本回合触及）。

# 7. Gate-3 收尾 checklist（一次 closeout）

改 shipped / 活文档前已加载本技能。顺序：

1. 检测 OS（§0）
2. `git status --short docs/capability-map.md docs/flow.md`（markers）
3. 确认 inbox 存在：`Test-Path` 或 `--check-gate3-preflight`；不存在 → stop-and-report
4. **仅在 inbox** 用 Write/StrReplace 改状态 + Gate-3 沉淀
5. `archive-requirement.ps1` / Move → shipped；Move 后再改 shipped → **仅 Python**
6. `python .codebuddy/skills/xijia-safe-file-write/scripts/verify_utf8.py <shipped-path>`
7. Experience Reuse 与约束引用对齐
8. 标记对照 gate3-markers（说明内无误用 `no-op` 子串）
9. `python .codebuddy/hooks/pipeline_guard.py --check-closeout --req <shipped-path>`
10. `python .codebuddy/hooks/pipeline_guard.py --check-doc-anchors`

目标：从改标记到 closeout OK **≤2 次** guard。  
**完成：** closeout + doc-anchors exit 0。

# GOTCHAS

| 症状 | 修复 |
| --- | --- |
| false-noop / `updated（…no-op）` | 写 `updated（…无业务主流程变更）`；说明勿含子串 `no-op` |
| PS/heredoc 损坏 md | Write/Python + `verify_utf8.py`；勿 `_gen_*.py` |
| 终端乱码后整文件重写 | 先 verify；显示≠磁盘 |
| Permission denied / Task 重建 shipped | `shipped-write.md`；Move 归档；预检见 sync 17.5 |

Pitfall：`docs/pitfalls/windows-powershell-utf8-bom.md` · Gate-3：`xijia-sync-knowledge`
