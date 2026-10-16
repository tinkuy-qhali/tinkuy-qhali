"""Task 1 in Python: personas JOIN hogares por HHID + agregacion ponderada por region x area
(same contract as benchmarks/R/task1_join.R).
Usage: python benchmarks/python/task1_join.py <polars|duckdb> <x1|x25>"""
from __future__ import annotations

import sys

import duckdb
import polars as pl
import pyarrow

from _bench import CACHE, py_version, time_impl, write_out

impl, size = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "x1")
P = str(CACHE / f"personas_{size}.parquet")
H = str(CACHE / "hogares.parquet")
COLS = ["region", "area", "n", "sum_w", "wm_edad", "wm_educ", "wm_hhsize"]


def wmean(x: str) -> pl.Expr:
    # NA handled explicitly: numerator skips nulls (sum ignores them), denominator only weights of non-null rows.
    return (pl.col("w") * pl.col(x)).sum() / pl.col("w").filter(pl.col(x).is_not_null()).sum()


def run_polars() -> list[list]:
    out = (
        pl.scan_parquet(P)
        .join(pl.scan_parquet(H), on="HHID", how="inner")
        .group_by("region", "area")
        .agg(n=pl.len(), sum_w=pl.col("w").sum(), wm_edad=wmean("edad"), wm_educ=wmean("educ"),
             wm_hhsize=wmean("hhsize"))
        .sort("region", "area")
        .collect()
    )
    return [list(r) for r in out.select(COLS).iter_rows()]


SQL = f"""
SELECT region, area, count(*) AS n, sum(w) AS sum_w,
       sum(w * edad) / sum(CASE WHEN edad IS NULL THEN 0 ELSE w END) AS wm_edad,
       sum(w * educ) / sum(CASE WHEN educ IS NULL THEN 0 ELSE w END) AS wm_educ,
       sum(w * hhsize) / sum(CASE WHEN hhsize IS NULL THEN 0 ELSE w END) AS wm_hhsize
FROM read_parquet('{P}') p JOIN read_parquet('{H}') h USING (HHID)
GROUP BY region, area ORDER BY region, area
"""


def run_duckdb() -> list[list]:
    with duckdb.connect() as con:
        return [list(r) for r in con.execute(SQL).fetchall()]


impls = {"polars": run_polars, "duckdb": run_duckdb}
versions = f"{py_version()}; polars {pl.__version__}; duckdb {duckdb.__version__}; pyarrow {pyarrow.__version__}"
res = time_impl(impls[impl], "join_agg", impl, size, versions)
write_out(COLS, [[r[0], r[1], float(r[2])] + r[3:] for r in res], "join_agg", impl, size)
print(f"join_agg {impl} {size} ok: {len(res)} groups, n={sum(r[2] for r in res)}")
