# ADR 0001 — Configuración de Claude Code (nivel usuario, gitignore global, WSL)

- **Estado:** superseded por ADR 0008 (2026-10-16); estuvo aceptado desde 2026-10-16 con `.wslconfig` pendiente
- **Fecha:** 2026-10-16
- **Revisión programada:** Fase 1, ítem 1 (verificación contra documentación oficial)

## Contexto

La especificación pide que el agente escriba la configuración de Claude Code (no que el usuario edite JSON), con `effort` alto, permisos `allow` para operaciones no destructivas, `deny` para operaciones destructivas y `ask` para publicación, y que lo documente con las URL oficiales consultadas. El archivo `~/.claude/settings.json` ya existía con configuración de otros proyectos del usuario; había que fusionar sin borrar.

## Documentación consultada (2026-10-15)

| Tema | URL | Hallazgo |
|---|---|---|
| Clave de esfuerzo | https://code.claude.com/docs/en/settings-reference.md | La clave es `effortLevel` (no `effort`); valores `low`, `medium`, `high`, `xhigh`. Env `CLAUDE_CODE_EFFORT_LEVEL` la sobreescribe |
| Permisos | https://code.claude.com/docs/en/permissions.md | Sintaxis `Bash(git push:*)`; precedencia deny → ask → allow; **deny sigue bloqueando en `bypassPermissions`**; `ask` no tiene efecto en ese modo |
| Modos | https://code.claude.com/docs/en/permission-modes.md | `defaultMode` ∈ {default, acceptEdits, plan, auto, dontAsk, bypassPermissions}; `auto` y `bypassPermissions` se ignoran en archivos de proyecto |
| Alcances | https://code.claude.com/docs/en/settings.md | Precedencia: managed > `--settings` > `.claude/settings.local.json` > `.claude/settings.json` > `~/.claude/settings.json`; listas (`allow/deny/ask`) se combinan, escalares se sobreescriben |
| Hooks | https://code.claude.com/docs/en/hooks.md | 33 eventos; `Notification` acepta matcher `idle_prompt`; `PreCompact`/`PostCompact` con matchers `manual`/`auto`; `SubagentStop` expone `last_assistant_message` y acepta `decision: "block"` |
| Subagentes | https://code.claude.com/docs/en/sub-agents.md | Frontmatter admite `model`, `effort`, `isolation: worktree`, `maxTurns`, `memory`, etc. |
| Memoria y reglas | https://code.claude.com/docs/en/memory.md | CLAUDE.md: guía de < 200 líneas (aviso al superarlas); `.claude/rules/*.md` con `paths:` existe |
| Evals | https://code.claude.com/docs/en/plugin-evals.md | `claude plugin eval` existe |

**Advertencia de versión:** el host tenía Claude Code 2.1.195; `effort` por subagente (≥ 2.1.292), `maxEffortLevel` (≥ 2.1.267) e "ignorar `bypassPermissions` en proyecto" (≥ 2.1.257) son posteriores. Se ejecutó `claude update` como parte de esta fase: versión resultante **2.1.301** (verificada con `claude --version` el 2026-10-16), que ya incluye las tres funciones.

## Decisión

### (a) `~/.claude/settings.json`

Fusión sin pérdidas (respaldo `settings.json.bak-20261016`). Añadido:

```json
{
  "effortLevel": "high",
  "permissions": {
    "deny": ["Bash(rm -rf:*)", "Bash(rm -r:*)", "Bash(rmdir /s:*)", "Bash(Remove-Item -Recurse:*)",
             "Bash(git push --force:*)", "Bash(git push -f:*)", "Bash(git push --force-with-lease:*)",
             "Bash(git reset --hard:*)", "Bash(git clean -fd:*)", "Bash(git filter-repo:*)",
             "Bash(dvc gc:*)", "Bash(docker system prune:*)", "Bash(docker volume rm:*)"],
    "ask":  ["Bash(git push:*)", "Bash(gh release:*)", "Bash(gh repo create:*)", "Bash(gh repo delete:*)",
             "Bash(dvc push:*)", "Bash(dvc remote:*)", "Bash(docker compose down -v:*)"]
  }
}
```

Se conservó `allow: ["Bash", ...]` y `defaultMode: "bypassPermissions"` porque los usan otros proyectos del usuario. Consecuencia: a nivel usuario, `deny` es efectivo hoy; `ask` lo será cuando el proyecto fije `defaultMode: "acceptEdits"` en `.claude/settings.json` (Fase 3), que tiene precedencia sobre el nivel usuario.

### (b) Gitignore global

`git config --global core.excludesfile ~/.config/git/ignore` con `.claude/worktrees/`, `tmpclaude-*`, `.Rhistory`, `.RData`, `.Ruserdata`, `Thumbs.db`, `Desktop.ini`, `.DS_Store`. También `init.defaultBranch=main`.

### (c) `%UserProfile%\.wslconfig` — PENDIENTE

En Windows, el límite real de CPU/RAM del contenedor lo fija la VM de WSL2, no `compose.yaml`. Valores derivados de `machine-profile.json` (`derived.wsl_memory_gb`, `derived.wsl_processors`):

```ini
[wsl2]
memory=24GB
processors=7
swap=8GB
localhostForwarding=true
```

Escribirlo requiere `wsl --shutdown` (reinicia Docker Desktop). Se escribe únicamente con aprobación explícita del usuario en la Fase 0.6.

### (d) `.claude/settings.json` del proyecto

Se escribe en la Fase 3 junto con los hooks (cada hook con test).

## Consecuencias

- El agente no puede ejecutar borrados recursivos ni reescribir historial aunque lo intente; publicar (push, release, `dvc push`) pedirá confirmación en cuanto el proyecto active `acceptEdits`.
- Si la Fase 1 (ítem 1) encuentra discrepancias con la documentación oficial, este ADR se supersede con uno nuevo; no se edita.
