---
item: 24
titulo: Pipeline a un clic sin agente
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 24 — Pipeline a un clic sin agente

## Pregunta
Cómo ejecutar el pipeline completo de extremo a extremo con un solo comando, sin invocar a `claude`, y probarlo en máquina limpia.

## Hallazgos
- `callr_function` por defecto lanza un proceso R limpio; `NULL` corre en la sesión actual y la doc dice que no debe usarse para trabajo reproducible serio (https://docs.ropensci.org/targets/reference/tar_make.html, 2026-10-16).
- `tar_progress()` devuelve un data frame con estados `completed`, `skipped`, `errored`, entre otros (https://docs.ropensci.org/targets/reference/tar_progress.html, 2026-10-16). `tar_visnetwork()` devuelve un widget visNetwork (https://docs.ropensci.org/targets/reference/tar_visnetwork.html, 2026-10-16).
- `tar_quarto()` renderiza el informe, detecta `tar_read()`/`tar_load()` en el fuente y rastrea las salidas con `format = "file"` (https://docs.ropensci.org/tarchetypes/reference/tar_quarto.html, 2026-10-16).
- `docker compose run` sustituye el `command` del servicio, no publica puertos sin `--service-ports`, y `--rm` borra el contenedor (https://docs.docker.com/reference/cli/docker/compose/run/, 2026-10-16). Un servicio con `profiles` se ejecuta con `run` sin activar el perfil (https://docs.docker.com/compose/how-tos/profiles/, 2026-10-16).
- `up --exit-code-from` devuelve el código de salida de un servicio e implica `--abort-on-container-exit` (https://docs.docker.com/reference/cli/docker/compose/up/, 2026-10-16).
- nf-core: `nextflow run nf-core/demo -profile test,docker --outdir results` deja `results/multiqc/multiqc_report.html` (https://nf-co.re/docs/get_started/run-your-first-pipeline, 2026-10-16); `nf-core pipelines download` sirve para uso offline (https://nf-co.re/docs/usage/getting_started/offline, 2026-10-16).
- `renv::restore()` no pregunta en sesiones no interactivas (`prompt = interactive()`) (https://rstudio.github.io/renv/reference/restore.html, 2026-10-16).
- La imagen `ubuntu-24.04` de GitHub trae Docker 28.0.4 y Compose 2.38.2 (https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md, 2026-10-16).
- Binder/`repo2docker` y `make` no se verificaron; el README de `rrtools` no menciona Makefile (https://github.com/benmarwick/rrtools, 2026-10-16). **[provisional]**
- Si `Rscript -e 'targets::tar_make()'` termina con código distinto de 0 al fallar un target no está en la doc consultada. **[provisional]**

## Decisión propuesta
- Decisión: `run.sh`/`run.bat` ejecutan `docker compose run --rm -T pipeline Rscript -e 'targets::tar_make()'` y el último target es `tar_quarto()` que escribe `reports/index.html` (bind mount) | Alternativa descartada: servicio aparte con `up --exit-code-from` | Confianza: media.
- Decisión: antes de correr verifica Docker, `docker info`, `.env` (límites CPU/RAM), imagen (`build` o `pull`) y datos (`dvc pull` salvo `TQ_SYNTHETIC=1`); salidas 10–13 prerrequisito, 20 pipeline, 21 informe ausente | Alternativa descartada: `callr_function = NULL` | Confianza: media.
- Decisión: prueba local en `.tq-tmp/` y CI con datos sintéticos; "sin agente" se mide con `claude` ausente del PATH | Alternativa descartada: Binder | Confianza: media.

## Riesgos y provisional
- Código de salida de `tar_make()` y `crew` bajo `mem_limit` se prueban en la Fase 2; aún no hay `_targets.R`.
- Disco y tiempo de `ubuntu-latest` frente a la imagen: sin medir.

## Fuentes nuevas
- https://rstudio.github.io/renv/articles/ci.html — caché de renv en GitHub Actions para acortar el CI.
- https://docs.ropensci.org/targets/reference/tar_mermaid.html — grafo del pipeline en Mermaid, alineado con el ítem 16.
