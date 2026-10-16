# 17 — Anexo: política de higiene y residuos

Clases de archivo. Regla: un archivo se conserva solo si tiene permanencia justificada; lo demás es regenerable.

| Clase | Ejemplos | Qué se hace | Fuente |
|---|---|---|---|
| Permanente | `docs/`, `raw/**/*.dvc`, manifiestos, lockfiles en `env/` | Versionar en git | Repo |
| Regenerable | `_targets/`, `renv/library/`, `.venv/`, `__pycache__/`, caché DVC | Borrar cuando haga falta espacio; reconstruir con el pipeline | https://docs.ropensci.org/targets/reference/tar_prune.html (2026-10-16) |
| Temporal | `.tq-tmp/`, `tmpclaude-*`, scratchpad de sesión | Borrar al cierre de sesión | https://code.claude.com/docs/en/claude-directory (2026-10-16); `tmpclaude-*` **[provisional]** |
| Worktree limpio | `.claude/worktrees/<n>/` sin cambios ni commits | Se borra con su rama al salir | https://code.claude.com/docs/en/worktrees (2026-10-16) |
| Worktree sucio | Cambios sin commit o commits sin subir | Commit WIP o rama `rescue/AAAA-MM-DD` con expiración de 30 días; después retirar el worktree | Política propuesta; `git stash` descartado por ser pila compartida |
| Respaldo con expiración | Transcripts, `history.jsonl` | Se deja al barrido de `cleanupPeriodDays` (30 días por defecto) | https://code.claude.com/docs/en/claude-directory (2026-10-16) |
| Memoria automática | `~/.claude/projects/<p>/memory/` | Conservar; no se borra mientras tenga contenido | https://code.claude.com/docs/en/claude-directory (2026-10-16) |
| Archivo comprimido con fecha | Bitácoras de fases cerradas | Comprimir en `docs/agent-log/archive/AAAA-MM-DD.tar.gz` | Política propuesta |

Mantenimiento de git:
- `git gc --auto` tras cada sesión; umbral `gc.auto` = 6700 objetos sueltos (https://git-scm.com/docs/git-gc, 2026-10-16).
- `git gc` mensual, precedido de revisión de `git worktree list` para no perder worktrees con trabajo. Cadencia **[provisional]**.
- Pre-release: listar objetos grandes del historial y comprobar que no hay datos crudos ni derivados pesados. Si aparecen, reescribir con `git filter-repo` sobre clon fresco (https://github.com/newren/git-filter-repo, 2026-10-16). Comandos **[provisional]**.

Topes [provisional], a medir antes de fijar:
- `.git` ≤ 1 GB.
- `docs/agent-log/` ≤ 5 MB sin comprimir; archivar por fase cerrada.

Cachés por herramienta (**[provisional]** salvo lo citado):
- targets: `tar_prune()` al cerrar cada fase; `tar_destroy()` solo con confirmación.
- DVC: `dvc gc -w` solo tras verificar el remoto R2 (sha256); `-c` sin revisar riesgos. Sin fuente leída.
- renv: `renv::clean()` en modo interactivo; caché global sin fuente.
- uv: `uv cache prune` en CI. Sin fuente leída.
- Julia: `Pkg.gc()`. Sin fuente consultada.
- Docker: `docker builder prune --keep-storage` con tope; `docker system df` sin fuente. Ninguna limpieza se ejecuta sin petición del usuario.
