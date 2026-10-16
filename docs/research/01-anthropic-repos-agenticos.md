---
item: 1
titulo: Anthropic para repos agénticos y revisión de la configuración de Claude Code
modelo: opus
esfuerzo: high
fecha: 2026-10-16
estado: borrador
---
# 01 — Anthropic para repos agénticos y configuración de Claude Code

## Pregunta
¿Qué dice hoy la documentación oficial sobre configurar repos agénticos en Claude Code, y resiste el ADR 0001?

## Hallazgos
- CLAUDE.md: objetivo < 200 líneas por archivo, con aviso si se supera; lo parcial, a `.claude/rules/*.md` con `paths:` (carga bajo demanda); auto memoria carga 200 líneas o 25KB de `MEMORY.md`, se apaga con `autoMemoryEnabled` (https://code.claude.com/docs/en/memory, 2026-10-16).
- Skills: solo la descripción vive en contexto (tope 1.536 caracteres); `SKILL.md` < 500 líneas; admite `effort`, `model`, `context: fork`, `paths` (https://code.claude.com/docs/en/skills, 2026-10-16).
- Subagentes: `model`, `effort` (`low`…`max`), `isolation: worktree`, `maxTurns`, `memory` (`user|project|local`) confirmados (https://code.claude.com/docs/en/sub-agents, 2026-10-16).
- Los worktrees de subagentes parten de la rama por defecto del remoto (`worktree.baseRef: "fresh"`), no del `HEAD` local; por eso este worktree nació sin `_plantilla.md` (https://code.claude.com/docs/en/worktrees, 2026-10-16).
- Hooks: 33 eventos, entre ellos `SessionStart/End`, `Stop`, `SubagentStop` (con `last_assistant_message` y `decision: "block"`), `PreCompact/PostCompact` (`manual|auto`), `Notification` (`idle_prompt`) (https://code.claude.com/docs/en/hooks, 2026-10-16).
- `effortLevel` ∈ `low|medium|high|xhigh` (sin `max`); `CLAUDE_CODE_EFFORT_LEVEL` y `--effort` mandan; precedencia managed > `--settings` > local > proyecto > usuario y las listas se combinan (https://code.claude.com/docs/en/settings-reference, 2026-10-16; https://code.claude.com/docs/en/settings, 2026-10-16).
- **Discrepancia ADR 0001:** las reglas `ask` sí preguntan en `bypassPermissions`; `deny` bloquea en todo modo; `allow` no tiene efecto ahí; `auto`/`bypassPermissions` no rigen desde archivos de proyecto (https://code.claude.com/docs/en/permission-modes, 2026-10-16).
- **Discrepancia ADR 0001:** las reglas `Bash(...)` no cubren la herramienta PowerShell (usa `PowerShell(...)`), y una regla Bash "no es frontera de seguridad": `git -C . push` la evade; `:*` equivale a ` *` (https://code.claude.com/docs/en/permissions, 2026-10-16).
- El sandbox de Bash no existe en Windows nativo, solo en macOS, Linux y WSL2 (https://code.claude.com/docs/en/sandboxing, 2026-10-16).
- Routines: nube, research preview, intervalo mínimo 1 h; `claude plugin eval` requiere ≥ 2.1.269 (https://code.claude.com/docs/en/routines, 2026-10-16; https://code.claude.com/docs/en/plugin-evals, 2026-10-16).

## Decisión propuesta
- Decisión: superseder ADR 0001 con un ADR nuevo que corrija `ask` en bypass, añada reglas `PowerShell(...)` espejo y un hook `PreToolUse` para push/borrados (diff en `_01-anexo-config.md`) | Alternativa descartada: confiar solo en reglas `Bash(...)` | Confianza: alta.
- Decisión: fijar `"worktree": {"baseRef": "head"}` en `.claude/settings.json` del proyecto | Alternativa descartada: hacer push antes de cada lanzamiento | Confianza: media.

## Riesgos y provisional
- Si `PowerShell(git push:*)` cubre `git push` sin argumentos no está verificado **[provisional]**; lo cierra el test de hooks de la Fase 3.
- Sin sandbox nativo, la defensa real será el hook (Fase 3).

## Fuentes nuevas
- https://code.claude.com/docs/en/hooks-guide — receta oficial de hook `PreToolUse` que bloquea comandos.
- https://code.claude.com/docs/en/sandbox-environments — aislamiento alternativo (dev containers, VM) en Windows.
