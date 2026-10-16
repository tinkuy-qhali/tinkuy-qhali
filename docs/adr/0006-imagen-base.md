# ADR 0006 — Imagen única del contenedor: `rocker/r-ver` + scripts oficiales, Julia opcional por build-arg

- **Estado:** aceptado (medidas de tamaño y tiempo se registran en `docs/benchmarks/baseline.md` tras el primer build)
- **Fecha:** 2026-10-16

## Contexto

La especificación (Fase 0.6) exige una sola imagen, capas cacheables, sin herramientas que no usemos, con R fijado, arrow, DuckDB, sf/terra, `targets`, `renv`, Quarto, DVC, Python con `uv`, compilador C++ y Julia vía `juliaup` con depot precompilado, más puente `JuliaCall`. Debe medirse tamaño y tiempo de build.

## Alternativas (verificado en Docker Hub el 2026-10-16)

| Base | Tamaño comprimido | Incluye | Veredicto |
|---|---|---|---|
| `rocker/r-ver:4.6.0` | 0.34 GB | R 4.6.0 compilado, Ubuntu 24.04 (noble), CRAN fijado a snapshot P3M `2026-06-23` con binarios, toolchain C/C++/Fortran, `/rocker_scripts` | **Elegida**: mínima, reproducible por fecha, binarios rápidos |
| `rocker/geospatial:4.6.0` | 1.32 GB | Lo anterior + RStudio Server, TeX Live, tidyverse completo, GDAL/GEOS/PROJ y ~60 paquetes espaciales | Descartada: RStudio y TeX no se usan; viola "sin herramientas que no usemos" |
| `rocker/verse:4.6.0` | 1.33 GB | RStudio + TeX + tidyverse, sin geoespacial | Descartada por la misma razón y además faltan GDAL/GEOS |

## Decisión

1. **Base** `rocker/r-ver:4.6.0`; librerías de sistema geoespaciales y gráficas vía `apt` (GDAL, GEOS, PROJ, udunits, cairo, harfbuzz…); Quarto 1.10.19 con el script oficial `install_quarto.sh` de rocker.
2. **Python**: `uv` 0.13.1 copiado del contenedor oficial `ghcr.io/astral-sh/uv`; Python 3.13 gestionado por `uv`; `dvc[s3]` 3.67.1 como herramienta `uv tool`; entorno del proyecto en `/opt/uv/venv` desde `env/python/pyproject.toml` + `uv.lock`.
3. **Julia**: `juliaup` con canal fijado 1.13.2 en `/opt/juliaup`; depot precompilado en `/opt/julia-depot` (capa propia, cacheable); entorno `/opt/env/julia` con DataFrames, Arrow, DuckDB, Distributions, Turing y RCall (requerido por `JuliaCall`). El depot del usuario (`/home/ubuntu/.julia`, volumen) se apila sobre el de la imagen. Controlado por `ARG WITH_JULIA` (por defecto 1): si el benchmark del ítem 22 de la Fase 1 no justifica Julia, la imagen por defecto se construye con `TQ_WITH_JULIA=0` y este ADR se supersede.
4. **R**: paquetes en `env/r/packages.txt`, instalados en la librería del sitio desde el snapshot P3M fijado; `env/r/install_packages.R` restaura `env/r/renv.lock` cuando existe y siempre emite `renv.lock.generated` para detectar deriva. No se activa `renv` por proyecto (la librería vive en la imagen; evita el bind-mount lento en Windows).
5. **Tres lockfiles** versionados: `env/r/renv.lock`, `env/python/uv.lock`, `env/julia/Manifest.toml` (+ `Project.toml`). El primer build los genera; después, cada build los restaura y CI compara.
6. **Usuario no root** `ubuntu` (uid 1000, creado explícitamente porque rocker/r-ver no trae el usuario por defecto de noble); `docker/entrypoint.sh` arranca como root solo para dar permisos a los volúmenes nombrados y baja privilegios con `setpriv`.
7. **Claude Code** instalado en la imagen con el instalador nativo, versión fijada 2.1.301; configuración y login en el volumen `claude-home` (un `claude login` la primera vez).
8. **Límites de recursos**: `.wslconfig` (24 GB, 7 CPU) derivado de `machine-profile.json` fija el techo de la VM; `start.sh`/`start.bat` leen `docker info` y escriben `.env` (`TQ_CPUS`, `TQ_MEM`) para `compose.yaml`. Nada hardcodeado; el host solo necesita Docker, Git, gh y Claude Code.
9. **Volúmenes nombrados** (fuera de NTFS): `dvc-cache` (montado en `/dvc-cache`), `targets-store`, `julia-user-depot`, `uv-cache`, `claude-home`. El código es un bind-mount porque es pequeño y va en git. **Corrección 2026-10-16:** `raw/` ya no es volumen: sus archivos `.dvc` y manifiestos deben ser visibles para git en el host; los bytes se escriben una vez y la deduplicación rápida la hace la caché DVC en el volumen. Dónde viven `standardized/`, `harmonized/` y `marts/` (I/O intensivo) se decide en la Fase 2 con el benchmark.

## Consecuencias

- Build inicial largo (precompilar Turing domina); builds posteriores reutilizan capas. Métricas en `docs/benchmarks/baseline.md`.
- Toda la sesión a partir de la Fase 0.6 ejecuta comandos de pipeline con `docker compose run --rm pipeline <cmd>`; la sesión interactiva "dentro" es `start.bat`/`start.sh`.
- Riesgo: `rocker/r-ver` fija el snapshot CRAN a 2026-06-23; paquetes publicados después no están disponibles sin cambiar `ENV CRAN` (decisión explícita, con ADR).
