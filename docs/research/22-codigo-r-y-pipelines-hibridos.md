---
item: 22
titulo: Código R rápido y legible, y pipelines híbridos R/Python/Julia
modelo: opus
esfuerzo: high
fecha: 2026-10-16
estado: borrador
---
# 22 — Código R rápido y legible, y pipelines híbridos

## Pregunta
Cómo escribir R rápido y legible, dónde gana Julia y cómo orquestar etapas multilenguaje con `targets` y Parquet.

## Hallazgos
- La guía tidyverse se aplica con `styler` y `lintr` (https://style.tidyverse.org/, 2026-10-16). `precommit` trae los hooks `style-files`, `lintr` y `roxygenize` (https://lorenzwalthert.github.io/precommit/articles/available-hooks.html, 2026-10-16).
- Join ponderado sobre ENDES 2024, 3,4 M filas, en segundos: polars 0,19; DuckDB 0,39–0,51; arrow perezoso 0,43; data.table 1,05; dplyr 1,69 (RSS pico 1,35 GB). Las 18 variantes coinciden (diferencia ≤ 4e-13) ([resultados](../../benchmarks/results.md)). arrow difiere el cálculo hasta `collect()` (https://arrow.apache.org/docs/r/articles/data_wrangling.html, 2026-10-16).
- dbplyr sobre DuckDB tardó 63 % más que el SQL directo ([resultados](../../benchmarks/results.md)). DuckDB lee Parquet con `tbl()` (https://duckdb.org/docs/current/clients/r.html, 2026-10-16). `duckdb_register_arrow` no copia los datos (https://r.duckdb.org/reference/duckdb_register_arrow.html, 2026-10-16).
- Microsimulación de 1e6 × 10, en segundos: R vectorizado 0,74; Rcpp 0,33, bit-idéntico al R vectorizado; pyarrow 0,28; Julia en bucle 0,21; Julia multihilo 0,06; DuckDB 1,04. Todas pasan z y χ² contra la expectativa analítica ([resultados](../../benchmarks/results.md)). `bench::mark` exige por defecto resultados iguales (https://bench.r-lib.org/, 2026-10-16).
- Julia gana 1,5× a Rcpp (dentro del ruido) y 5,5× con hilos, que hay que activar al lanzar Julia (https://docs.julialang.org/en/v1/manual/multi-threading/, 2026-10-16). En join pierde 4× frente a polars y compila 6–9 s en cada proceso ([resultados](../../benchmarks/results.md)).
- `profmem` no ve las asignaciones de Arrow ni de DuckDB (https://cran.r-project.org/web/packages/profmem/vignettes/profmem.html, 2026-10-16), por eso se compara el RSS pico. `profvis` perfila el tiempo (https://profvis.r-lib.org/, 2026-10-16).
- `targets` acepta `format = "parquet"` para data frames (https://docs.ropensci.org/targets/reference/tar_target.html, 2026-10-16).
- `srvyr` ofrece sintaxis dplyr sobre `survey` (https://cran.r-project.org/web/packages/srvyr/vignettes/srvyr-vs-survey.html, 2026-10-16).

## Decisión propuesta
- Decisión: escalera dplyr → arrow/DuckDB perezoso con `collect()` lo más tarde posible → Rcpp encapsulado tras una función R con test de equivalencia | Alternativa descartada: data.table como motor por defecto | Confianza: media.
- Decisión: etapas Python o Julia como targets `format = "file"` que lanzan un proceso y entregan Parquet; JuliaCall y reticulate solo para llamadas pequeñas | Alternativa descartada: puentes en proceso | Confianza: media.
- Decisión: Julia solo para simulación multihilo; declarar `data.table` en `env/r/packages.txt` | Alternativa descartada: Julia por defecto | Confianza: media.

## Riesgos y provisional
- Una máquina ruidosa; Rcpp usó un hilo; Julia leyó Arrow IPC. Fase 3 repite.
- Faltan numpy, duckplyr y profvis; los hooks no se probaron **[provisional]**.

## Fuentes nuevas
- https://duckplyr.tidyverse.org/ — dplyr sobre DuckDB, pendiente de benchmark.
- https://julialang.github.io/PackageCompiler.jl/dev/ — sysimages para reducir la compilación de Julia en cada proceso.
