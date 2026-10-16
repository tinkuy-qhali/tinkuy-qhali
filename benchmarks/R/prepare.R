# Unzip ENDES 2024 module 1629 (read-only from raw/) into benchmarks/.cache/ and convert once to Parquet.
# The SPSS read time is itself a benchmark row (task "read_sav"). NA handling is decided HERE, once, for every
# language: user-missing codes become NA so no implementation has to re-encode them.
#   HV105 (edad): 98 = "No sabe" -> NA; 97 = "Mayores de 96" is a top-code and stays as 97.
#   HV108 (anios de estudio): 98 = "No sabe" -> NA.
#   HV005 (factor de ponderacion) is stored x 1e6 by INEI -> divided by 1e6.
source(file.path(Sys.getenv("TQ_BENCH_ROOT", "/workspace/benchmarks"), "R", "common.R"))
suppressPackageStartupMessages({
  library(haven)
  library(arrow)
})

zip_path <- Sys.getenv("TQ_ENDES_ZIP", "/workspace/raw/inei-endes/2024/1629/968-Modulo1629.zip")
sav_dir <- cache_dir("endes1629")
dir.create(sav_dir, showWarnings = FALSE)
members <- grep("RECH[01]_2024[.]sav$", utils::unzip(zip_path, list = TRUE)$Name, value = TRUE)
utils::unzip(zip_path, files = members, exdir = sav_dir, junkpaths = TRUE, overwrite = TRUE)

read_both <- function() {
  list(
    hogar = read_sav(file.path(sav_dir, "RECH0_2024.sav"),
                     col_select = c("HHID", "HV001", "HV005", "HV024", "HV025", "HV009", "HV040")),
    persona = read_sav(file.path(sav_dir, "RECH1_2024.sav"),
                       col_select = c("HHID", "HVIDX", "HV104", "HV105", "HV108"))
  )
}
raw <- time_impl(read_both, "read_sav", "haven", "x1", c("haven", "arrow"),
                 extra_note = "haven::read_sav of RECH0 (37390x7) + RECH1 (135045x5), col_select")

na_code <- function(x, codes) {
  x <- as.numeric(zap_labels(x))
  x[x %in% codes] <- NA_real_
  x
}
hogares <- data.frame(
  HHID = raw$hogar$HHID,
  conglomerado = as.integer(raw$hogar$HV001),
  w = as.numeric(raw$hogar$HV005) / 1e6,
  region = as.integer(zap_labels(raw$hogar$HV024)),
  area = as.integer(zap_labels(raw$hogar$HV025)),
  hhsize = as.numeric(raw$hogar$HV009),
  altitud = as.numeric(raw$hogar$HV040)
)
personas <- data.frame(
  HHID = raw$persona$HHID,
  idx = as.integer(raw$persona$HVIDX),
  sexo = as.integer(zap_labels(raw$persona$HV104)),
  edad = na_code(raw$persona$HV105, 98),
  educ = na_code(raw$persona$HV108, 98)
)
stopifnot(!anyDuplicated(hogares$HHID), all(personas$HHID %in% hogares$HHID))

write_parquet(hogares, cache_dir("hogares.parquet"))
write_parquet(personas, cache_dir("personas_x1.parquet"))
# x25: every person repeated 25 times (3.4 M rows). Same households, so weighted means are unchanged and sums x25.
rep25 <- personas[rep(seq_len(nrow(personas)), 25), ]
rep25$copia <- rep(1:25, each = nrow(personas))
write_parquet(rep25, cache_dir("personas_x25.parquet"))
# Arrow IPC copies for Julia: Arrow.jl reads IPC (memory-mapped) but not Parquet, and no Parquet reader is in the
# image's Julia environment. Uncompressed so Arrow.jl can map it without decoding.
write_feather(hogares, cache_dir("hogares.arrow"), compression = "uncompressed")
write_feather(personas, cache_dir("personas_x1.arrow"), compression = "uncompressed")
write_feather(rep25, cache_dir("personas_x25.arrow"), compression = "uncompressed")
cat(sprintf("prepare ok: hogares=%d personas=%d x25=%d NA edad=%d NA educ=%d\n", nrow(hogares), nrow(personas),
            nrow(rep25), sum(is.na(personas$edad)), sum(is.na(personas$educ))))
