# Task 2: microsimulation of N = 1e6 individuals, 10 annual steps, fixed model and seed (identical in every language):
#   age0 = 20 + floor(60 u), sex = 1{u < 0.5}; each step t: age += 1; p = plogis(a + b*age + c*sex);
#   event ~ Bernoulli(p); events += event; cost += (1500*event + 100) / 1.03^t
#   a = -3, b = 0.03, c = 0.3, seed = 20261016
# Usage: Rscript benchmarks/R/task2_microsim.R <impl> [size]   impl in vec|rcpp
source(file.path(Sys.getenv("TQ_BENCH_ROOT", "/workspace/benchmarks"), "R", "common.R"))

args <- parse_args()
N <- as.integer(Sys.getenv("TQ_MICROSIM_N", "1000000"))
STEPS <- 10L
A <- -3
B <- 0.03
C <- 0.3
SEED <- 20261016L

# Clean R interface: same signature for both engines, so callers (and tests) never see C++.
microsim_r <- function(n, steps, a, b, c) {
  age <- 20 + floor(60 * runif(n))
  sex <- as.numeric(runif(n) < 0.5)
  events <- numeric(n)
  cost <- numeric(n)
  for (t in seq_len(steps)) {
    age <- age + 1
    ev <- as.numeric(runif(n) < plogis(a + b * age + c * sex))
    events <- events + ev
    cost <- cost + (1500 * ev + 100) / 1.03^t
  }
  list(events = events, cost = cost)
}

note <- ""
if (args$impl == "rcpp") {
  t0 <- bench::hires_time()
  Rcpp::sourceCpp(file.path(bench_root(), "R", "microsim.cpp"), cacheDir = cache_dir("rcpp"))
  note <- sprintf("sourceCpp compile/load s=%.2f (cached in benchmarks/.cache/rcpp)", bench::hires_time() - t0)
}
engine <- switch(args$impl, vec = microsim_r, rcpp = microsim_rcpp, stop("unknown impl: ", args$impl))

run <- function() {
  set.seed(SEED, kind = "Mersenne-Twister", normal.kind = "Inversion")
  engine(N, STEPS, A, B, C)
}
sim <- time_impl(run, "microsim", args$impl, "n1e6", c("Rcpp", "bench"), extra_note = note)

summ <- function(sim) {
  k <- tabulate(as.integer(sim$events) + 1L, nbins = STEPS + 1L)
  data.frame(
    metric = c("n", "mean_events", "sd_events", "mean_cost", "sd_cost", "prop_any", paste0("k", 0:STEPS)),
    value = c(length(sim$events), mean(sim$events), sd(sim$events), mean(sim$cost), sd(sim$cost),
              mean(sim$events > 0), k)
  )
}
out <- summ(sim)
write_out(out, "microsim", args$impl, "n1e6")
cat(sprintf("microsim %s ok: mean_events=%.6f mean_cost=%.4f\n", args$impl, out$value[2], out$value[4]))
