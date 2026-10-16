---
titulo: Rendimiento y pipelines híbridos
estado: borrador
fecha: 2026-10-16
fase_aplicacion: F3
fuentes: [docs/research/22-codigo-r-y-pipelines-hibridos.md, benchmarks/results.md, benchmarks/README.md, docs/research/10-contrato-manifiesto-pipelines.md, docs/research/_10-anexo-manifiesto.md, docs/research/24-pipeline-a-un-clic.md, tools/profile_machine.py]
---
# Política: Rendimiento y pipelines híbridos

## Propósito
Define cuándo y cómo optimizar el código, cómo orquestar etapas en R, Python y Julia, y cómo medir tiempo y memoria sin cargar en RAM más de lo que cabe. Toda optimización se justifica con un benchmark ejecutado y, si cambia la arquitectura, con un ADR. El criterio es la evidencia de `benchmarks/results.md`, no la intuición.

## Reglas
R1. Se sube la escalera de optimización de un peldaño a la vez: (1) dplyr; (2) arrow/DuckDB perezoso con `collect()` lo más tarde posible; (3) Rcpp encapsulado tras una función R con test de equivalencia; (4) proceso Python o Julia. — **Por qué:** cada salto agrega complejidad, y en el join de 3,4 M filas el peldaño 2 ya da ~4x sobre dplyr (`benchmarks/results.md`). — **Se verifica con:** revisión de PR; ADR enlazado en el PR.
R2. Cada salto de peldaño exige un benchmark reproducible (`bench::mark`, 5 repeticiones más 1 de calentamiento, resultados iguales verificados) y un ADR con la cifra; diferencias < 1,5x se tratan como no concluyentes. — **Por qué:** el host ejecuta otros procesos y esas diferencias están dentro del ruido (`benchmarks/results.md`). — **Se verifica con:** `Rscript benchmarks/run_all.R` en el contenedor; carpeta `docs/adr/`.
R3. Joins y agregaciones sobre tablas grandes se hacen en DuckDB (SQL directo o `tbl()` sobre Parquet), no con `merge()` en memoria. dbplyr es aceptable por legibilidad, con el costo medido de +63 % frente al SQL directo. — **Por qué:** x25: DuckDB SQL 0,43 s frente a dplyr 1,69 s; dbplyr 0,70 s (`benchmarks/results.md`). — **Se verifica con:** benchmark de la etapa; revisión de PR.
R4. Nunca se carga un módulo completo en memoria si no cabe en el perfil de la máquina: se lee en bloques de `derived.read_chunk_rows` filas o perezosamente con arrow/DuckDB, y DuckDB corre con `memory_limit = derived.duckdb_memory_limit_gb` GB. — **Por qué:** `tools/profile_machine.py` deriva esos valores de la RAM real (250 000 filas si hay ≥ 16 GB, si no 100 000; 40 % de la RAM para DuckDB). — **Se verifica con:** test que lee `machine-profile.json` y falla si una etapa fija un límite a mano [propuesta].
R5. `targets` orquesta todo. Las etapas en Python o Julia son targets con `format = "file"` que lanzan un proceso y entregan Parquet; `JuliaCall` y `reticulate` se usan solo de forma interactiva y para llamadas pequeñas. Los workers de `crew` son `derived.targets_workers` (núcleos físicos - 1). — **Por qué:** los procesos aislados son reproducibles y no comparten estado ni memoria con R (informes 10 y 22). — **Se verifica con:** revisión de `tar_manifest()` por test [propuesta]; `grep` de `JuliaCall::`/`reticulate::` en `_targets.R` y `R/`.
R6. Julia se usa solo para simulación o MCMC multihilo, lanzada con `julia --threads=auto`; no para joins ni lectura de tablas. Lee Parquet vía DuckDB.jl, porque Arrow.jl no lee Parquet. — **Por qué:** en microsimulación 1e6 x 10, Julia con hilos tarda 0,060 s frente a 0,328 s de Rcpp, pero en join pierde ~4x frente a polars y compila 6–9 s por proceso (`benchmarks/results.md`). — **Se verifica con:** ADR por etapa Julia; revisión de PR.
R7. `data.table` está disponible pero no es el motor por defecto: se declara en `env/r/packages.txt` y solo se usa con justificación medida. — **Por qué:** 1,05 s en x25 frente a 0,43 s de arrow y de DuckDB; se descartó como motor por defecto (informe 22). — **Se verifica con:** `tools/check_renv_drift.py`; revisión de PR.
R8. Cada etapa mide tiempo con `bench::mark(memory = TRUE)` y memoria con el RSS pico del proceso (`VmHWM` / `getrusage` / `Sys.maxrss`), nunca solo con `profmem`. — **Por qué:** `profmem` no ve las asignaciones de Arrow ni de DuckDB, y `mem_MB` nativo no es comparable entre lenguajes (`benchmarks/README.md`). — **Se verifica con:** helper de medición [propuesta] basado en `benchmarks/R/common.R`.
R9. Para localizar cuellos de botella de tiempo se usa `profvis` antes de reescribir; no se optimiza código que no se perfiló. — **Por qué:** evita Rcpp o procesos externos donde el problema es un bucle R evitable (informe 22). — **Se verifica con:** manual (el PR cita el perfil); `profvis` no está instalado aún.
R10. Cada etapa tiene un presupuesto de tiempo y de RSS pico registrado en el manifiesto de corrida; superarlo en más de 2x [propuesta] marca la corrida como advertencia y exige revisión. — **Por qué:** el manifiesto guarda `duration_s` y `targets[]` con `seconds`, pero no memoria (informe 10 y su anexo). — **Se verifica con:** validador del manifiesto [propuesta] en CI.
R11. Las etapas Python se ejecutan con `uv run --no-sync --project env/python` dentro de la imagen; sin `--no-sync` falla al intentar instalar el grupo `dev` en `/opt/uv/venv`. — **Por qué:** el venv pertenece a root y `--frozen`/`--offline` no lo evitan (`benchmarks/README.md`). — **Se verifica con:** test de humo de la etapa Python en CI [propuesta].
R12. Un reemplazo por otro motor o lenguaje solo se acepta si pasa equivalencia contra la referencia R: tolerancia relativa ≤ 1e-8 en determinista; z y χ² en estocástico. — **Por qué:** las 18 variantes del join coinciden (≤ 4e-13) y los generadores aleatorios difieren entre lenguajes. — **Se verifica con:** test de equivalencia por etapa [propuesta]; ver `docs/policies/r-style.md` (R11 y R12).

## Qué hace el agente y qué no
- Hace: mide antes de optimizar; empieza por dplyr y sube de peldaño solo con cifras; lee `machine-profile.json` (`derived`) para chunking y límites; registra tiempo y RSS en el manifiesto; propone el ADR con el benchmark.
- No hace: reescribir en Rcpp, Python o Julia sin benchmark y ADR; cargar un módulo entero sin comprobar que cabe; fijar workers o memoria a mano; usar `JuliaCall`/`reticulate` en el pipeline; instalar `duckplyr`, `profvis` ni `numpy` por su cuenta.

## Mecanismos que la hacen cumplir (Fase 3)
| Mecanismo | Tipo (hook/test/CI/skill/lintr) | Evento o disparador | Estado |
|---|---|---|---|
| `benchmarks/run_all.R` repetido en la imagen final | test | manual al cerrar Fase 3 y ante cada salto de peldaño | por implementar |
| Test de equivalencia por etapa (`expect_equivalente()`) | test | CI y `tar_make()` | por implementar |
| Validador del manifiesto con presupuesto y RSS por etapa | CI | fin de `tar_make()` y PR | por implementar |
| Test que lee `machine-profile.json` y rechaza límites fijos | test | CI | por implementar |
| Revisión de `tar_manifest()` (formatos `parquet`/`file`, sin `JuliaCall`) | test | CI | por implementar |
| `undesirable_function_linter` para `JuliaCall`/`reticulate` en `R/` | lintr | pre-commit | por implementar |
| Exigir ADR enlazado en PR que cambie motor o lenguaje | CI | PR | por implementar |

## Cifras de referencia
Fuente: `benchmarks/results.md` (2026-10-16; Xeon E3-1575M v5, 7 CPU, 22 GiB; R 4.6.0, Python 3.13, Julia 1.13.2; mediana de 5 repeticiones; host con ruido).
| Prueba | Implementación | Mediana (s) | RSS pico (MB) |
|---|---|---|---|
| Join + agregación ponderada x25 (3,4 M filas) | polars | 0,186 | 532 |
| Ídem | DuckDB SQL (R) | 0,428 | 199 |
| Ídem | arrow perezoso (R) | 0,433 | 529 |
| Ídem | dbplyr sobre DuckDB | 0,698 | 268 |
| Ídem | data.table | 1,05 | 1409 |
| Ídem | dplyr | 1,69 | 1350 |
| Microsimulación 1e6 x 10 | Julia multihilo | 0,060 | 336 |
| Ídem | Julia bucle | 0,213 | 321 |
| Ídem | Rcpp | 0,328 | 193 |
| Ídem | R vectorizado | 0,744 | 242 |
| Arranque sin paquetes | Python / R / Julia | 0,076 / 0,246 / 0,310 | NA |
| Arranque con paquetes de datos | Python / R / Julia | 1,09 / 1,28 / 1,67 | NA |
| Lectura SPSS RECH0 + RECH1 | `haven::read_sav` | 0,890 | 185 |

Rcpp es bit-idéntico al R vectorizado; Julia compila 6–9 s en el primer uso de cada proceso. En etapas cortas el arranque domina: no se lanza un proceso por llamada pequeña.

## Provisional
- Máquina ruidosa, Rcpp con un solo hilo y Julia leyendo Arrow IPC (Arrow.jl no lee Parquet); la Fase 3 repite los benchmarks (informe 22).
- Faltan `numpy`, `duckplyr`, `collapse` y `profvis` en la imagen; los hooks no se probaron (informe 22).
- El presupuesto 2x, los campos de RSS y `stages[]` en el manifiesto son [propuesta]; el esquema del manifiesto es [provisional] (anexo 10).
- Código de salida de `tar_make()` y `crew` bajo `mem_limit`: se prueban en Fase 2; aún no hay `_targets.R` (informe 24).
- `machine-profile.json` está en `.gitignore` y se regenera en cada arranque; cómo llega al contenedor queda por confirmar en Fase 3.

## Fuentes
- docs/research/22-codigo-r-y-pipelines-hibridos.md; docs/research/10-contrato-manifiesto-pipelines.md y _10-anexo-manifiesto.md; docs/research/24-pipeline-a-un-clic.md; benchmarks/results.md y benchmarks/README.md; tools/profile_machine.py (campos `derived`).
- https://arrow.apache.org/docs/r/articles/data_wrangling.html (2026-10-16)
- https://duckdb.org/docs/current/clients/r.html (2026-10-16)
- https://bench.r-lib.org/ (2026-10-16)
- https://cran.r-project.org/web/packages/profmem/vignettes/profmem.html (2026-10-16)
- https://profvis.r-lib.org/ (2026-10-16)
- https://docs.julialang.org/en/v1/manual/multi-threading/ (2026-10-16)
- https://docs.ropensci.org/targets/reference/tar_target.html (2026-10-16)
- https://docs.ropensci.org/targets/reference/tar_meta.html (2026-10-16)
