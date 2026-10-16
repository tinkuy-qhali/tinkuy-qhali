---
titulo: Higiene y residuos
estado: borrador
fecha: 2026-10-16
fase_aplicacion: F3
fuentes: [docs/research/17-higiene-y-residuos.md, docs/research/_17-anexo-politica.md, docs/research/13-nomenclatura-bitacoras-metaaprendizaje.md, docs/research/_13-anexo-convenciones.md, docs/adr/0008-config-claude-code-revision.md, .gitignore]
---
# Política: Higiene y residuos

## Propósito
Evitar que el repo y el disco acumulen residuos de sesiones, worktrees y cachés, y que datos pesados o sensibles entren al historial de git. Cada archivo tiene una clase (permanente, regenerable, temporal o respaldo con expiración) y cada clase una acción; nada se borra sin saber si es regenerable.

## Reglas
R1. Todo archivo se clasifica en una de estas clases y se trata según la tabla: **permanente** (`docs/`, `raw/**/*.dvc`, manifiestos, lockfiles en `env/`: se versiona); **regenerable** (`_targets/`, `renv/library/`, `.venv/`, `__pycache__/`, caché DVC: se borra si falta espacio y se reconstruye); **temporal** (`.tq-tmp/`, `tmpclaude-*`, scratchpad: se borra al cerrar sesión); **respaldo con expiración** (transcripts, `history.jsonl`: los barre `cleanupPeriodDays`, 30 por defecto). — **Por qué:** un archivo se conserva solo con permanencia justificada (anexo 17). — **Se verifica con:** manual; `git status --ignored` lista lo no versionado.
R2. `.gitignore` conserva obligatoriamente: `machine-profile.json`, `.tq-tmp/`, `.claude/worktrees/`, `.claude/settings.local.json`, `tmpclaude-*`, `raw/**` (con excepciones `*.dvc`, `manifest.json`, `manifest.sha256`), `standardized/`, `harmonized/`, `marts/`, `quarantine/`, `*.parquet`, `*.duckdb`, cachés (`_targets/`, `.venv/`, `renv/library/`, `.dvc/cache/`, `benchmarks/.cache/`) y secretos (`.env`, `.env.*`, `*.pem`). — **Por qué:** los bytes crudos se resuelven por hash, no por git; la doc oficial recomienda ignorar `.claude/worktrees/`. — **Se verifica con:** `git check-ignore -v <ruta>` y `tests/test_bootstrap.sh`.
R3. Al cierre de sesión se retiran los temporales (`.tq-tmp/`, `tmpclaude-*`, scratchpad) sin tocar permanentes ni regenerables. Como las reglas `deny` bloquean `rm -r`/`rm -rf`, se borran archivos concretos o lo hace el usuario; no se evade la regla. — **Por qué:** una regla `deny` ya bloqueó un comando propio (bitácora 0.6). — **Se verifica con:** `git status --ignored --short` al cierre (**[propuesta]**: hook `SessionEnd`).
R4. Un worktree limpio (sin cambios ni commits sin subir) se borra con su rama al salir; uno sucio recibe un commit WIP o pasa a la rama `rescue/AAAA-MM-DD`, que expira a los 30 días. Nunca `git stash` (pila compartida entre worktrees). — **Por qué:** `git stash` es compartido y otras sesiones pueden sacar la entrada ajena (informe 17). — **Se verifica con:** `git worktree list` y `git branch --list 'rescue/*'`.
R5. Los worktrees se gestionan con `git worktree remove <ruta>` (rechaza los sucios sin `--force`), `git worktree unlock` antes de retirar uno bloqueado (p. ej. un agente reanudado) y `git worktree prune` para metadatos huérfanos. `--force` solo tras cosechar el contenido. — **Por qué:** `remove` protege el trabajo no guardado; `tools/harvest_research.py --prune` usa `--force` porque ya copió los informes. — **Se verifica con:** `git worktree list` sin entradas `prunable`.
R6. Las bitácoras de fases cerradas se archivan comprimidas con fecha y se deja un índice; no se borran. La ruta exacta está en conflicto entre informes (ver Provisional); mientras tanto, solo se rota por fase cerrada. — **Por qué:** conservan el *por qué* de las decisiones y reducen el tamaño de `docs/agent-log/`. — **Se verifica con:** `du -sk docs/agent-log` <= 5120 (**[provisional]**).
R7. Topes **[provisional]**: `.git` <= 1 GB y `docs/agent-log/` <= 5 MB sin comprimir; se mide `.git` antes de fijarlos y se archiva por fase al superarlos. — **Por qué:** el informe 17 los propone sin medición previa. — **Se verifica con:** `du -sk .git docs/agent-log`.
R8. `git gc --auto` tras cada sesión (umbral `gc.auto` = 6700 objetos sueltos) y `git gc` mensual, precedido de `git worktree list` para no perder worktrees con trabajo. — **Por qué:** `gc` poda worktrees tras `gc.worktreePruneExpire` (3 meses) y objetos huérfanos tras `gc.pruneExpire` (2 semanas). — **Se verifica con:** `git count-objects -vH`; cadencia **[provisional]**.
R9. Antes de cada release se listan los blobs más grandes del historial y se comprueba que no hay datos crudos ni derivados pesados (comando **[provisional]**, p. ej. `git rev-list --objects --all | git cat-file --batch-check=...`). — **Por qué:** los repos son públicos desde el commit 1 (ADR 0002). — **Se verifica con:** paso de CI pre-release (**[propuesta]**).
R10. Si aparecen blobs indebidos, el remedio es `git filter-repo` sobre un clon fresco, ejecutado por el usuario (está en `deny`), con aviso de reescritura de historia. — **Por qué:** filter-repo reescribe la historia y exige clon fresco salvo `--force` (informe 17). — **Se verifica con:** manual (ADR antes de reescribir historia).
R11. Cachés regenerables: `tar_prune()` al cerrar cada fase; `tar_destroy()` solo con confirmación; `renv::clean()` en modo interactivo; `uv cache prune` en CI; `Pkg.gc()` para Julia; Docker solo `docker builder prune --keep-storage <tope>`. — **Por qué:** `prune` borra lo huérfano y `destroy` todo (informe 17: **[provisional]** salvo lo citado). — **Se verifica con:** manual.
R12. `dvc gc -w` solo tras verificar en R2 el sha256 de lo que se conserva; `dvc gc -c`, `docker system prune`, `docker volume rm` y `docker compose down -v` solo por el usuario. — **Por qué:** `dvc gc` puede borrar la única copia; están en `deny`/`ask` (ADR 0008). — **Se verifica con:** reglas en `~/.claude/settings.json`; `dvc pull` en clon limpio.
R13. Transcripts, `history.jsonl` y scratchpad se dejan al barrido de `cleanupPeriodDays`; la memoria automática (`~/.claude/projects/<p>/memory/`) se conserva mientras tenga contenido. — **Por qué:** es el comportamiento oficial; borrarlos a mano no aporta. — **Se verifica con:** manual.
R14. Ninguna limpieza de Docker o de cachés compartidas se ejecuta sin petición expresa del usuario; el agente propone el comando y el efecto esperado. — **Por qué:** los volúmenes guardan `renv`, DVC, `raw/` y el depot de Julia (ADR 0000). — **Se verifica con:** manual.
R15. Los nombres de lo archivado cumplen las convenciones del informe 13: `kebab-case` ASCII, fechas `YYYY-MM-DD`, ramas `tipo/tema` (`rescue/AAAA-MM-DD` es la excepción de higiene). — **Por qué:** legibles por máquina y ordenables. — **Se verifica con:** `tools/check_research.py` para informes; manual para el resto.

## Qué hace el agente y qué no
- Hace: clasifica antes de borrar; retira temporales y worktrees limpios; crea `rescue/AAAA-MM-DD` para trabajo sucio; ejecuta `git gc --auto`, `git worktree prune`, `tar_prune()`; informa tamaños de `.git` y `docs/agent-log/`.
- No hace: `git filter-repo`, `dvc gc`, `docker system prune`, `docker volume rm`, `rm -r`, `git clean -fd` ni `git push --force` (todos en `deny`); borrar ramas `rescue/*` antes de 30 días; limpiar cachés compartidas sin petición; usar `git stash`.

## Mecanismos que la hacen cumplir (Fase 3)
| Mecanismo | Tipo (hook/test/CI/skill) | Evento o disparador | Estado |
|---|---|---|---|
| Test de entradas obligatorias de `.gitignore` | test | CI `validate` | por implementar |
| Reporte de residuos y worktrees al cierre | hook | `SessionEnd` **[propuesta]** | por implementar |
| Comprobación de tamaños (`.git`, `docs/agent-log/`) | test/CI | `validate` | por implementar |
| Comprobación de blobs grandes pre-release | CI | workflow de release | por implementar |
| Skill de cierre de sesión (clasificar, rescue, prune) **[propuesta]** | skill | cierre de sesión | por implementar |
| Reglas `deny`/`ask` de borrado y reescritura | hook/config | `PreToolUse` y `settings.json` (ADR 0008) | por implementar (hook); reglas aplicadas |

## Provisional
- Topes de `.git` (1 GB) y `docs/agent-log/` (5 MB); medir antes de fijarlos (informe 17; Fase 3).
- Cadencia de `git gc` mensual; comandos de blobs grandes; `tmpclaude-*` sin fuente; que `worktree remove` conserve la rama (informe 17; Fase 2).
- `dvc gc`, `uv cache prune`, `tar_destroy`, caché global de renv, `Pkg.gc()` y `docker system df`: sin lectura completa (informe 17; Fase 2).
- Resuelto por ADR 0013 (decisión 5): el archivo va a `docs/agent-log/archivo/AAAA/` **sin comprimir** (git ya comprime y un `.tar.gz` no es legible ni diffeable por el agente), con `docs/agent-log/archivo/INDEX.md`; disparador: cierre de fase con archivos de más de 90 días o carpeta > 5 MB (umbrales [provisional]).

## Fuentes
- Informes docs/research/17, 13, `_17-anexo-politica.md`, `_13-anexo-convenciones.md`; ADR 0008; bitácoras de las Fases 0.6 y 1; `.gitignore`.
- https://code.claude.com/docs/en/worktrees (2026-10-16)
- https://code.claude.com/docs/en/claude-directory (2026-10-16)
- https://git-scm.com/docs/git-worktree (2026-10-16)
- https://git-scm.com/docs/git-gc (2026-10-16)
- https://rstudio.github.io/renv/reference/clean.html (2026-10-16)
- https://docs.ropensci.org/targets/reference/tar_prune.html (2026-10-16)
- https://docs.docker.com/reference/cli/docker/builder/prune/ (2026-10-16)
- https://github.com/newren/git-filter-repo (2026-10-16)
- https://doc.dvc.org/command-reference/gc (informe 17, fuente nueva)
- https://docs.astral.sh/uv/reference/cli/ (informe 17, fuente nueva)
- https://speakerdeck.com/jennybc/how-to-name-files (2026-10-16)
