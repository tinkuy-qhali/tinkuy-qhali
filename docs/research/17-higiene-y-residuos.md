---
item: 17
titulo: Higiene y residuos
modelo: haiku
esfuerzo: low
fecha: 2026-10-16
estado: borrador
---
# 17 — Higiene y residuos

## Pregunta
Qué deja Claude Code en disco y en git, qué limpia solo, y qué política de residuos y tamaños fijar para tinkuy-qhali. Detalle en `docs/research/_17-anexo-politica.md`.

## Hallazgos
- Worktrees de sesión: `.claude/worktrees/<nombre>/`, rama `worktree-<nombre>`. Al salir, si están limpios se borran con su rama (sesión sin nombre); si tienen cambios, Claude pregunta (https://code.claude.com/docs/en/worktrees, 2026-10-16).
- El barrido periódico borra worktrees de subagentes y sesiones en segundo plano más antiguos que `cleanupPeriodDays` (30 por defecto), salvo los que tienen cambios o commits sin subir (https://code.claude.com/docs/en/worktrees, 2026-10-16).
- `worktree.baseRef` acepta solo `"fresh"` (por defecto) o `"head"` (https://code.claude.com/docs/en/worktrees, 2026-10-16).
- Transcripts, `history.jsonl` y scratchpad se borran tras `cleanupPeriodDays`; la memoria automática se conserva mientras tenga contenido (https://code.claude.com/docs/en/claude-directory, 2026-10-16).
- Claude añade `settings.local.json` a los excludes globales de git; la doc recomienda `.claude/worktrees/` en `.gitignore`, ya presente aquí (https://code.claude.com/docs/en/claude-directory, 2026-10-16). `tmpclaude-*` en el repo: **[provisional]**, sin fuente.
- `git worktree remove` rechaza worktrees sucios sin `--force`; `prune` quita metadatos de worktrees sin directorio (https://git-scm.com/docs/git-worktree, 2026-10-16). Que el borrado conserve la rama: **[provisional]**.
- `gc.auto` = 6700 objetos sueltos; `gc.pruneExpire` = 2 semanas; `gc` poda worktrees con `gc.worktreePruneExpire` = 3 meses (https://git-scm.com/docs/git-gc, 2026-10-16).
- `renv::clean()` quita bloqueos, temporales y paquetes no usados (interactivo); la caché global **[provisional]** (https://rstudio.github.io/renv/reference/clean.html, 2026-10-16).
- `tar_prune()` borra objetos y metadatos de targets fuera del pipeline; `tar_destroy()` **[provisional]** (https://docs.ropensci.org/targets/reference/tar_prune.html, 2026-10-16).
- `docker builder prune` borra solo caché huérfana salvo `-a` (https://docs.docker.com/reference/cli/docker/builder/prune/, 2026-10-16).
- `git filter-repo` reescribe historia y exige clon fresco salvo `--force` (https://github.com/newren/git-filter-repo, 2026-10-16).
- `dvc gc` y `uv cache prune`: sin lectura completa; **[provisional]**.

## Decisión propuesta
- Decisión: borrar al cierre los worktrees limpios; los sucios pasan a rama `rescue/AAAA-MM-DD` (30 días). | Alternativa descartada: `git stash` (pila compartida) | Confianza: media.
- Decisión: `git gc --auto` en cada sesión y `git gc` mensual. | Alternativa descartada: gc manual | Confianza: baja **[provisional]**.
- Decisión: tope de `.git` 1 GB y de `docs/agent-log/` 5 MB, con archivado por fase. | Alternativa descartada: sin tope | Confianza: baja **[provisional]**.

## Riesgos y provisional
- Sin verificar: borrado de rama, `tmpclaude-*`, `dvc gc`, `uv cache prune`, `tar_destroy`, caché de renv. Se cierran en Fase 2.
- Los topes son propuesta; medir `.git` antes de fijarlos.

## Fuentes nuevas
- https://doc.dvc.org/command-reference/gc — referencia de `dvc gc` (flags -w, -c, riesgos); la URL original redirige aquí.
- https://docs.astral.sh/uv/reference/cli/ — referencia de `uv cache prune` y `uv cache clean`, no leída completa.
