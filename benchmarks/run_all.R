# Item 22 benchmark orchestrator. Run INSIDE the container from the repo root:
#   MSYS_NO_PATHCONV=1 docker compose run --rm -T pipeline Rscript benchmarks/run_all.R
# Every implementation runs in its own process (system2) so that peak RSS, runtime start-up and JIT costs are
# attributable. Workers write benchmarks/.cache/{res,out}/; this script measures start-up, runs the workers, checks
# numerical equivalence and writes benchmarks/results.{parquet,csv,md}. A failing worker is recorded
# (equiv_ok = NA, error in `note`) and the run continues; the script exits 0 whenever the results files are written.
suppressPackageStartupMessages({
  library(arrow)
})
Sys.setenv(TQ_BENCH_ROOT = Sys.getenv("TQ_BENCH_ROOT", "/workspace/benchmarks"))
if (!nzchar(Sys.getenv("TQ_BENCH_REPS"))) Sys.setenv(TQ_BENCH_REPS = "5")
source(file.path(Sys.getenv("TQ_BENCH_ROOT"), "R", "common.R"))
root <- bench_root()
REPS <- n_reps()
PY_PROJECT <- Sys.getenv("TQ_PY_PROJECT", "/workspace/env/python")
TIMEOUT <- 900

# Only this run's worker files are cleared (Parquet inputs and the Rcpp build cache are kept).
for (d in c("res", "out")) unlink(list.files(dirname(cache_dir(d, "x")), full.names = TRUE))

# ---- environment -----------------------------------------------------------------------------------------------
sh <- function(cmd) tryCatch(paste(system(cmd, intern = TRUE), collapse = " "), error = function(e) NA_character_)
env <- list(
  date = format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
  cpu = sh("lscpu | grep 'Model name' | sed 's/.*: *//'"),
  nproc = sh("nproc"),
  cpu_max = sh("cat /sys/fs/cgroup/cpu.max"),
  mem_max_gib = round(as.numeric(sh("cat /sys/fs/cgroup/memory.max")) / 2^30, 1),
  loadavg_start = sh("cat /proc/loadavg"),
  r = R.version.string,
  python = sh(sprintf("uv run --no-sync --project %s python -c 'import sys,polars,duckdb,pyarrow; print(sys.version.split()[0], \"polars\", polars.__version__, \"duckdb\", duckdb.__version__, \"pyarrow\", pyarrow.__version__)'", PY_PROJECT)),
  julia = sh("julia --version")
)
cat("== entorno\n")
for (k in names(env)) cat(sprintf("%-14s %s\n", k, env[[k]]))

# ---- helpers -----------------------------------------------------------------------------------------------------
lang_of <- function(impl) c(r = "R", py = "Python", jl = "Julia")[[sub("_.*", "", impl)]]
run_worker <- function(cmd, args) {
  t0 <- bench::hires_time()
  out <- suppressWarnings(system2(cmd, args, stdout = TRUE, stderr = TRUE, timeout = TIMEOUT))
  wall <- as.numeric(bench::hires_time() - t0)
  status <- attr(out, "status")
  list(ok = is.null(status) || status == 0, wall = wall, log = out)
}
failures <- list()

# ---- 1. runtime start-up (important for targets steps in other languages) ----------------------------------------
startup_specs <- list(
  r_bare = list("Rscript", c("-e", shQuote("invisible(1)"))),
  r_arrow_duckdb_dplyr = list("Rscript", c("-e", shQuote("suppressMessages({library(arrow); library(duckdb); library(dplyr)})"))),
  py_bare = list("uv", c("run", "--no-sync", "--project", PY_PROJECT, "python", "-c", "1")),
  py_polars_duckdb_pyarrow = list("uv", c("run", "--no-sync", "--project", PY_PROJECT, "python", "-c",
                                          shQuote("import polars, duckdb, pyarrow"))),
  jl_bare = list("julia", c("-e", "1")),
  jl_dataframes_arrow_duckdb = list("julia", c("-e", shQuote("using DataFrames, Arrow, DuckDB")))
)
startup <- do.call(rbind, lapply(names(startup_specs), function(impl) {
  s <- startup_specs[[impl]]
  do.call(rbind, lapply(0:REPS, function(rep) {
    r <- run_worker(s[[1]], s[[2]])
    data.frame(task = "startup", impl = impl, size = "-", rep = rep, seconds = if (r$ok) r$wall else NA_real_,
               mem_bytes = NA_real_, note = paste0(if (rep == 0) "warmup (cold page cache); " else "",
                                                   "wall time of the whole process incl. container-internal exec",
                                                   if (!r$ok) paste("; ERROR:", tail(r$log, 1)) else ""))
  }))
}))
cat("== start-up ok\n")

# ---- 2. data preparation (also benchmarks haven::read_sav) -------------------------------------------------------
prep <- run_worker("Rscript", file.path(root, "R", "prepare.R"))
cat(tail(prep$log, 1), "\n")
if (!prep$ok) stop("prepare.R failed:\n", paste(tail(prep$log, 20), collapse = "\n"))

# ---- 3. workers --------------------------------------------------------------------------------------------------
R_ <- function(script, impl, size) list(impl = paste0("r_", impl), size = size, cmd = "Rscript",
                                        args = c(file.path(root, "R", script), impl, size))
PY <- function(script, impl, size) list(impl = paste0("py_", impl), size = size, cmd = "uv",
                                        args = c("run", "--no-sync", "--project", PY_PROJECT, "python",
                                                 file.path(root, "python", script), impl, size))
JL <- function(script, impl, size) list(impl = paste0("jl_", impl), size = size, cmd = "julia",
                                        args = c("--threads=auto", file.path(root, "julia", script), impl, size))
specs <- list()
for (size in c("x1", "x25")) {
  specs <- c(specs, list(
    R_("task1_join.R", "dplyr", size), R_("task1_join.R", "arrow", size), R_("task1_join.R", "duckdb_sql", size),
    R_("task1_join.R", "duckdb_dbplyr", size), R_("task1_join.R", "datatable", size),
    PY("task1_join.py", "polars", size), PY("task1_join.py", "duckdb", size),
    JL("task1_join.jl", "dataframes", size), JL("task1_join.jl", "duckdb", size)
  ))
}
specs <- c(specs, list(
  R_("task2_microsim.R", "vec", "n1e6"), R_("task2_microsim.R", "rcpp", "n1e6"),
  PY("task2_microsim.py", "pyarrow", "n1e6"), PY("task2_microsim.py", "duckdb", "n1e6"),
  JL("task2_microsim.jl", "loop", "n1e6"), JL("task2_microsim.jl", "threads", "n1e6")
))
walls <- list()
for (s in specs) {
  r <- run_worker(s$cmd, s$args)
  key <- paste(s$impl, s$size)
  walls[[key]] <- r$wall
  cat(sprintf("%-6s %-18s %-5s %s (%.1f s proceso)\n", if (r$ok) "OK" else "FALLA", s$impl, s$size,
              if (r$ok) tail(r$log, 1) else "", r$wall))
  if (!r$ok) failures[[key]] <- paste(gsub("[\r\n\"]", " ", tail(r$log, 3)), collapse = " | ")
}

# ---- 4. collect timings ------------------------------------------------------------------------------------------
read_res <- function(f) {
  parts <- strsplit(sub("[.]csv$", "", basename(f)), "__")[[1]]
  d <- utils::read.csv(f, stringsAsFactors = FALSE, na.strings = "NA")
  vf <- sub("[.]csv$", ".versions.txt", f)
  data.frame(task = parts[1], impl = parts[2], size = parts[3], rep = d$rep, seconds = d$seconds,
             mem_bytes = as.numeric(d$mem_bytes), note = d$note,
             versions = if (file.exists(vf)) readLines(vf, n = 1) else NA_character_)
}
res_files <- list.files(dirname(cache_dir("res", "x")), pattern = "[.]csv$", full.names = TRUE)
timings <- do.call(rbind, lapply(res_files, read_res))
startup$versions <- NA_character_
timings <- rbind(timings, startup)
for (key in names(failures)) {
  p <- strsplit(key, " ")[[1]]
  task <- if (p[2] == "n1e6") "microsim" else "join_agg"
  timings <- rbind(timings, data.frame(task = task, impl = p[1], size = p[2], rep = NA_integer_, seconds = NA_real_,
                                       mem_bytes = NA_real_, note = paste("ERROR:", failures[[key]]),
                                       versions = NA_character_))
}

# ---- 5. equivalence ----------------------------------------------------------------------------------------------
read_out <- function(task, impl, size) {
  f <- cache_dir("out", paste0(paste(task, impl, size, sep = "__"), ".csv"))
  if (!file.exists(f)) return(NULL)
  utils::read.csv(f, stringsAsFactors = FALSE)
}
equiv <- list()
TOL_JOIN <- 1e-8
for (size in c("x1", "x25")) {
  ref <- read_out("join_agg", "r_dplyr", size)
  impls <- unique(timings$impl[timings$task == "join_agg" & timings$size == size])
  for (impl in impls) {
    o <- read_out("join_agg", impl, size)
    key <- paste("join_agg", impl, size)
    if (is.null(o) || is.null(ref)) { equiv[[key]] <- list(ok = NA, note = "no output"); next }
    m <- merge(ref, o, by = c("region", "area"), suffixes = c(".ref", ".x"))
    same_groups <- nrow(m) == nrow(ref) && nrow(m) == nrow(o)
    cols <- c("n", "sum_w", "wm_edad", "wm_educ", "wm_hhsize")
    rel <- max(vapply(cols, function(cl) {
      a <- m[[paste0(cl, ".x")]]; b <- m[[paste0(cl, ".ref")]]
      max(abs(a - b) / pmax(abs(b), 1e-12))
    }, numeric(1)))
    ok <- same_groups && rel <= TOL_JOIN && all(m$n.x == m$n.ref)
    equiv[[key]] <- list(ok = ok, note = sprintf("equiv vs r_dplyr: groups=%d max_rel_diff=%.2e (tol %.0e)",
                                                 nrow(m), rel, TOL_JOIN))
  }
}
# x25 sanity: means unchanged, n and sums x25 (reference implementation only)
r1 <- read_out("join_agg", "r_dplyr", "x1")
r25 <- read_out("join_agg", "r_dplyr", "x25")
x25_ok <- !is.null(r1) && !is.null(r25) && all(r25$n == 25 * r1$n) &&
  max(abs(r25$wm_edad - r1$wm_edad) / r1$wm_edad) < 1e-8 && max(abs(r25$sum_w / 25 - r1$sum_w) / r1$sum_w) < 1e-8
cat("x25 sanity (n x25, means unchanged):", x25_ok, "\n")

# Microsimulation: analytic expectation over the exact initial distribution (age0 uniform on 20..79, sex Bernoulli 0.5)
A <- -3; B <- 0.03; C <- 0.3; STEPS <- 10
strata <- expand.grid(age0 = 20:79, sex = 0:1)
pmat <- t(sapply(seq_len(nrow(strata)), function(i) plogis(A + B * (strata$age0[i] + 1:STEPS) + C * strata$sex[i])))
disc <- 1.03^(1:STEPS)
an <- list(
  mean_events = mean(rowSums(pmat)),
  mean_cost = mean(pmat %*% (1500 / disc) + sum(100 / disc)),
  prop_any = mean(1 - apply(1 - pmat, 1, prod))
)
poibin <- function(p) { d <- 1; for (pi in p) d <- c(d * (1 - pi), 0) + c(0, d * pi); d }
an_dist <- rowMeans(apply(pmat, 1, poibin))
cat(sprintf("analitico: E[eventos]=%.6f E[costo]=%.4f P(alguno)=%.6f\n", an$mean_events, an$mean_cost, an$prop_any))
ms_ref <- read_out("microsim", "r_vec", "n1e6")
for (impl in unique(timings$impl[timings$task == "microsim"])) {
  o <- read_out("microsim", impl, "n1e6")
  key <- paste("microsim", impl, "n1e6")
  if (is.null(o)) { equiv[[key]] <- list(ok = NA, note = "no output"); next }
  v <- setNames(o$value, o$metric)
  n <- v[["n"]]
  z <- c(events = (v[["mean_events"]] - an$mean_events) / (v[["sd_events"]] / sqrt(n)),
         cost = (v[["mean_cost"]] - an$mean_cost) / (v[["sd_cost"]] / sqrt(n)),
         any = (v[["prop_any"]] - an$prop_any) / sqrt(an$prop_any * (1 - an$prop_any) / n))
  rel <- c(events = v[["mean_events"]] / an$mean_events - 1, cost = v[["mean_cost"]] / an$mean_cost - 1,
           any = v[["prop_any"]] / an$prop_any - 1)
  obs <- v[paste0("k", 0:STEPS)]
  # chi-square goodness of fit vs the analytic Poisson-binomial mixture, tail k >= 8 pooled
  e <- an_dist * n
  obs_p <- c(obs[1:8], sum(obs[9:11]))
  e_p <- c(e[1:8], sum(e[9:11]))
  chi_p <- pchisq(sum((obs_p - e_p)^2 / e_p), df = length(e_p) - 1, lower.tail = FALSE)
  tv <- 0.5 * sum(abs(obs / n - an_dist))
  identical_ref <- !is.null(ms_ref) && identical(o$value, ms_ref$value)
  ok <- all(abs(z) <= 4) && chi_p > 1e-4
  equiv[[key]] <- list(ok = ok, note = sprintf(paste0(
    "equiv vs analytic: z(events,cost,any)=%.2f,%.2f,%.2f; rel_diff=%.1e,%.1e,%.1e (<=1e-3: %s); ",
    "chi2 p=%.3g; TV=%.1e; bit-identical to r_vec: %s"),
    z[1], z[2], z[3], rel[1], rel[2], rel[3], all(abs(rel) <= 1e-3), chi_p, tv, identical_ref))
}

# ---- 6. assemble -------------------------------------------------------------------------------------------------
n_rows_of <- function(task, size) switch(task, join_agg = c(x1 = 135045, x25 = 3376125)[[size]],
                                         microsim = 1e6, read_sav = 135045 + 37390, NA_real_)
timings$language <- vapply(timings$impl, lang_of, character(1))
timings$n_rows <- mapply(n_rows_of, timings$task, timings$size)
keys <- paste(timings$task, timings$impl, timings$size)
timings$equiv_ok <- vapply(keys, function(k) if (!is.null(equiv[[k]])) equiv[[k]]$ok else NA, logical(1))
timings$note <- mapply(function(nt, k, impl, size) {
  extra <- c(if (!is.null(equiv[[k]])) equiv[[k]]$note,
             if (!is.null(walls[[paste(impl, size)]])) sprintf("process_wall_s=%.2f", walls[[paste(impl, size)]]))
  paste(c(nt, extra), collapse = "; ")
}, timings$note, keys, timings$impl, timings$size, USE.NAMES = FALSE)
timings$impl <- ifelse(timings$size %in% c("x1", "x25"), paste0(timings$impl, "@", timings$size), timings$impl)
results <- timings[, c("task", "impl", "language", "rep", "seconds", "mem_bytes", "n_rows", "equiv_ok", "note",
                       "versions")]
results <- results[order(results$task, results$impl, results$rep), ]
rownames(results) <- NULL
write_parquet(results, file.path(root, "results.parquet"))
utils::write.csv(results, file.path(root, "results.csv"), row.names = FALSE)

# ---- 7. results.md -----------------------------------------------------------------------------------------------
md_table <- function(df) c(paste0("| ", paste(names(df), collapse = " | "), " |"),
                           paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|"),
                           apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")))
f3 <- function(x) ifelse(is.na(x), "NA", formatC(x, digits = 3, format = "fg", flag = "#"))
rss_of <- function(notes) { m <- regmatches(notes, regexpr("rss_peak_mb=[0-9]+", notes)); if (length(m)) sub(".*=", "", m[1]) else "NA" }
summ <- do.call(rbind, lapply(split(results, results$impl), function(d) {
  t <- d[!is.na(d$rep) & d$rep > 0, ]
  w <- d[!is.na(d$rep) & d$rep == 0, ]
  data.frame(task = d$task[1], impl = d$impl[1], lenguaje = d$language[1],
             mediana_s = f3(median(t$seconds)), min_s = f3(min(t$seconds)), max_s = f3(max(t$seconds)),
             reps = nrow(t), warmup_s = f3(if (nrow(w)) w$seconds[1] else NA),
             mem_MB = if (all(is.na(t$mem_bytes))) "NA" else f3(median(t$mem_bytes, na.rm = TRUE) / 2^20),
             rss_pico_MB = rss_of(d$note), equiv_ok = as.character(d$equiv_ok[1]),
             med_num = median(t$seconds))
}))
summ <- summ[order(summ$task, summ$med_num), ]
tab <- function(task) md_table(summ[summ$task == task, setdiff(names(summ), c("task", "med_num"))])
eq_notes <- vapply(names(equiv), function(k) paste0("- `", k, "`: ", equiv[[k]]$note), character(1))
md <- c(
  "# Resultados de benchmarks (ítem 22)", "",
  "Generado automáticamente por `benchmarks/run_all.R`; no editar a mano (se sobrescribe en cada corrida).", "",
  "## Entorno", "",
  paste0("- ", names(env), ": ", unlist(env)),
  paste0("- loadavg al terminar: ", sh("cat /proc/loadavg")),
  paste0("- Repeticiones por implementación: ", REPS, " + 1 de calentamiento (rep 0; en Julia incluye compilación JIT)."),
  "- Advertencia: el host Windows (WSL2 + Docker Desktop) ejecuta otros procesos durante la corrida; las diferencias < 1.5x entre implementaciones no son concluyentes. Cada implementación corre en su propio proceso.",
  "- `mem_MB` es la medida nativa de cada herramienta y NO es comparable entre lenguajes: `bench::mark` (solo heap de R), `tracemalloc` (solo heap de Python), pool de Arrow (pyarrow), `@timed` (bytes asignados por Julia). `rss_pico_MB` (VmHWM / getrusage / Sys.maxrss) sí es comparable: pico de memoria residente de todo el proceso.", "",
  "## Arranque de runtimes (proceso completo, s)", "", tab("startup"), "",
  "## Lectura SPSS (`haven::read_sav`, RECH0 + RECH1)", "", tab("read_sav"), "",
  "## Tarea 1: join por HHID + agregación ponderada por región × área", "",
  "`@x1` = 135 045 personas reales (ENDES 2024, módulo 1629); `@x25` = 3 376 125 filas (cada persona repetida 25 veces). Todas leen Parquet salvo `jl_dataframes` (Arrow IPC mapeado en memoria, porque Arrow.jl no lee Parquet).", "",
  tab("join_agg"), "",
  "## Tarea 2: microsimulación de 1e6 individuos × 10 pasos", "",
  sprintf("Expectativa analítica: E[eventos] = %.6f; E[costo] = %.4f; P(al menos un evento) = %.6f.", an$mean_events, an$mean_cost, an$prop_any), "",
  tab("microsim"), "",
  "## Equivalencia", "",
  "- Tarea 1: cada implementación contra `r_dplyr` del mismo tamaño; mismos grupos, `n` exacto y diferencia relativa máxima ≤ 1e-8 en suma de pesos y medias ponderadas.",
  paste0("- Control x25 (n ×25, medias iguales a x1): ", x25_ok),
  "- Tarea 2: los generadores difieren (Mersenne-Twister en R/Rcpp, `pc.random` en pyarrow, `random()` de DuckDB, Xoshiro256++ en Julia), así que la comparación es distribucional: |z| ≤ 4 contra la expectativa analítica en media de eventos, media de costo y proporción con ≥ 1 evento, y χ² de bondad de ajuste de la distribución de conteos (0–10) contra la mezcla Poisson-binomial analítica (p > 1e-4). La tolerancia relativa 1e-3 se informa, pero con N = 1e6 el error estándar relativo de la media de eventos es ≈ 7e-4, así que 1e-3 equivale a ~1.5 EE y no sirve como criterio de aceptación. `r_rcpp` consume el mismo flujo de R que `r_vec` y debe ser bit-idéntico.",
  "", eq_notes, "",
  if (length(failures)) c("## Fallas", "", paste0("- `", names(failures), "`: ", unlist(failures)), "") else
    c("## Fallas", "", "- Ninguna.", ""),
  "## Ausencias (no benchmarkeado por ausencia en la imagen)", "",
  "- numpy (no está en `env/python/uv.lock`): la versión Python vectorizada de la microsimulación usa `pyarrow.compute`.",
  "- Lector Parquet para Julia (Parquet2.jl): `jl_dataframes` lee Arrow IPC.",
  "- duckplyr, collapse y profvis (R): no están instalados.",
  "- data.table SÍ está instalado (1.18.x) como dependencia transitiva, aunque no figura en `env/r/packages.txt`; se benchmarkeó con `setDTthreads(0)`."
)
writeLines(md, file.path(root, "results.md"))

n_fail <- length(failures)
n_neq <- sum(vapply(equiv, function(e) isFALSE(e$ok), logical(1)))
cat(sprintf("run_all OK: %d filas en benchmarks/results.parquet; %d implementaciones; %d fallas; %d no equivalentes\n",
            nrow(results), length(unique(results$impl)), n_fail, n_neq))
