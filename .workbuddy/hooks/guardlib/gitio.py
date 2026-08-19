"""Git change discovery with explicit failure semantics."""

from __future__ import annotations

import re
import subprocess

from . import paths

TEST_RE = re.compile(r"(^|/)(tests?|__tests__)/|(^|/)test_|\.(test|spec)\.")


class GitCommandError(RuntimeError):
    """Raised when a git command cannot provide trustworthy change data."""

    def __init__(self, args: list[str], detail: str):
        self.args_list = args
        super().__init__(f"git {' '.join(args)} 失败: {detail}")


def git_lines(args: list[str]) -> list[str]:
    try:
        result = subprocess.run(
            ["git", *args], cwd=paths.ROOT, capture_output=True, text=True,
            encoding="utf-8", errors="replace",
        )
    except (OSError, ValueError) as exc:
        raise GitCommandError(args, str(exc)) from exc
    if result.returncode:
        raise GitCommandError(args, (result.stderr or result.stdout or f"exit {result.returncode}").strip())
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def changed_files(base: str) -> list[str]:
    changed = set(git_lines(["diff", "--name-only", base]))
    changed.update(git_lines(["ls-files", "--others", "--exclude-standard"]))
    return sorted(rel for raw in changed if (rel := paths.to_rel(raw)))


def changed_impl_files(base: str) -> list[str]:
    return [rel for rel in changed_files(base) if paths.is_comment_sync_code(rel)]


def changed_all_files(base: str) -> list[str]:
    return changed_files(base)


def changed_test_files(base: str) -> list[str]:
    prefixes = (f"{paths.BACKEND_DIR}/", f"{paths.FRONTEND_DIR}/")
    return [rel for rel in changed_files(base) if rel.startswith(prefixes) and TEST_RE.search(rel)]


def needs_adr(files: list[str]) -> bool:
    dependency_files = {
        f"{paths.BACKEND_DIR}/requirements.txt",
        f"{paths.FRONTEND_DIR}/package.json",
        f"{paths.FRONTEND_DIR}/package-lock.json",
        f"{paths.FRONTEND_DIR}/yarn.lock",
    }
    return any(
        rel in dependency_files
        or (rel.startswith(f"{paths.BACKEND_DIR}/alembic/versions/") and rel.endswith(".py"))
        or (paths.CODE_FILE_RE.search(rel) and re.search(r"(auth|permission|rbac|security|secret|token)", rel, re.I))
        for rel in files
    )
