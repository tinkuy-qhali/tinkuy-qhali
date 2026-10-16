# Benchmarks del ítem 22: R rápido y legible, pipelines híbridos R/Python/Julia

Mide, dentro del contenedor `tinkuy-qhali:local` y sin instalar nada, dos cargas típicas del proyecto:

1. **`join_agg`**: ENDES 2024, módulo 1629. Personas (RECH1) se unen con hogares (RECH0) por `HHID` y se agregan con pesos por región × área: `n`, suma de pesos y medias ponderadas de edad, años de estudio y tamaño del hogar, con los NA excluidos del numerador y del denominador. Hay dos tamaños: `x1` (135 045 filas reales) y `x25` (3,4 M filas, cada persona repetida 25 veces).
2. **`microsim`**: 1e6 individuos y 10 pasos anuales con un modelo fijo (logit de edad y sexo, eventos y costos descontados) y semilla fija.

Además se miden el arranque de cada runtime (R, Python y Julia, con y sin sus paquetes de datos) y la lectura SPSS con `haven::read_sav`.

## Cómo correr

Desde la raíz del repo, en Git Bash:

```bash
MSYS_NO_PATHCONV=1 docker compose run --rm -T pipeline Rscript benchmarks/run_all.R
```

Tarda unos 4 minutos con 7 CPU. Escribe `benchmarks/results.parquet`, `benchmarks/results.csv` y `benchmarks/results.md`. Si una implementación falla, queda registrada con `equiv_ok = NA` y el error en `note`, y la corrida sigue. Variables útiles:

- `TQ_BENCH_REPS`: repeticiones por implementación (5 por defecto, más 1 de calentamiento).
- `TQ_MICROSIM_N`: tamaño de la microsimulación.

Ejemplo: `docker compose run --rm -T -e TQ_BENCH_REPS=1 pipeline Rscript benchmarks/run_all.R`.

## Estructura

| Ruta | Qué hace |
|---|---|
| `run_all.R` | Orquestador. Mide el arranque, corre `R/prepare.R` y lanza cada implementación en su propio proceso (`system2`). Luego verifica la equivalencia y escribe los resultados. |
| `R/common.R` | Medición con `bench::mark(memory = TRUE)` y RSS pico (`/proc/self/status`). Contrato de archivos en `.cache/res` y `.cache/out`. |
| `R/prepare.R` | Descomprime el zip de `raw/` (solo lectura) en `.cache/` y lee los `.sav`. Decide el manejo de NA una sola vez. Escribe Parquet y, para Julia, Arrow IPC. |
| `R/task1_join.R` | `dplyr` en memoria, `arrow` perezoso, DuckDB por SQL, DuckDB por `dbplyr` y `data.table`. |
| `R/task2_microsim.R`, `R/microsim.cpp` | R vectorizado y Rcpp. Ambos consumen el mismo flujo RNG de R y dan resultados bit-idénticos. |
| `python/` | `polars` (perezoso) y DuckDB para la tarea 1; `pyarrow.compute` y DuckDB SQL para la tarea 2. numpy no está en la imagen. Se ejecutan con `uv run --no-sync --project env/python`. |
| `julia/` | `DataFrames` (sobre Arrow IPC) y DuckDB para la tarea 1; bucle nativo y bucle multihilo para la tarea 2. Se ejecutan con `julia --threads=auto`. |
| `.cache/` | Datos intermedios y salidas por implementación. Está en `.gitignore` y se regenera. |

## Columnas de `results.parquet`

`task`, `impl` (`<lang>_<impl>[@tamaño]`), `language`, `rep` (0 = calentamiento), `seconds`, `mem_bytes`, `n_rows`, `equiv_ok`, `note` y `versions`.

`mem_bytes` es la medida nativa de cada herramienta, así que no sirve para comparar entre lenguajes:

- `bench::mark` y `@timed` cuentan solo el heap de R o de Julia.
- `tracemalloc` cuenta solo el heap de Python.
- En pyarrow se usa el pico del pool de Arrow.

Para comparar entre lenguajes, usa `rss_peak_mb` dentro de `note`.

## Notas de reproducibilidad

- `uv run` sin `--no-sync` falla dentro del contenedor: intenta instalar el grupo `dev` (pytest) en `/opt/uv/venv`, que pertenece a root. `--frozen` y `--offline` no lo evitan.
- DuckDB `random()` con varios hilos no es reproducible bit a bit. La comparación de la microsimulación entre lenguajes es distribucional (z contra la expectativa analítica y χ² de la distribución de conteos). El detalle está en `results.md`.
- El host Windows ejecuta otros procesos durante la corrida. Las diferencias menores de 1,5x no son concluyentes.
