# Benchmark de la imagen — línea base (Fase 0.6)

Máquina: perfil en ADR 0000 (Xeon E3-1575M v5, 4 físicos / 8 lógicos; VM WSL2 limitada a 7 CPU / 24 GB). Docker 29.5.3, BuildKit. Red doméstica sin proxy. Fecha: 2026-10-16.

## Intentos de construcción (logs en `docs/benchmarks/build-log-20261016-*.txt`)

| Intento | Resultado | Tiempo (s) | Hasta dónde llegó | Causa del fallo | Corrección |
|---|---|---|---|---|---|
| 1 | cancelado | ~348 (etapas terminadas) | Julia instalada (juliaup) | Parche del Dockerfile no aplicado (`str.replace` silencioso): la etapa Julia ejecutaba `Pkg.instantiate()` sin proyecto | Verificar parches con `grep`; `setup.jl` |
| 2 | fallo | 551 | Julia precompilada, R instalado ("R stack ok") | `chown ubuntu:ubuntu`: `rocker/r-ver` no trae el usuario `ubuntu` | `groupadd`/`useradd` explícitos |
| 3 | OK (imagen incompleta) | 177 | Imagen completa | — (pero `JuliaCall::julia_setup()` falla: falta `Suppressor`) | Añadir `Suppressor` al entorno Julia |
| 4 | fallo | 610 | Julia re-precompilada (Manifest fijado); restore de R | `fs` binario de P3M requiere `libuv.so.1` | `libuv1` |
| 5 | fallo | 85 | restore de R | `V8` (vía `pointblank`) requiere `libnode.so.109` | Consultar sysreqs de P3M para toda la lista; instalar la unión |
| 6 | **OK** | 317 | Imagen completa; `tests/test_bootstrap.sh` 18/20 (faltan DVC y Zenodo, que dependen de credenciales del usuario) | — | — |

Lecciones: (1) un build "en verde" no prueba nada hasta que `tests/test_bootstrap.sh` corre dentro del contenedor; (2) los binarios de P3M exigen las librerías de sistema de `SystemRequirements` aunque no se compile nada: la fuente de verdad es la API `sysreqs` de P3M, no la intuición (`env/r/sysreqs-ubuntu-24.04.txt`).

## Métricas de la imagen (se completan con el intento exitoso)

| Métrica | Valor | Cómo se midió |
|---|---|---|
| Tamaño de imagen (sin comprimir) | **2.39 GB** (2 393 046 039 bytes), intento 6; 1.96 GB en el intento 3 antes de libnode-dev y sysreqs | `docker image inspect tinkuy-qhali:local --format '{{.Size}}'` |
| Build en frío (sin caché) | _no medido aún_: todos los intentos reutilizaron capas; estimación por suma de etapas ≈ 12–15 min | suma de `#N DONE` en los logs |
| Build con caché, cambio solo en `env/r/` | 317 s (sysreqs apt + 154 paquetes R binarios + usuario + Claude Code) | intento 6 |
| Precompilación Julia (DataFrames, Arrow, DuckDB, Distributions, Turing, RCall, Suppressor) | ≈ 7 min | etapa `#19` del intento 4 |

## Capas y qué invalida cada una

| Capa | Invalidada por |
|---|---|
| apt base + Quarto | cambios en la lista `apt` o `QUARTO_VERSION` |
| uv + Python + DVC + venv | `env/python/*` |
| juliaup + depot | `env/julia/*` (precompilar Turing es el costo dominante) |
| sysreqs R + librería R | `env/r/*` |
| usuario + Claude Code + entrypoint | `CLAUDE_CODE_VERSION`, `docker/entrypoint.sh` |

Estas medidas alimentan el protocolo de benchmark de la Fase 1 (ítem 14) y la Fase 3; aquí son línea base, no comparación.
