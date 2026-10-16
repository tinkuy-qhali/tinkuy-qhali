# Bitácora — Fase 1 (investigación por subagentes), estado al 2026-10-16

Volcado de estado para continuidad entre sesiones (política de contexto: por fase, no por porcentaje).

## Hecho
- `docs/research/_plantilla.md`, `tools/check_research.py` (+ `tests/test_check_research.sh`, 13/13) y `tools/harvest_research.py` (cosecha informes desde `.claude/worktrees/agent-*` y poda).
- 26 informes `docs/research/NN-*.md` validados (≤ 400 palabras, URL + fecha por hallazgo, 2 fuentes nuevas) y 22 anexos `_NN-anexo-*.md` sin límite de palabras (matrices, esquemas, borradores de skill/scripts, protocolo de benchmark).
- Consolidado `docs/research/00-informe-investigacion.md`: tabla de 26 decisiones, correcciones a ADR 0001/0003/0004/manifiesto ENDES, las cinco respuestas de la Fase 1 y las decisiones que necesita el usuario.
- ADR 0008 (propuesto) supersede al 0001; parte (b) `worktree.baseRef: "head"` aplicada en `.claude/settings.json`.
- Ítem 22: `benchmarks/` con `run_all.R`, scripts R/Python/Julia, `results.parquet`, `results.csv`, `results.md` (ver sección "Benchmark" abajo).
- `tests/test_f1_acceptance.sh`: criterio de aceptación de la fase.

## Benchmark (ítem 22)
- Comando: `MSYS_NO_PATHCONV=1 docker compose run --rm -T pipeline Rscript benchmarks/run_all.R`. Última línea: `run_all OK: 186 filas en benchmarks/results.parquet; 31 implementaciones; 0 fallas; 0 no equivalentes`. 5 repeticiones + 1 calentamiento; 7 CPU / 22 GiB; host con otros procesos (diferencias < 1,5× no concluyentes).
- Join ponderado ENDES (3,4 M filas), mediana s: polars 0,19 · DuckDB Py 0,39 · DuckDB SQL R 0,43 · arrow 0,43 · Julia DuckDB 0,51 · dbplyr 0,70 · Julia DataFrames 0,79 · data.table 1,05 · dplyr 1,69. 18 variantes equivalentes (≤ 4e-13).
- Microsimulación 1e6 × 10, mediana s: Julia multihilo 0,06 · Julia bucle 0,21 · pyarrow 0,28 · Rcpp 0,33 · R vectorizado 0,74 · DuckDB 1,04. Rcpp bit-idéntico a R; todas pasan z y χ².
- Arranque con paquetes: Python 1,1 s, R 1,3 s, Julia 1,7 s (+ 6–9 s de compilación JIT de DataFrames por proceso).
- Veredicto: Julia solo para simulación/MCMC multihilo, nunca por defecto; DuckDB/arrow/polars para wrangling; `data.table` ya está en la imagen como dependencia indirecta (1.18.4): declararlo en `env/r/packages.txt` sin usarlo por defecto. Ausentes: numpy, duckplyr, profvis, lector Parquet para Julia. `uv run` requiere `--no-sync` dentro de la imagen.

## Pendiente para el usuario (decisiones)
1. ~~Aprobar el diff (a) del ADR 0008~~ — aprobado y aplicado el 2026-10-16 (respaldo `.bak-20261016-adr0008`; `curl` denegado en la prueba).
2. ~~ENDES: pedir consentimiento o quedarse en nivel 3~~ — decidido el 2026-10-16: **nivel 3 (receta + hash)**, sin pedir consentimiento por ahora; el ADR 0010 deja previsto el ascenso a nivel 2 si se solicita más adelante.
3. Autorizar la cuarentena de `duckdb-skills`, `pointblank`, `cloudflare/skills`, `docker/skills` al abrir la Fase 2.
4. Borrar el volumen huérfano `tinkuy-qhali_raw` (pendiente desde 0.6; regla `deny`).

## Siguiente
- Fase 2: arquitectura (`docs/architecture/01-ecosistema.md` con Mermaid ISO 5807 según informe 16), ADR 0009 (CDM: corrección del punto 3 del 0003), ADR 0010 (licencias de derivados), corrección del manifiesto ENDES (`terms_url` → política ANDA), `docs/style/mermaid-iso5807.md`, `docs/policies/*.md` a partir de los anexos 17, 18, 19, 20, 21.

## Decisiones tomadas en la marcha (no irreversibles)
- Ítem 22 corrió sin worktree, en el checkout principal, porque necesita Docker, volúmenes y `raw/`.
- Ítem 1 e ítem 12 no editaron configuración ni instalaron nada: solo propusieron (ADR 0008; cuarentena en Fase 2).
- Los informes se cosecharon por lotes y se commitearon por grupos; cada worktree se podó al cosechar.

## Incidentes y lecciones
- Los worktrees de subagentes partían de `origin/HEAD` (`worktree.baseRef: "fresh"` por defecto): los primeros nacieron sin la plantilla ni el validador recién commiteados. Corrección: `worktree.baseRef: "head"` en el proyecto; verificado con el siguiente worktree.
- Un heredoc largo con comillas anidadas rompió el parser de Bash y no escribió nada: para archivos largos, usar la herramienta Write y normalizar LF con Python después.
- Python en Windows escribe CRLF y la consola usa cp1252: `newline="\n"` y `sys.stdout.reconfigure(encoding="utf-8")` en toda herramienta cuyo texto lea `grep`.
- Tres subagentes (22, 24, 25) quedaron interrumpidos al pausar la sesión; 24 y 25 se reanudaron por mensaje desde su transcript sin pérdida; 22 (sin worktree, trabajo en disco incompleto) se relanzó desde cero. Docker Desktop no estaba corriendo tras la pausa: arrancarlo y esperar `docker info` antes de relanzar.
- Al cerrar un worktree cuyo agente fue reanudado hace falta `git worktree unlock` antes de `remove`.
- Varios subagentes toparon con 403/404/418 en fuentes oficiales (gob.pe, iso.org, ipums.org, dhsprogram.com, nature.com): lo marcaron **[provisional]** en vez de inventar; la Fase 2 cierra esos huecos con lectura humana o con otro cliente.
- Cuatro informes superaron las 400 palabras en el primer intento (05, 12, 13, 24) y el validador los hizo recortar: el límite funciona como criterio de salida.
