"""Task 2 in Python (model in benchmarks/R/task2_microsim.R). numpy is NOT in the image (env/python/uv.lock), so the
vectorised version uses pyarrow.compute (pc.random with one seeded stream per draw) plus a set-based DuckDB SQL one.
Usage: python benchmarks/python/task2_microsim.py <pyarrow|duckdb>"""
from __future__ import annotations

import os
import sys

import duckdb
import pyarrow as pa
import pyarrow.compute as pc

from _bench import py_version, time_impl, write_out

impl = sys.argv[1]
N = int(os.environ.get("TQ_MICROSIM_N", "1000000"))
STEPS, A, B, C, SEED = 10, -3.0, 0.03, 0.3, 20261016
KEYS = ["n", "mean_events", "sd_events", "mean_cost", "sd_cost", "prop_any"] + [f"k{j}" for j in range(STEPS + 1)]


def run_pyarrow() -> dict:
    age = pc.add(20.0, pc.floor(pc.multiply(60.0, pc.random(N, initializer=SEED))))
    sex = pc.cast(pc.less(pc.random(N, initializer=SEED + 1), 0.5), pa.float64())
    events = pc.multiply(age, 0.0)
    cost = pc.multiply(age, 0.0)
    for t in range(1, STEPS + 1):
        age = pc.add(age, 1.0)
        lin = pc.add(pc.add(A, pc.multiply(B, age)), pc.multiply(C, sex))
        p = pc.divide(1.0, pc.add(1.0, pc.exp(pc.negate(lin))))
        ev = pc.cast(pc.less(pc.random(N, initializer=SEED + 1 + t), p), pa.float64())
        events = pc.add(events, ev)
        cost = pc.add(cost, pc.divide(pc.add(pc.multiply(1500.0, ev), 100.0), 1.03 ** t))
    k = pc.value_counts(pc.cast(events, pa.int64()))
    hist = dict(zip(k.field("values").to_pylist(), k.field("counts").to_pylist()))
    vals = [N, pc.mean(events).as_py(), pc.stddev(events, ddof=1).as_py(), pc.mean(cost).as_py(),
            pc.stddev(cost, ddof=1).as_py(), pc.mean(pc.cast(pc.greater(events, 0.0), pa.float64())).as_py()]
    return dict(zip(KEYS, vals + [hist.get(j, 0) for j in range(STEPS + 1)]))


def run_duckdb() -> dict:
    # Set-based: 1e6 x 10 person-steps, one random() per row. random() is seeded by setseed(), but with several
    # threads the draw order is not deterministic: reproducible in distribution, not bit-for-bit.
    hist = ", ".join(f"count(*) FILTER (WHERE events = {j})" for j in range(STEPS + 1))
    sql = f"""
    WITH pop AS (SELECT i, 20 + floor(60 * random()) AS age0, (random() < 0.5)::DOUBLE AS sex FROM range({N}) r(i)),
    ps AS (SELECT i, t, (random() < 1 / (1 + exp(-({A} + {B} * (age0 + t) + {C} * sex))))::DOUBLE AS e
           FROM pop, range(1, {STEPS + 1}) s(t)),
    per AS (SELECT i, sum(e) AS events, sum((1500 * e + 100) / pow(1.03, t)) AS cost FROM ps GROUP BY i)
    SELECT count(*), avg(events), stddev_samp(events), avg(cost), stddev_samp(cost), avg((events > 0)::DOUBLE), {hist}
    FROM per"""
    with duckdb.connect() as con:
        con.execute(f"SELECT setseed({(SEED % 1000) / 1000})")
        return dict(zip(KEYS, con.execute(sql).fetchone()))


impls = {"pyarrow": run_pyarrow, "duckdb": run_duckdb}
versions = f"{py_version()}; pyarrow {pa.__version__}; duckdb {duckdb.__version__}; numpy ABSENT"
mem_fun = (lambda: pa.default_memory_pool().max_memory()) if impl == "pyarrow" else None
note = ("numpy absent from image: pyarrow.compute used as vectorised substitute" if impl == "pyarrow"
        else "DuckDB random() with threads>1: not bit-reproducible")
res = time_impl(impls[impl], "microsim", impl, "n1e6", versions, mem_fun=mem_fun, extra_note=note)
write_out(["metric", "value"], [[k, float(v)] for k, v in res.items()], "microsim", impl, "n1e6")
print(f"microsim {impl} ok: mean_events={res['mean_events']:.6f} mean_cost={res['mean_cost']:.4f}")
