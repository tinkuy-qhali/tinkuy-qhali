"""Shared timing/writing helpers for the item-22 Python workers (same file contract as benchmarks/R/common.R)."""
from __future__ import annotations

import csv
import os
import resource
import sys
import time
import tracemalloc
from pathlib import Path
from typing import Any, Callable

ROOT = Path(os.environ.get("TQ_BENCH_ROOT", "/workspace/benchmarks"))
CACHE = ROOT / ".cache"
REPS = int(os.environ.get("TQ_BENCH_REPS", "5"))


def rss_peak_bytes() -> int:
    return resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024  # Linux reports KiB


def time_impl(fun: Callable[[], Any], task: str, impl: str, size: str, versions: str,
              mem_fun: Callable[[], int] | None = None, extra_note: str = "") -> Any:
    """Warm-up (rep 0) + REPS timed calls with perf_counter; memory from ONE extra traced call so that
    tracemalloc overhead never enters the timings. mem_fun overrides tracemalloc (e.g. Arrow pool peak)."""
    rows = []
    t0 = time.perf_counter()
    value = fun()
    rows.append((0, time.perf_counter() - t0))
    for rep in range(1, REPS + 1):
        t0 = time.perf_counter()
        value = fun()
        rows.append((rep, time.perf_counter() - t0))
    tracemalloc.start()
    fun()
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    mem = mem_fun() if mem_fun else peak
    kind = "arrow memory pool max_memory" if mem_fun else "tracemalloc peak (Python heap only; Rust/C++ buffers excluded)"
    note = f"mem={kind}; rss_peak_mb={rss_peak_bytes() // 2**20}" + (f"; {extra_note}" if extra_note else "")
    key = f"{task}__py_{impl}__{size}"
    (CACHE / "res").mkdir(parents=True, exist_ok=True)
    with open(CACHE / "res" / f"{key}.csv", "w", newline="\n", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["rep", "seconds", "mem_bytes", "note"])
        for rep, secs in rows:
            w.writerow([rep, repr(secs), "NA" if rep == 0 else mem, ("warmup; " if rep == 0 else "") + note])
    (CACHE / "res" / f"{key}.versions.txt").write_text(versions + "\n", encoding="utf-8", newline="\n")
    return value


def write_out(header: list[str], rows: list[list[Any]], task: str, impl: str, size: str) -> None:
    (CACHE / "out").mkdir(parents=True, exist_ok=True)
    with open(CACHE / "out" / f"{task}__py_{impl}__{size}.csv", "w", newline="\n", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(header)
        for r in rows:
            w.writerow([repr(float(x)) if isinstance(x, float) else x for x in r])


def py_version() -> str:
    return "Python " + sys.version.split()[0]
