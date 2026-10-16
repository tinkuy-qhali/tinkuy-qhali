---
item: 12
titulo: Skills, plugins, MCP y conectores por herramienta
modelo: haiku
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 12 — Skills, plugins, MCP y conectores por herramienta

## Pregunta
¿Qué skill o plugin existe por herramienta del stack (oficial o comunitario activo) y qué hay que crear? Matriz en el anexo.

## Hallazgos
- `duckdb/duckdb-skills`: oficial, MIT, push 2026-04-23; trae query y s3-explore (https://github.com/duckdb/duckdb-skills, 2026-10-16).
- `posit-dev/pointblank`: skill oficial para el paquete Python, MIT, archivo 2026-10-09; el paquete R no tiene skill (https://github.com/posit-dev/pointblank, 2026-10-16).
- `cloudflare/skills`: oficial, Apache-2.0, push 2026-10-15; cubre R2 sin skill propia (https://github.com/cloudflare/skills, 2026-10-16).
- `docker/skills`: oficial, Apache-2.0, 11 skills de Docker, ninguna de devcontainer (https://github.com/docker/skills, 2026-10-16).
- `uv` (astral): oficial, pero último commit 2026-02-27, fuera de 6 meses (https://github.com/astral-sh/claude-code-plugins, 2026-10-16).
- Comunitario activo: `github-actions-hardening`, MIT, archivo 2026-06-16 (https://github.com/github/awesome-copilot, 2026-10-16).
- Excluidos por antigüedad: Zenodo, Mermaid, DVC, DuckDB y Arrow de `TerminalSkills` (https://github.com/TerminalSkills/skills, 2026-10-16).
- Sin skill oficial: renv, haven, srvyr, targets, DVC, pre-commit, styler y devcontainers/cli (https://github.com/r-lib/lintr, 2026-10-16; lintr sólo trae skills para desarrollar linters).
- Julia: `JuliaLang/julia` sólo trae skills de desarrollo del lenguaje (https://github.com/JuliaLang/julia, 2026-10-16). **[provisional]** La búsqueda por código exige autenticación.

## Decisión propuesta
- Usar existente, tras cuarentena del ítem 18: duckdb-skills, pointblank, cloudflare, docker/skills, uv y github-actions-hardening. Decisión: instalar tras revisar cada SKILL.md en un commit fijo | Alternativa descartada: agregadores como TerminalSkills (sin cuarentena previa) | Confianza: alta para duckdb, pointblank, cloudflare y docker; media para uv y github-actions-hardening.
- Crear y testear: renv, arrow, haven, srvyr, targets, Julia, DVC, pre-commit, lintr, styler, Zenodo (sobre el Sandbox de la Fase 0.6), Mermaid y GitHub Pages. Decisión: skills propias pequeñas con prueba mínima | Alternativa descartada: adoptar comunitarias fuera de 6 meses | Confianza: media.

## Riesgos y provisional
- Más valiosos para la cuarentena: duckdb-skills, pointblank y cloudflare (cierre en el ítem 18).
- La API no detecta licencia en lintr, styler, haven, targets y srvyr: verificar DESCRIPTION.
- **[provisional]** Fechas de mermaid-diagram-guide y pubmed-api (wentorai) no verificadas por límite de la API de GitHub.
- **[provisional]** Julia y devcontainer: búsqueda limitada a repositorios revisados.

## Fuentes nuevas
- https://github.com/ropensci — revisar si rOpenSci publica una skill para targets antes de crear la nuestra.
- https://github.com/treeverse — revisar si el proyecto DVC publica una skill en otro repositorio, ya que treeverse/dvc no la trae.
