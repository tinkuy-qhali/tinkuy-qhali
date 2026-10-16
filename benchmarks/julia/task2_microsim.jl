# Task 2 in Julia (model in benchmarks/R/task2_microsim.R): a plain nested loop, no vectorisation needed.
# Usage: julia --threads=auto benchmarks/julia/task2_microsim.jl <loop|threads>
#   loop:    one Xoshiro stream, individual-major loop, no temporaries.
#   threads: same kernel over Threads.nthreads() chunks, one Xoshiro(seed + chunk) per chunk (reproducible for a
#            fixed thread count; results differ from `loop` only by RNG stream).
using Random, Statistics
include(joinpath(@__DIR__, "_bench.jl"))

const IMPL = ARGS[1]
const N = parse(Int, get(ENV, "TQ_MICROSIM_N", "1000000"))
const STEPS, A, B, C, SEED = 10, -3.0, 0.03, 0.3, 20261016

function simulate!(events, cost, idx, rng)
    @inbounds for i in idx
        age = 20.0 + floor(60.0 * rand(rng))
        sex = rand(rng) < 0.5 ? 1.0 : 0.0
        ev = 0.0
        c = 0.0
        for t in 1:STEPS
            age += 1.0
            p = 1.0 / (1.0 + exp(-(A + B * age + C * sex)))
            e = rand(rng) < p ? 1.0 : 0.0
            ev += e
            c += (1500.0 * e + 100.0) / 1.03^t
        end
        events[i] = ev
        cost[i] = c
    end
    return nothing
end

function microsim_loop()
    events = zeros(N)
    cost = zeros(N)
    simulate!(events, cost, 1:N, Xoshiro(SEED))
    return events, cost
end

function microsim_threads()
    events = zeros(N)
    cost = zeros(N)
    chunks = collect(Iterators.partition(1:N, cld(N, Threads.nthreads())))
    Threads.@threads for k in eachindex(chunks)
        simulate!(events, cost, chunks[k], Xoshiro(SEED + k))
    end
    return events, cost
end

f = IMPL == "loop" ? microsim_loop : IMPL == "threads" ? microsim_threads : error("unknown impl $IMPL")
versions = "Julia $(VERSION); Random stdlib (Xoshiro256++)"
events, cost = time_impl(f, "microsim", IMPL, "n1e6", versions)
k = [count(==(j), events) for j in 0:STEPS]
vals = Any[N, mean(events), std(events), mean(cost), std(cost), mean(events .> 0)]
keys = vcat(["n", "mean_events", "sd_events", "mean_cost", "sd_cost", "prop_any"], ["k$j" for j in 0:STEPS])
write_out(["metric", "value"], [(keys[i], Float64(v)) for (i, v) in enumerate(vcat(vals, k))], "microsim", IMPL, "n1e6")
println("microsim $IMPL ok: mean_events=$(round(mean(events); digits = 6)) mean_cost=$(round(mean(cost); digits = 4))")
