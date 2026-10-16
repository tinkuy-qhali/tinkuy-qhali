# ADR 0008 — Revisión de la configuración de Claude Code (supersede al ADR 0001)

- **Estado:** aceptado (parte (a) aprobada por el usuario y aplicada el 2026-10-16 con respaldo `~/.claude/settings.json.bak-20261016-adr0008`; parte (b) aplicada el mismo día; parte (c) programada para la Fase 3)
- **Fecha:** 2026-10-16
- **Supersede:** ADR 0001
- **Fuente:** Fase 1, ítem 1 (`docs/research/01-anthropic-repos-agenticos.md`, anexo `docs/research/_01-anexo-config.md`), ítem 11 e ítem 18.

## Contexto

El ADR 0001 programó su propia revisión contra la documentación oficial en la Fase 1. El ítem 1 verificó fila por fila la tabla "Documentación consultada" del ADR 0001 el 2026-10-16 y encontró tres discrepancias y un hallazgo operativo; los ítems 11 y 18 añadieron ajustes de contexto y seguridad.

## Hallazgos que motivan el cambio (verificados 2026-10-16)

| # | Afirmación del ADR 0001 | Veredicto | Fuente |
|---|---|---|---|
| 1 | "`ask` no tiene efecto en `bypassPermissions`" | **Incorrecto.** Las reglas `ask` explícitas preguntan en todo modo; lo que no tiene efecto en bypass es `allow`. Consecuencia: `ask` ya es efectivo hoy a nivel usuario. | https://code.claude.com/docs/en/permission-modes#actions-no-mode-auto-approves |
| 2 | Reglas `Bash(Remove-Item -Recurse:*)` y `Bash(rmdir /s:*)` | **No aplican.** `Remove-Item` corre por la herramienta PowerShell (reglas `PowerShell(...)`); `rmdir /s` es sintaxis de cmd. Claude Code ya trae chequeos propios para `Remove-Item` y `rd/rmdir/del`. | https://code.claude.com/docs/en/permission-modes#remove-item-in-powershell |
| 3 | "El agente no puede ejecutar borrados recursivos ni reescribir historial aunque lo intente" | **Sobreafirma.** Las reglas Bash no son frontera de seguridad: `git -C . push`, `bash -c '...'`, `/bin/rm -rf` las evaden. | https://code.claude.com/docs/en/permissions#bash-rule-limits |
| 4 | Worktrees de subagentes | Partían de `origin/HEAD` (`worktree.baseRef: "fresh"`), por lo que nacían sin los archivos recién commiteados en local. | https://code.claude.com/docs/en/worktrees#choose-the-base-branch |
| 5 | Sandbox | No existe en Windows nativo (solo macOS, Linux, WSL2); `sandbox.enabled: false` no cambia nada en este host. | https://code.claude.com/docs/en/sandboxing |
| 6 | Sesión inactiva | Sí consume tokens: `idleCompaction` viene activada (≈54 min, ≥200k tokens). | https://code.claude.com/docs/en/settings-reference |

Lo demás del ADR 0001 (`effortLevel` y sus valores, sintaxis `:*`, `deny` bloquea en bypass, `auto`/`bypassPermissions` ignorados en archivos de proyecto, precedencia de alcances, catálogo de hooks, `claude plugin eval`) se confirmó correcto.

## Decisión

### (a) `~/.claude/settings.json` (usuario) — APLICADO el 2026-10-16

Aprobado por el usuario tras ver el diff; respaldo en `settings.json.bak-20261016-adr0008`. Resultado: 23 reglas `deny`, 14 `ask`, `idleCompaction: false`; `allow` y `defaultMode: bypassPermissions` conservados. Test ejecutado: `curl -sI https://example.com` desde la herramienta Bash fue denegado en la misma sesión.

```diff
   "permissions": {
     "deny": [
       "Bash(rm -rf:*)",
       "Bash(rm -r:*)",
-      "Bash(rmdir /s:*)",
-      "Bash(Remove-Item -Recurse:*)",
+      "PowerShell(Remove-Item * -Recurse*)",
       "Bash(git push --force:*)", "Bash(git push -f:*)", "Bash(git push --force-with-lease:*)",
       "Bash(git reset --hard:*)", "Bash(git clean -fd:*)", "Bash(git filter-repo:*)",
       "Bash(dvc gc:*)", "Bash(docker system prune:*)", "Bash(docker volume rm:*)",
+      "PowerShell(git push --force:*)", "PowerShell(git push -f:*)", "PowerShell(git push --force-with-lease:*)",
+      "PowerShell(git reset --hard:*)", "PowerShell(git clean -fd:*)", "PowerShell(git filter-repo:*)",
+      "PowerShell(dvc gc:*)", "PowerShell(docker system prune:*)", "PowerShell(docker volume rm:*)",
+      "Bash(curl:*)", "Bash(wget:*)"
     ],
     "ask": [
       "Bash(git push:*)", "Bash(gh release:*)", "Bash(gh repo create:*)", "Bash(gh repo delete:*)",
       "Bash(dvc push:*)", "Bash(dvc remote:*)", "Bash(docker compose down -v:*)",
+      "PowerShell(git push:*)", "PowerShell(gh release:*)", "PowerShell(gh repo create:*)", "PowerShell(gh repo delete:*)",
+      "PowerShell(dvc push:*)", "PowerShell(dvc remote:*)", "PowerShell(docker compose down -v:*)"
     ]
   },
+  "idleCompaction": false
```

- `Bash(curl:*)`/`Bash(wget:*)` en `deny` viene del ítem 18: toda descarga pasa por scripts del repo (`tools/`) con lista de dominios, no por el agente a mano. **[provisional]**: si bloquea un flujo legítimo (p. ej. un script de `tools/` que el agente invoque), la regla se afina en la Fase 3.
- `idleCompaction: false` viene del ítem 11: la política de contexto es por fase, con volcado a bitácora; la compactación en reposo gasta tokens sin control.
- **[provisional]**: si `PowerShell(git push:*)` cubre `git push` sin argumentos y si `Remove-Item * -Recurse*` aguanta otro orden de parámetros; lo cierran los tests de hooks de la Fase 3.

### (b) `.claude/settings.json` (proyecto) — APLICADO el 2026-10-16

```json
{ "worktree": { "baseRef": "head" } }
```

Se añadió esa clave al archivo existente, que ya contenía `enabledPlugins` y `extraKnownMarketplaces` (tres plugins habilitados sin commit fijado: su fijación por `sha` y la revisión del skill `pptx` quedan para la cuarentena de la Fase 3, revisión adversarial M21). Los subagentes con `isolation: worktree` parten ahora del `HEAD` local. Verificado en esta sesión: el primer worktree creado tras el cambio ya contenía `docs/research/_plantilla.md` y `tools/check_research.py`; los anteriores nacían sin ellos y hubo que sembrarlos a mano. `defaultMode: "acceptEdits"` sigue programado para la Fase 3 junto con los hooks.

### (c) Hook `PreToolUse` (Fase 3, con test)

Matcher `Bash|PowerShell|WebFetch|mcp__.*` (unifica el ADR, el informe 18 y `docs/policies/security.md`; addendum 2026-10-16 por la revisión adversarial M5): normaliza el comando, bloquea hosts fuera de `tools/allowed-domains.txt`, (quita `git -C <dir>`, `-c k=v`, ruta absoluta del binario, `bash -c`) y sale con código 2 ante push forzado, `reset --hard`, `clean -fd`, `filter-repo`, `dvc gc`, borrados recursivos y push a remotos no declarados. Un hook con exit 2 detiene la llamada antes de evaluar `allow`. Es la defensa real en Windows nativo, donde no hay sandbox; las reglas de permisos son la primera capa, no la única.

## Consecuencias

- El ADR 0001 queda superseded; no se edita. Sus hallazgos correctos siguen vigentes por referencia.
- La frase "no puede ejecutar aunque lo intente" se reemplaza por "la primera capa lo bloquea; la frontera es el hook de la Fase 3 y la ejecución dentro del contenedor".
- La parte (a) exige aprobación del usuario antes de tocar `~/.claude/settings.json`.
