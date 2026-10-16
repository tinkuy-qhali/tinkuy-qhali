# ADR 0012 — Mapa de lenguajes por tipo de tarea y escalera de optimización con evidencia

- **Estado:** aceptado (los umbrales se recalibran con el benchmark de la Ronda 1)
- **Fecha:** 2026-10-16
- **Fuente:** Fase 1, informe 22 y `benchmarks/results.md` (186 mediciones, 31 implementaciones, 0 fallas, 0 no equivalentes; contenedor con 7 CPU / 22 GiB, host con otros procesos); informes 23 y 26

## Contexto

La especificación proponía un mapa de lenguajes a validar con benchmark: wrangling en DuckDB/arrow desde R o Python, inferencia con diseño muestral en R, ML en Python, simulación numérica en Julia "que sustituye a C++ salvo que un benchmark muestre lo contrario". El ítem 22 corrió dos tareas reproducibles dentro de la imagen sobre ENDES 2024 módulo 1629:

| Tarea | Implementación | Mediana (s) |
|---|---|---|
| Join ponderado + agregación, 3,4 M filas | polars (Python) | 0,19 |
| | DuckDB (Python) | 0,39 |
| | DuckDB SQL desde R | 0,43 |
| | arrow perezoso (R) | 0,43 |
| | DuckDB vía dbplyr (R) | 0,70 |
| | Julia DataFrames | 0,79 (+ 6–9 s de JIT por proceso) |
| | data.table (R) | 1,05 |
| | dplyr en memoria (R) | 1,69 |
| Microsimulación 1e6 × 10 pasos | Julia multihilo | 0,06 |
| | Julia bucle (1 hilo) | 0,21 |
| | pyarrow.compute | 0,28 |
| | Rcpp (1 hilo) | 0,33 |
| | R vectorizado | 0,74 |
| | DuckDB SQL | 1,04 |

Las 18 variantes del join coinciden (diferencia relativa ≤ 4e-13); las de microsimulación pasan pruebas z y χ² contra la expectativa analítica (la tolerancia 1e-3 no sirve como criterio: es del orden del error Monte Carlo). Diferencias < 1,5× no son concluyentes en este host.

## Alternativas

- **Julia por defecto para todo lo numérico:** descartado; pierde 4× frente a polars en joins y paga 6–9 s de compilación por proceso.
- **`data.table` como motor de wrangling:** descartado; no supera a DuckDB ni a arrow en estas tareas.
- **Rcpp como primer salto de optimización:** descartado como regla general; arrow/DuckDB perezoso rinde más sin salir de R para datos tabulares.

## Decisión

1. **Mapa de lenguajes por tarea:** wrangling, joins y agregaciones → DuckDB o arrow desde R (SQL directo antes que `dbplyr` cuando el rendimiento importe), o polars/DuckDB desde Python si la etapa ya es Python; inferencia con diseño muestral, espacial y HTA → R (`survey`/`srvyr`); predicción/ML → Python; simulación, microsimulación, Monte Carlo y MCMC → Julia **multihilo** (`-t auto`) como proceso independiente (ADR 0011).
2. **Escalera de optimización con evidencia:** dplyr en memoria → arrow/DuckDB perezoso con `collect()` tardío → Rcpp encapsulado tras una función R con test de equivalencia → proceso Python o Julia. Cada salto exige `bench::mark` (≥ 3 repeticiones, mediana) más RSS pico, un test de equivalencia numérica y un ADR corto que cite las cifras; sin eso, no se cambia de peldaño.
3. **Legibilidad al optimizar:** la interfaz pública siempre es una función R documentada con roxygen2; el C++ o el script externo quedan encapsulados; un test `testthat` compara la implementación rápida con la de referencia (bit-idéntica cuando el RNG lo permite; z y χ² cuando no).
4. **Medición estándar:** `bench::mark(memory = TRUE)` para R, `tracemalloc` para Python, `@timed` para Julia, y **RSS pico del proceso** como única medida de memoria comparable entre lenguajes (`profmem` no ve las asignaciones de Arrow ni DuckDB). Cada etapa de `targets` registra `seconds`, `bytes` y `rss_peak_bytes` en el manifiesto de corrida.
5. **Imagen:** `data.table` se declara explícitamente en `env/r/packages.txt` (ya está como dependencia transitiva 1.18.4) sin ser motor por defecto; Julia permanece en la imagen por `build-arg` (ADR 0006) y se usa solo para la decisión 1; se evalúan para la Fase 3 `numpy`, `duckplyr` y `profvis` (ausentes hoy). Dentro de la imagen, Python se invoca con `uv run --no-sync`.
6. **Umbral de arranque:** una etapa en otro lenguaje solo se justifica si el ahorro medido supera su costo de arranque (Python ≈ 1,1 s, R ≈ 1,3 s, Julia ≈ 1,7 s + JIT) en la corrida completa.

## Consecuencias

- `docs/policies/performance.md` y `docs/policies/r-style.md` operan estas reglas; la Fase 3 añade un lint que exige ADR enlazado en todo PR que cambie de motor o lenguaje.
- `benchmarks/run_all.R` se conserva como benchmark de regresión y se vuelve a correr en cada cambio de imagen (comparación contra `benchmarks/results.md`).
- **Provisional:** cifras medidas en un host ruidoso y con Rcpp en un hilo (el RNG de R no es multihilo); la Ronda 1 repite el benchmark en el runner de CI y, si la diferencia Julia/Rcpp cae dentro del ruido, Julia queda restringida a MCMC.
