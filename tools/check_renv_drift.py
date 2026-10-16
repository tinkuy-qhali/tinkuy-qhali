#!/usr/bin/env python3
"""check_renv_drift.py - Compare the committed env/r/renv.lock with the snapshot the image build regenerated.

Why: the image must install exactly what the lockfile says. We compare package set and versions (what matters for
reproducibility) and ignore cosmetic fields such as `Repository` ("RSPM" vs "CRAN"), `Hash` and `Requirements`, which renv
rewrites depending on install path. Exit 1 on drift, with an actionable list. Stdlib only.

Usage (inside the image): python tools/check_renv_drift.py [/opt/env/r/renv.lock] [/opt/env/r/renv.lock.generated]
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def load(p: str) -> dict:
    return json.loads(Path(p).read_text(encoding="utf-8"))


def main(argv: list[str]) -> int:
    committed = argv[1] if len(argv) > 1 else "/opt/env/r/renv.lock"
    generated = argv[2] if len(argv) > 2 else "/opt/env/r/renv.lock.generated"
    a, b = load(committed), load(generated)
    problems: list[str] = []
    if a["R"]["Version"] != b["R"]["Version"]:
        problems.append(f"R version: lock={a['R']['Version']} image={b['R']['Version']}")
    pa, pb = a["Packages"], b["Packages"]
    for k in sorted(set(pa) - set(pb)):
        problems.append(f"{k}: in lockfile but not installed")
    for k in sorted(set(pb) - set(pa)):
        problems.append(f"{k} {pb[k].get('Version')}: installed but not in lockfile (run: copy renv.lock.generated -> env/r/renv.lock)")
    for k in sorted(set(pa) & set(pb)):
        if pa[k].get("Version") != pb[k].get("Version"):
            problems.append(f"{k}: lock={pa[k].get('Version')} image={pb[k].get('Version')}")
    if problems:
        print(f"renv drift: {len(problems)} problem(s)")
        print("\n".join(" - " + p for p in problems))
        return 1
    print(f"renv.lock matches the image: {len(pa)} packages, R {a['R']['Version']}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
