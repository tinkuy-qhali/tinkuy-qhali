---
item: 23
titulo: Skill r-package-scout para paquetes de R poco conocidos
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 23 — Skill r-package-scout

## Pregunta
Qué fuentes de documentación de R se pueden consultar por API o MCP, y cómo diseñar una skill que aprenda un paquete desconocido y deje `docs/packages/<pkg>.md`.

## Hallazgos
- CRAN `DESCRIPTION` de `srvyr` responde en texto plano con versión 1.3.1, licencia GPL-2 | GPL-3 y fecha de publicación (https://cran.r-project.org/web/packages/srvyr/DESCRIPTION, 2026-10-16).
- crandb devuelve JSON con `Version`, `License`, `Imports` y el historial `releases` (https://crandb.r-pkg.org/srvyr, 2026-10-16).
- Los CRAN checks de `srvyr` se leen en HTML: 11 flavors OK y 2 NOTE (https://cran.r-project.org/web/checks/check_results_srvyr.html, 2026-10-16).
- r-universe: la búsqueda global devuelve JSON con mantenedor, `_usedby` y estrellas (https://r-universe.dev/api/search?q=srvyr, 2026-10-16). El detalle por paquete exige el universo del dueño y trae estado de build y vignettes (https://gergness.r-universe.dev/api/packages/srvyr, 2026-10-16). Con `ropensci` dio 404 y `cran.r-universe.dev` dio 521 transitorio.
- La API de GitHub entrega `pushed_at`, archivado e issues abiertos; para `srvyr` la licencia sale `null` aunque CRAN diga GPL (https://api.github.com/repos/gergness/srvyr, 2026-10-16). La licencia manda desde `DESCRIPTION`.
- cranlogs da descargas en JSON (https://cranlogs.r-pkg.org/downloads/total/last-month/srvyr, 2026-10-16); `pkgsearch` 3.1.5 consulta el servidor de r-hub, no es oficial de CRAN (https://cran.r-project.org/web/packages/pkgsearch/index.html, 2026-10-16).
- Sí hay MCP de R: `mcptools` 1.0.3, MIT + LICENSE, expone ayuda de paquetes y código R (https://cran.r-project.org/web/packages/mcptools/DESCRIPTION, 2026-10-16); repo activo, último push 2026-09-28 (https://api.github.com/repos/posit-dev/mcptools, 2026-10-16). `btw` agrega documentación de paquetes instalados (https://api.github.com/repos/posit-dev/btw, 2026-10-16).
- `cran_mcp` (MEO265) ofrece búsqueda y temas de ayuda por HTTP **[no oficial]**; su licencia no figura (https://glama.ai/mcp/servers/iwmxx3xhfb, 2026-10-16).
- Formato de skill: `description` con `when_to_use` truncado a 1.536 caracteres, `SKILL.md` bajo 500 líneas y `allowed-tools` con patrones `Bash(cmd *)` (https://code.claude.com/docs/en/skills, 2026-10-16).
- Ayuda offline (`Rd2txt`, `vignette()`, `citation()`) y `pak::pkg_deps()` **[provisional]**: no se ejecutaron por la regla de no usar docker.

## Decisión propuesta
- Decisión: skill `r-package-scout` con flujo de 5 pasos, API de CRAN/crandb/r-universe/GitHub y ayuda offline en el contenedor; borrador en el anexo | Alternativa descartada: depender de un MCP externo | Confianza: media.
- Decisión: no instalar `cran_mcp`; evaluar `mcptools`/`btw` solo tras cuarentena y como opción, no como requisito | Alternativa descartada: instalar ambos ya | Confianza: media.

## Riesgos y provisional
- Falta ejecutar el flujo y la eval en el contenedor (Fase 2); la licencia de `mcptools` figura como NOASSERTION en GitHub.
- r-universe exige conocer el universo; hay que probar con paquete archivado y solo-GitHub.

## Fuentes nuevas
- https://r-universe.dev/docs/api — especificación completa de la API de r-universe, para el paso 2.
- https://github.com/r-hub/crandb — documenta la API de crandb (versiones, reverse deps), para automatizar el paso 1.
