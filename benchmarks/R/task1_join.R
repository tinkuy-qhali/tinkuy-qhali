# Task 1 (ENDES 2024, modulo 1629): personas (RECH1) JOIN hogares (RECH0) por HHID + agregacion ponderada por
# region x area. Every implementation starts from the SAME Parquet files and returns the same columns:
#   region, area, n, sum_w, wm_edad, wm_educ, wm_hhsize
# Weighted means drop NA in the numerator AND the denominator (sum of weights over non-missing rows only).
# Usage: Rscript benchmarks/R/task1_join.R <impl> <size>   impl in dplyr|arrow|duckdb_sql|duckdb_dbplyr|datatable
source(file.path(Sys.getenv("TQ_BENCH_ROOT", "/workspace/benchmarks"), "R", "common.R"))
suppressPackageStartupMessages({
  library(dplyr)
  library(arrow)
})

args <- parse_args()
p_path <- cache_dir(paste0("personas_", args$size, ".parquet"))
h_path <- cache_dir("hogares.parquet")

# One tidy summary used by dplyr (in memory), arrow (lazy) and dbplyr (lazy SQL): same code, three engines.
summarise_weighted <- function(.data) {
  .data |>
    group_by(region, area) |>
    summarise(
      n = n(),
      sum_w = sum(w),
      swx_edad = sum(w * edad, na.rm = TRUE), sw_edad = sum(if_else(is.na(edad), 0, w)),
      swx_educ = sum(w * educ, na.rm = TRUE), sw_educ = sum(if_else(is.na(educ), 0, w)),
      swx_hh = sum(w * hhsize, na.rm = TRUE), sw_hh = sum(if_else(is.na(hhsize), 0, w)),
      .groups = "drop"
    ) |>
    mutate(wm_edad = swx_edad / sw_edad, wm_educ = swx_educ / sw_educ, wm_hhsize = swx_hh / sw_hh) |>
    select(region, area, n, sum_w, wm_edad, wm_educ, wm_hhsize)
}

finish <- function(df) {
  df <- as.data.frame(df)
  df$n <- as.numeric(df$n)
  df[order(df$region, df$area), ]
}

impls <- list(
  dplyr = function() {
    personas <- read_parquet(p_path)
    hogares <- read_parquet(h_path)
    personas |> inner_join(hogares, by = "HHID") |> summarise_weighted() |> finish()
  },
  arrow = function() {
    # Lazy: nothing is read until collect(); Acero does the join and the aggregation.
    open_dataset(p_path) |>
      inner_join(open_dataset(h_path), by = "HHID") |>
      summarise_weighted() |>
      collect() |>
      finish()
  },
  duckdb_sql = function() {
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
    sql <- sprintf("
      SELECT region, area, count(*) AS n, sum(w) AS sum_w,
             sum(w * edad) / sum(CASE WHEN edad IS NULL THEN 0 ELSE w END) AS wm_edad,
             sum(w * educ) / sum(CASE WHEN educ IS NULL THEN 0 ELSE w END) AS wm_educ,
             sum(w * hhsize) / sum(CASE WHEN hhsize IS NULL THEN 0 ELSE w END) AS wm_hhsize
      FROM read_parquet('%s') p JOIN read_parquet('%s') h USING (HHID)
      GROUP BY region, area", p_path, h_path)
    finish(DBI::dbGetQuery(con, sql))
  },
  duckdb_dbplyr = function() {
    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
    personas <- tbl(con, dplyr::sql(sprintf("SELECT * FROM read_parquet('%s')", p_path)))
    hogares <- tbl(con, dplyr::sql(sprintf("SELECT * FROM read_parquet('%s')", h_path)))
    personas |> inner_join(hogares, by = "HHID") |> summarise_weighted() |> collect() |> finish()
  },
  datatable = function() {
    personas <- data.table::as.data.table(read_parquet(p_path))
    hogares <- data.table::as.data.table(read_parquet(h_path))
    j <- hogares[personas, on = "HHID", nomatch = NULL]
    out <- j[, .(
      n = .N, sum_w = sum(w),
      wm_edad = sum(w * edad, na.rm = TRUE) / sum(w[!is.na(edad)]),
      wm_educ = sum(w * educ, na.rm = TRUE) / sum(w[!is.na(educ)]),
      wm_hhsize = sum(w * hhsize, na.rm = TRUE) / sum(w[!is.na(hhsize)])
    ), by = .(region, area)]
    finish(out)
  }
)

if (!args$impl %in% names(impls)) stop("unknown impl: ", args$impl)
pkgs <- switch(args$impl,
  dplyr = c("dplyr", "arrow"), arrow = c("dplyr", "arrow"), duckdb_sql = c("duckdb", "DBI", "arrow"),
  duckdb_dbplyr = c("duckdb", "dbplyr", "dplyr"), datatable = c("data.table", "arrow")
)
note <- ""
if (args$impl == "datatable") {
  data.table::setDTthreads(0L) # default is 50% of logical CPUs; use all, like DuckDB/arrow/polars
  note <- paste0("data.table threads=", data.table::getDTthreads(), "; transitive dependency, not in env/r/packages.txt")
}
res <- time_impl(impls[[args$impl]], "join_agg", args$impl, args$size, pkgs, extra_note = note)
write_out(res, "join_agg", args$impl, args$size)
cat(sprintf("join_agg %s %s ok: %d groups, n=%.0f\n", args$impl, args$size, nrow(res), sum(res$n)))
