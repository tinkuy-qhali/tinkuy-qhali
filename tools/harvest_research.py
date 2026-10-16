#!/usr/bin/env python3
"""Harvest Phase 1 research reports from subagent worktrees into the main checkout.

For every worktree under .claude/worktrees/agent-*/ copy docs/research/NN-*.md and
docs/research/_NN-anexo-*.md that do not yet exist in the main checkout (or differ),
normalising to LF. Then run tools/check_research.py on the harvested files.
With --prune, remove each harvested worktree (git worktree remove --force) and its branch.
Standard library only. Usage: python tools/harvest_research.py [--prune]
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "docs" / "research"
WT_DIR = ROOT / ".claude" / "worktrees"
REPORT_RE = re.compile(r"^(_)?\d{2}-[a-z0-9-]+\.md$")


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, text=True, capture_output=True, check=False).stdout


def main(argv: list[str]) -> int:
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    prune = "--prune" in argv
    DEST.mkdir(parents=True, exist_ok=True)
    harvested: list[Path] = []
    emptied: list[Path] = []
    for wt in sorted(WT_DIR.glob("agent-*")) if WT_DIR.exists() else []:
        src = wt / "docs" / "research"
        files = [p for p in src.glob("*.md") if REPORT_RE.match(p.name) and p.name != "_plantilla.md"] if src.exists() else []
        if not files:
            emptied.append(wt)
            print(f"[vacio] {wt.name}: sin informes")
            continue
        for p in files:
            text = p.read_text(encoding="utf-8", newline="").replace("\r\n", "\n")
            target = DEST / p.name
            if target.exists() and target.read_text(encoding="utf-8", newline="") == text:
                print(f"[igual] {p.name}")
            else:
                target.write_text(text, encoding="utf-8", newline="\n")
                print(f"[copia] {p.name} <- {wt.name}")
            if not p.name.startswith("_"):
                harvested.append(target)
        emptied.append(wt)
    rc = 0
    if harvested:
        rc = subprocess.run([sys.executable, str(ROOT / "tools" / "check_research.py"), *map(str, harvested)], cwd=ROOT).returncode
    if prune:
        for wt in emptied:
            branch = f"worktree-{wt.name}"
            print(git("worktree", "remove", "--force", str(wt)).strip() or f"[prune] worktree {wt.name}")
            print(git("branch", "-D", branch).strip() or f"[prune] branch {branch}")
        print(git("worktree", "prune").strip())
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
