# Read/Write 失败降级与 shipped 协议

Cursor Read/Write 返回 **Permission denied**（常见于 inbox→shipped Move 之后；`docs/requirements/shipped/` 在 `.cursorignore`）时**必须**按本文件操作。

## 降级步骤

1. 用 Python：`Path.read_text(encoding="utf-8")` / `write_text(..., encoding="utf-8", newline="\n")`，或 `scripts/write_utf8.py`。勿用 PowerShell `Set-Content` / 批量 `-replace` 补救。
2. inbox→shipped 后：直接对 **shipped 目标路径** 用 Python；勿 Move 回 inbox 再重试。
3. 仍失败 → **一次** stop-and-report（附绝对路径与错误原文）；不盲重试超过一轮。
4. 勿输出「需求文档已从磁盘消失，正在重建并归档到 shipped/」并用 Cursor Write / Task 子 Agent **全量重建** shipped。inbox 不可见 → 走 `xijia-sync-knowledge` `references/gate3-archive.md` 步骤 17.5 预检硬停。

## 归档路径

- Gate-3 正文编辑只在 **inbox**。
- 归档仅 `Move-Item` / `scripts/archive-requirement.ps1`。
- 对 shipped：用 Move 归档；事后修改用 Python，不用 Cursor `Write`/`StrReplace`。

本技能不修复 Cursor/IDE 权限 bug，只缩短绕行并防止写坏文件。

**完成：** 目标路径经 `verify_utf8.py` exit 0，或已 stop-and-report。
