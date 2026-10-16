# Shared helpers for the item-22 benchmarks. Sourced by every R script; no side effects beyond defining functions.
# Contract with the orchestrator (run_all.R): each worker writes
#   benchmarks/.cache/res/<task>__<lang>_<impl>__<size>.csv  (rep, seconds, mem_bytes, note)  -> timings
#   benchmarks/.cache/out/<task>__<lang>_<impl>__<size>.csv  (one row per group / metric)      -> results for equivalence
#   benchmarks/.cache/res/<task>__<lang>_<impl>__<size>.versions.txt                          -> one-line version string

bench_root <- function() {
  root <- Sys.getenv("TQ_BENCH_ROOT", "/workspace/benchmarks")
  stopifnot(dir.exists(root))
  root
}
cache_dir <- function(...) {
  path <- file.path(bench_root(), ".cache", ...)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  path
}

n_reps <- function() as.integer(Sys.getenv("TQ_BENCH_REPS", "5"))

# Peak resident set size of this process (Linux), in bytes. Comparable across R, Python and Julia.
rss_peak_bytes <- function() {
  line <- grep("^VmHWM:", readLines("/proc/self/status"), value = TRUE)
  as.numeric(gsub("[^0-9]", "", line)) * 1024
}

pkg_versions <- function(pkgs) {
  v <- vapply(pkgs, function(p) as.character(utils::packageVersion(p)), character(1))
  paste0("R ", getRversion(), "; ", paste(pkgs, v, collapse = "; "))
}

# Time `fun` once as warm-up (rep 0) and then n_reps() times with bench::mark (memory = R-heap allocations only).
# Returns the value of the last call so the caller can write it for the equivalence test.
time_impl <- function(fun, task, impl, size, pkgs, extra_note = "") {
  t0 <- bench::hires_time()
  value <- fun()
  warm <- as.numeric(bench::hires_time() - t0)
  bm <- bench::mark(value <- fun(), iterations = n_reps(), memory = TRUE, check = FALSE, filter_gc = FALSE,
                    time_unit = "s")
  secs <- as.numeric(bm$time[[1]])
  mem <- as.numeric(bm$mem_alloc)
  note <- paste0("mem=bench::mark R-heap alloc (excludes C++/Arrow/DuckDB buffers); rss_peak_mb=",
                 round(rss_peak_bytes() / 2^20), if (nzchar(extra_note)) paste0("; ", extra_note))
  res <- data.frame(rep = c(0L, seq_along(secs)), seconds = c(warm, secs), mem_bytes = c(NA, rep(mem, length(secs))),
                    note = c(paste("warmup", note, sep = "; "), rep(note, length(secs))))
  key <- paste(task, paste0("r_", impl), size, sep = "__")
  utils::write.csv(res, cache_dir("res", paste0(key, ".csv")), row.names = FALSE)
  writeLines(pkg_versions(pkgs), cache_dir("res", paste0(key, ".versions.txt")))
  value
}

write_out <- function(df, task, impl, size) {
  df <- as.data.frame(df)
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], function(x) trimws(formatC(x, digits = 17, format = "g")))
  utils::write.csv(df, cache_dir("out", paste0(paste(task, paste0("r_", impl), size, sep = "__"), ".csv")), row.names = FALSE)
}

parse_args <- function() {
  a <- commandArgs(trailingOnly = TRUE)
  list(impl = a[[1]], size = if (length(a) >= 2) a[[2]] else "x1")
}
