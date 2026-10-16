# Task 1 in Julia: personas JOIN hogares por HHID + agregacion ponderada por region x area
# (same contract as benchmarks/R/task1_join.R).
# Usage: julia --threads=auto benchmarks/julia/task1_join.jl <dataframes|duckdb> <x1|x25>
# DataFrames reads the Arrow IPC copies written by prepare.R (Arrow.jl has no Parquet reader and no Parquet package
# is in the image); DuckDB reads the Parquet files directly, like every other implementation.
using DataFrames, Arrow, DuckDB
include(joinpath(@__DIR__, "_bench.jl"))

const IMPL = ARGS[1]
const SIZE = length(ARGS) >= 2 ? ARGS[2] : "x1"
const COLS = ["region", "area", "n", "sum_w", "wm_edad", "wm_educ", "wm_hhsize"]

# NA handled explicitly: skip missing x in the numerator and its weight in the denominator.
function wmean(w, x)
    s = 0.0
    sw = 0.0
    @inbounds for i in eachindex(w, x)
        xi = x[i]
        if !ismissing(xi)
            s += w[i] * xi
            sw += w[i]
        end
    end
    return s / sw
end

function run_dataframes()
    p = DataFrame(Arrow.Table(joinpath(CACHE, "personas_$(SIZE).arrow")); copycols = false)
    h = DataFrame(Arrow.Table(joinpath(CACHE, "hogares.arrow")); copycols = false)
    j = innerjoin(select(p, :HHID, :edad, :educ), select(h, :HHID, :w, :region, :area, :hhsize); on = :HHID)
    g = combine(groupby(j, [:region, :area]), nrow => :n, :w => sum => :sum_w,
                [:w, :edad] => wmean => :wm_edad, [:w, :educ] => wmean => :wm_educ,
                [:w, :hhsize] => wmean => :wm_hhsize)
    sort!(g, [:region, :area])
    return g
end

function run_duckdb()
    p = joinpath(CACHE, "personas_$(SIZE).parquet")
    h = joinpath(CACHE, "hogares.parquet")
    sql = """
    SELECT region, area, count(*) AS n, sum(w) AS sum_w,
           sum(w * edad) / sum(CASE WHEN edad IS NULL THEN 0 ELSE w END) AS wm_edad,
           sum(w * educ) / sum(CASE WHEN educ IS NULL THEN 0 ELSE w END) AS wm_educ,
           sum(w * hhsize) / sum(CASE WHEN hhsize IS NULL THEN 0 ELSE w END) AS wm_hhsize
    FROM read_parquet('$p') p JOIN read_parquet('$h') h USING (HHID)
    GROUP BY region, area ORDER BY region, area"""
    con = DBInterface.connect(DuckDB.DB)
    try
        return DataFrame(DBInterface.execute(con, sql))
    finally
        DBInterface.close!(con)
    end
end

const versions = "Julia $(VERSION); DataFrames $(pkgversion(DataFrames)); Arrow $(pkgversion(Arrow)); " *
                 "DuckDB $(pkgversion(DuckDB))"
f = IMPL == "dataframes" ? run_dataframes : IMPL == "duckdb" ? run_duckdb : error("unknown impl $IMPL")
note = IMPL == "dataframes" ? "reads Arrow IPC (mmap), not Parquet" : ""
g = time_impl(f, "join_agg", IMPL, SIZE, versions; extra_note = note)
rows = [(Int(r.region), Int(r.area), Float64(r.n), Float64(r.sum_w), Float64(r.wm_edad), Float64(r.wm_educ),
         Float64(r.wm_hhsize)) for r in eachrow(g)]
write_out(COLS, rows, "join_agg", IMPL, SIZE)
println("join_agg $IMPL $SIZE ok: $(nrow(g)) groups, n=$(sum(g.n))")
