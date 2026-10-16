# ADR 0011 — Pipeline determinista: `targets` orquesta, Parquet como contrato, DVC solo para `raw/`

- **Estado:** aceptado
- **Fecha:** 2026-10-16
- **Fuente:** Fase 1, informes 10 (+ anexo manifiesto), 22 (+ `benchmarks/results.md`), 24 (+ anexo `run`), 11, 26; ADR 0006 (imagen), ADR 0007 (DVC en R2)

## Contexto

La especificación pedía elegir entre `targets` + `renv`, DVC pipelines, Snakemake y Kedro, justificando por Windows, caché, Parquet/DuckDB y legibilidad para agentes. La Fase 0.6 ya mostró que DVC necesita `--no-scm` en bind mounts de Windows (la libgit2 embebida no renombra objetos) y que `dvc exp` exige Git (informe 10), lo que descarta DVC como orquestador. `targets` registra hash de datos, comando y dependencias, semilla y tiempo por target en `tar_meta()`, admite `format = "parquet"` y `format = "file"`, y `tar_resources_aws()` acepta `endpoint` S3-compatible (https://docs.ropensci.org/targets/reference/tar_target.html, 2026-10-16). El benchmark del ítem 22 midió el costo de arranque de cada runtime (Python 1,1 s, R 1,3 s, Julia 1,7 s más 6–9 s de compilación JIT por proceso) y confirmó que el intercambio por Parquet es viable entre los tres lenguajes.

## Alternativas

- **DVC pipelines (`dvc.yaml`/`dvc repro`):** descartado como orquestador por la dependencia de Git en bind mounts de Windows y por `dvc exp`; se conserva para versionar `raw/`.
- **Kedro / nf-core / Snakemake:** descartados como motor (otra pila, sin ventaja para un equipo R); se toman ideas: `versioned` y `validator` de Kedro, esquema JSON de parámetros y módulos que reportan versiones de nf-core.
- **Puentes en proceso (`reticulate`, `JuliaCall`) para trabajo pesado:** descartados: acoplan entornos y memoria, y ocultan el contrato de datos.

## Decisión

1. **`targets` (R) orquesta todo el pipeline** desde `_targets.R`, con `crew` para paralelismo limitado por `machine-profile.json` (`targets_workers`). Caché en el volumen `targets-store` (ya montado en `compose.yaml`).
2. **Parquet es el único contrato de intercambio** entre etapas y entre lenguajes; cada Parquet lleva en `custom_metadata` la versión del Table Schema que cumple (ADR 0009). Prohibido intercambiar objetos serializados (`.rds`, `.pkl`, `.jld2`) entre etapas.
3. **Etapas en Python o Julia** se declaran como targets `format = "file"` que lanzan un proceso (`uv run --no-sync python ...`, `julia --project=... -t auto ...`) y devuelven la ruta del Parquet producido; `reticulate` y `JuliaCall` quedan para llamadas pequeñas e interactivas. Julia lee Parquet vía DuckDB.jl (Arrow.jl no lee Parquet; benchmark 22).
4. **DVC versiona solo `raw/`** (`dvc init --no-scm`, caché en `/dvc-cache`, remote `r2`); los punteros `.dvc` y manifiestos viven en git dentro de `raw/` (ADR 0006 corrección). Las capas `standardized/`, `harmonized/` y `marts/` son regenerables por `targets` y no entran en git ni en DVC; se publican como artefactos de release según su nivel (ADR 0010).
5. **Manifiesto por corrida** (esquema en ADR 0009, decisión 9) escrito por el último target a `reports/manifest-<run_id>.json`, construido desde `tar_meta()` más el perfil de máquina, el digest de la imagen y los campos de agente (`model`, `claude_code_version`, `skills_hash`, `cost_usd`).
6. **Validación declarativa por capa:** `pointblank` en R y `pandera` en Python contra los Table Schema del `cdm`; un target de validación por capa falla el pipeline con mensaje accionable.
7. **Un clic sin agente** (informe 24): `run.sh`/`run.bat` verifican Docker, `.env`, imagen y datos (`dvc pull` salvo `TQ_SYNTHETIC=1`) y ejecutan `docker compose run --rm -T pipeline Rscript -e 'targets::tar_make()'`; el último target es `tarchetypes::tar_quarto()` que escribe `reports/index.html`. Códigos de salida: 10–13 prerrequisitos, 20 pipeline, 21 informe ausente.
8. **Prueba en máquina limpia:** local en `.tq-tmp/` con proyecto de compose distinto y datos sintéticos; en CI, job `e2e` del workflow `image` con `claude` ausente del PATH.

## Consecuencias

- Fase 3 crea `_targets.R`, `R/` con funciones por etapa, `python/` y `julia/` con scripts de proceso, `run.sh`/`run.bat` y el job `e2e`.
- El informe de arranque (benchmark 22) fija la regla: una etapa en otro lenguaje solo se justifica si ahorra más que su arranque (≈ 1–2 s, o ≈ 10 s en Julia) y lo demuestra con `bench::mark`.
- **Provisional (cierra Fase 3):** `tar_resources_aws(endpoint = ...)` contra R2 sin probar; código de salida de `tar_make()` ante target fallido (el script revisa `tar_progress()`); comportamiento de `crew` bajo `mem_limit`.
