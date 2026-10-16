# Shared timing/writing helpers for the item-22 Julia workers (same file contract as benchmarks/R/common.R).
const ROOT = get(ENV, "TQ_BENCH_ROOT", "/workspace/benchmarks")
const CACHE = joinpath(ROOT, ".cache")
const REPS = parse(Int, get(ENV, "TQ_BENCH_REPS", "5"))

fmt(x::AbstractFloat) = repr(Float64(x))
fmt(x::Integer) = string(x)
fmt(x) = string(x)

# Warm-up (rep 0, includes JIT compilation = "time to first X") + REPS calls measured with @timed.
# mem_bytes = bytes allocated by Julia during the call (@timed); peak RSS of the process goes in the note.
function time_impl(f, task, impl, size, versions; extra_note = "")
    rows = Tuple{Int,Float64,Union{Missing,Int}}[]
    st = @timed f()
    push!(rows, (0, st.time, missing))
    value = st.value
    for rep in 1:REPS
        st = @timed f()
        push!(rows, (rep, st.time, st.bytes))
        value = st.value
    end
    note = "mem=@timed bytes allocated by Julia (DuckDB C++ buffers excluded); rss_peak_mb=$(Sys.maxrss() ÷ 2^20); " *
           "threads=$(Threads.nthreads())" * (isempty(extra_note) ? "" : "; " * extra_note)
    key = "$(task)__jl_$(impl)__$(size)"
    mkpath(joinpath(CACHE, "res"))
    open(joinpath(CACHE, "res", key * ".csv"), "w") do io
        println(io, "rep,seconds,mem_bytes,note")
        for (rep, secs, mem) in rows
            println(io, rep, ",", fmt(secs), ",", ismissing(mem) ? "NA" : mem, ",\"",
                    rep == 0 ? "warmup (includes JIT compilation); " : "", note, "\"")
        end
    end
    write(joinpath(CACHE, "res", key * ".versions.txt"), versions * "\n")
    return value
end

function write_out(header::Vector{String}, rows, task, impl, size)
    mkpath(joinpath(CACHE, "out"))
    open(joinpath(CACHE, "out", "$(task)__jl_$(impl)__$(size).csv"), "w") do io
        println(io, join(header, ","))
        for r in rows
            println(io, join(fmt.(r), ","))
        end
    end
end
