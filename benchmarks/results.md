# Resultados de benchmarks (ítem 22)

Generado automáticamente por `benchmarks/run_all.R`; no editar a mano (se sobrescribe en cada corrida).

## Entorno

- date: 2026-10-16 10:25 -05
- cpu: Intel(R) Xeon(R) CPU E3-1575M v5 @ 3.00GHz
- nproc: 7
- cpu_max: 700000 100000
- mem_max_gib: 22
- loadavg_start: 0.92 0.48 0.27 1/301 48
- r: R version 4.6.0 (2026-04-24)
- python: 3.13.16 polars 2.0.0 duckdb 1.5.6 pyarrow 26.0.0
- julia: julia version 1.13.2
- loadavg al terminar: 1.96 1.13 0.56 1/302 1782
- Repeticiones por implementación: 5 + 1 de calentamiento (rep 0; en Julia incluye compilación JIT).
- Advertencia: el host Windows (WSL2 + Docker Desktop) ejecuta otros procesos durante la corrida; las diferencias < 1.5x entre implementaciones no son concluyentes. Cada implementación corre en su propio proceso.
- `mem_MB` es la medida nativa de cada herramienta y NO es comparable entre lenguajes: `bench::mark` (solo heap de R), `tracemalloc` (solo heap de Python), pool de Arrow (pyarrow), `@timed` (bytes asignados por Julia). `rss_pico_MB` (VmHWM / getrusage / Sys.maxrss) sí es comparable: pico de memoria residente de todo el proceso.

## Arranque de runtimes (proceso completo, s)

| impl | lenguaje | mediana_s | min_s | max_s | reps | warmup_s | mem_MB | rss_pico_MB | equiv_ok |
|---|---|---|---|---|---|---|---|---|---|
| py_bare | Python | 0.0757 | 0.0674 | 0.0869 | 5 | 0.0866 | NA | NA | NA |
| r_bare | R | 0.246 | 0.218 | 0.306 | 5 | 0.214 | NA | NA | NA |
| jl_bare | Julia | 0.310 | 0.242 | 0.333 | 5 | 0.306 | NA | NA | NA |
| py_polars_duckdb_pyarrow | Python | 1.09 | 0.961 | 1.52 | 5 | 1.28 | NA | NA | NA |
| r_arrow_duckdb_dplyr | R | 1.28 | 1.12 | 1.48 | 5 | 1.10 | NA | NA | NA |
| jl_dataframes_arrow_duckdb | Julia | 1.67 | 1.30 | 2.15 | 5 | 1.48 | NA | NA | NA |

## Lectura SPSS (`haven::read_sav`, RECH0 + RECH1)

| impl | lenguaje | mediana_s | min_s | max_s | reps | warmup_s | mem_MB | rss_pico_MB | equiv_ok |
|---|---|---|---|---|---|---|---|---|---|
| r_haven@x1 | R | 0.890 | 0.805 | 0.945 | 5 | 1.25 | 7.21 | 185 | NA |

## Tarea 1: join por HHID + agregación ponderada por región × área

`@x1` = 135 045 personas reales (ENDES 2024, módulo 1629); `@x25` = 3 376 125 filas (cada persona repetida 25 veces). Todas leen Parquet salvo `jl_dataframes` (Arrow IPC mapeado en memoria, porque Arrow.jl no lee Parquet).

| impl | lenguaje | mediana_s | min_s | max_s | reps | warmup_s | mem_MB | rss_pico_MB | equiv_ok |
|---|---|---|---|---|---|---|---|---|---|
| jl_dataframes@x1 | Julia | 0.0302 | 0.0201 | 0.0487 | 5 | 6.41 | 23.3 | 679 | TRUE |
| py_polars@x1 | Python | 0.0436 | 0.0373 | 0.0534 | 5 | 0.0563 | 0.0117 | 197 | TRUE |
| r_dplyr@x1 | R | 0.126 | 0.113 | 0.148 | 5 | 0.220 | 31.3 | 270 | TRUE |
| py_duckdb@x1 | Python | 0.133 | 0.129 | 0.139 | 5 | 0.134 | 0.0103 | 122 | TRUE |
| jl_duckdb@x1 | Julia | 0.134 | 0.0981 | 0.157 | 5 | 0.601 | 0.0120 | 477 | TRUE |
| r_duckdb_sql@x1 | R | 0.153 | 0.142 | 0.176 | 5 | 0.343 | 0.302 | 189 | TRUE |
| r_datatable@x1 | R | 0.161 | 0.133 | 0.338 | 5 | 0.206 | 39.2 | 278 | TRUE |
| py_polars@x25 | Python | 0.186 | 0.172 | 0.327 | 5 | 0.235 | 0.0117 | 532 | TRUE |
| r_arrow@x1 | R | 0.260 | 0.244 | 0.283 | 5 | 0.368 | 0.796 | 284 | TRUE |
| py_duckdb@x25 | Python | 0.388 | 0.367 | 0.444 | 5 | 0.401 | 0.0103 | 131 | TRUE |
| r_duckdb_dbplyr@x1 | R | 0.418 | 0.407 | 0.426 | 5 | 0.930 | 1.68 | 259 | TRUE |
| r_duckdb_sql@x25 | R | 0.428 | 0.417 | 0.482 | 5 | 0.674 | 0.302 | 199 | TRUE |
| r_arrow@x25 | R | 0.433 | 0.414 | 0.492 | 5 | 0.599 | 0.795 | 529 | TRUE |
| jl_duckdb@x25 | Julia | 0.512 | 0.491 | 0.675 | 5 | 1.01 | 0.0120 | 501 | TRUE |
| r_duckdb_dbplyr@x25 | R | 0.698 | 0.685 | 0.796 | 5 | 1.21 | 1.70 | 268 | TRUE |
| jl_dataframes@x25 | Julia | 0.789 | 0.575 | 0.878 | 5 | 9.07 | 559. | 1509 | TRUE |
| r_datatable@x25 | R | 1.05 | 0.988 | 1.28 | 5 | 1.93 | 932. | 1409 | TRUE |
| r_dplyr@x25 | R | 1.69 | 1.64 | 1.97 | 5 | 2.54 | 804. | 1350 | TRUE |

## Tarea 2: microsimulación de 1e6 individuos × 10 pasos

Expectativa analítica: E[eventos] = 2.450130; E[costo] = 3971.6414; P(al menos un evento) = 0.895369.

| impl | lenguaje | mediana_s | min_s | max_s | reps | warmup_s | mem_MB | rss_pico_MB | equiv_ok |
|---|---|---|---|---|---|---|---|---|---|
| jl_threads | Julia | 0.0599 | 0.0580 | 0.158 | 5 | 0.157 | 15.3 | 336 | TRUE |
| jl_loop | Julia | 0.213 | 0.206 | 0.218 | 5 | 0.336 | 15.3 | 321 | TRUE |
| py_pyarrow | Python | 0.279 | 0.263 | 0.367 | 5 | 0.329 | 76.3 | 189 | TRUE |
| r_rcpp | R | 0.328 | 0.280 | 0.334 | 5 | 0.299 | 30.5 | 193 | TRUE |
| r_vec | R | 0.744 | 0.702 | 0.847 | 5 | 0.988 | 690. | 242 | TRUE |
| py_duckdb | Python | 1.04 | 1.02 | 1.08 | 5 | 1.18 | 0.00287 | 171 | TRUE |

## Equivalencia

- Tarea 1: cada implementación contra `r_dplyr` del mismo tamaño; mismos grupos, `n` exacto y diferencia relativa máxima ≤ 1e-8 en suma de pesos y medias ponderadas.
- Control x25 (n ×25, medias iguales a x1): TRUE
- Tarea 2: los generadores difieren (Mersenne-Twister en R/Rcpp, `pc.random` en pyarrow, `random()` de DuckDB, Xoshiro256++ en Julia), así que la comparación es distribucional: |z| ≤ 4 contra la expectativa analítica en media de eventos, media de costo y proporción con ≥ 1 evento, y χ² de bondad de ajuste de la distribución de conteos (0–10) contra la mezcla Poisson-binomial analítica (p > 1e-4). La tolerancia relativa 1e-3 se informa, pero con N = 1e6 el error estándar relativo de la media de eventos es ≈ 7e-4, así que 1e-3 equivale a ~1.5 EE y no sirve como criterio de aceptación. `r_rcpp` consume el mismo flujo de R que `r_vec` y debe ser bit-idéntico.

- `join_agg jl_dataframes x1`: equiv vs r_dplyr: groups=49 max_rel_diff=2.14e-14 (tol 1e-08)
- `join_agg jl_duckdb x1`: equiv vs r_dplyr: groups=49 max_rel_diff=2.14e-14 (tol 1e-08)
- `join_agg py_duckdb x1`: equiv vs r_dplyr: groups=49 max_rel_diff=2.14e-14 (tol 1e-08)
- `join_agg py_polars x1`: equiv vs r_dplyr: groups=49 max_rel_diff=4.87e-15 (tol 1e-08)
- `join_agg r_arrow x1`: equiv vs r_dplyr: groups=49 max_rel_diff=1.99e-14 (tol 1e-08)
- `join_agg r_datatable x1`: equiv vs r_dplyr: groups=49 max_rel_diff=0.00e+00 (tol 1e-08)
- `join_agg r_dplyr x1`: equiv vs r_dplyr: groups=49 max_rel_diff=0.00e+00 (tol 1e-08)
- `join_agg r_duckdb_dbplyr x1`: equiv vs r_dplyr: groups=49 max_rel_diff=2.14e-14 (tol 1e-08)
- `join_agg r_duckdb_sql x1`: equiv vs r_dplyr: groups=49 max_rel_diff=2.14e-14 (tol 1e-08)
- `join_agg jl_dataframes x25`: equiv vs r_dplyr: groups=49 max_rel_diff=3.78e-13 (tol 1e-08)
- `join_agg jl_duckdb x25`: equiv vs r_dplyr: groups=49 max_rel_diff=9.86e-14 (tol 1e-08)
- `join_agg py_duckdb x25`: equiv vs r_dplyr: groups=49 max_rel_diff=9.86e-14 (tol 1e-08)
- `join_agg py_polars x25`: equiv vs r_dplyr: groups=49 max_rel_diff=4.72e-14 (tol 1e-08)
- `join_agg r_arrow x25`: equiv vs r_dplyr: groups=49 max_rel_diff=8.63e-14 (tol 1e-08)
- `join_agg r_datatable x25`: equiv vs r_dplyr: groups=49 max_rel_diff=0.00e+00 (tol 1e-08)
- `join_agg r_dplyr x25`: equiv vs r_dplyr: groups=49 max_rel_diff=0.00e+00 (tol 1e-08)
- `join_agg r_duckdb_dbplyr x25`: equiv vs r_dplyr: groups=49 max_rel_diff=9.86e-14 (tol 1e-08)
- `join_agg r_duckdb_sql x25`: equiv vs r_dplyr: groups=49 max_rel_diff=9.86e-14 (tol 1e-08)
- `microsim jl_loop n1e6`: equiv vs analytic: z(events,cost,any)=0.93,0.96,1.22; rel_diff=6.2e-04,5.0e-04,4.2e-04 (<=1e-3: TRUE); chi2 p=0.557; TV=8.1e-04; bit-identical to r_vec: FALSE
- `microsim jl_threads n1e6`: equiv vs analytic: z(events,cost,any)=0.92,0.97,1.48; rel_diff=6.2e-04,5.1e-04,5.1e-04 (<=1e-3: TRUE); chi2 p=0.177; TV=1.1e-03; bit-identical to r_vec: FALSE
- `microsim py_duckdb n1e6`: equiv vs analytic: z(events,cost,any)=0.58,0.59,1.33; rel_diff=3.9e-04,3.1e-04,4.6e-04 (<=1e-3: TRUE); chi2 p=0.896; TV=6.1e-04; bit-identical to r_vec: FALSE
- `microsim py_pyarrow n1e6`: equiv vs analytic: z(events,cost,any)=-0.88,-0.87,0.39; rel_diff=-5.9e-04,-4.6e-04,1.3e-04 (<=1e-3: TRUE); chi2 p=0.614; TV=8.7e-04; bit-identical to r_vec: FALSE
- `microsim r_rcpp n1e6`: equiv vs analytic: z(events,cost,any)=1.85,1.79,0.93; rel_diff=1.2e-03,9.4e-04,3.2e-04 (<=1e-3: FALSE); chi2 p=0.506; TV=1.2e-03; bit-identical to r_vec: TRUE
- `microsim r_vec n1e6`: equiv vs analytic: z(events,cost,any)=1.85,1.79,0.93; rel_diff=1.2e-03,9.4e-04,3.2e-04 (<=1e-3: FALSE); chi2 p=0.506; TV=1.2e-03; bit-identical to r_vec: TRUE

## Fallas

- Ninguna.

## Ausencias (no benchmarkeado por ausencia en la imagen)

- numpy (no está en `env/python/uv.lock`): la versión Python vectorizada de la microsimulación usa `pyarrow.compute`.
- Lector Parquet para Julia (Parquet2.jl): `jl_dataframes` lee Arrow IPC.
- duckplyr, collapse y profvis (R): no están instalados.
- data.table SÍ está instalado (1.18.x) como dependencia transitiva, aunque no figura en `env/r/packages.txt`; se benchmarkeó con `setDTthreads(0)`.
