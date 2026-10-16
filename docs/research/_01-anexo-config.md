# Anexo 01 — Diff propuesto de configuración (NO aplicado)

Fecha de verificación: 2026-10-16. Nada de esto se aplicó; requiere un ADR nuevo que superseda al 0001.

## 1. Verificación fila a fila de "Documentación consultada" (ADR 0001)

| Fila | Veredicto | Evidencia (consultada 2026-10-16) |
|---|---|---|
| `effortLevel`, valores low/medium/high/xhigh, env var | Correcto | https://code.claude.com/docs/en/settings-reference#effortlevel — `--effort` y `CLAUDE_CODE_EFFORT_LEVEL` lo sobreescriben; `max` solo existe en `maxEffortLevel`, subagentes y skills |
| `Bash(git push:*)` | Correcto | https://code.claude.com/docs/en/permissions — "The `:*` suffix is an equivalent way to write a trailing wildcard"; solo vale al final del patrón; el diálogo escribe la forma con espacio |
| Precedencia deny → ask → allow | Correcto | https://code.claude.com/docs/en/permissions |
| deny bloquea en bypassPermissions | Correcto | https://code.claude.com/docs/en/permission-modes — "Deny rules block in every mode, including `bypassPermissions`" |
| "`ask` no tiene efecto en ese modo" | **INCORRECTO** | https://code.claude.com/docs/en/permission-modes#actions-no-mode-auto-approves — las reglas `ask` explícitas preguntan en todo modo, incluido bypass. Lo que no tiene efecto en bypass es `allow` |
| `auto` y `bypassPermissions` ignorados en proyecto | Correcto (matiz) | https://code.claude.com/docs/en/permission-modes — `auto` en proyecto/local cae al default integrado (no al `defaultMode` de usuario); `bypassPermissions` en proyecto arranca en Manual (desde v2.1.257) |
| Precedencia de alcances; listas se combinan | Correcto | https://code.claude.com/docs/en/settings#settings-precedence |
| Hooks: 33 eventos, matchers citados | Correcto | https://code.claude.com/docs/en/hooks — `idle_prompt`, `manual`/`auto`, `last_assistant_message`, `decision: "block"` confirmados |
| Subagentes: frontmatter | Correcto | https://code.claude.com/docs/en/sub-agents — `effort` admite también `max` |
| CLAUDE.md < 200 líneas con aviso; rules con `paths:` | Correcto | https://code.claude.com/docs/en/memory |
| `claude plugin eval` existe | Correcto | https://code.claude.com/docs/en/plugin-evals — requiere v2.1.269+ |

Discrepancias fuera de la tabla:

- Sección (a), "Consecuencia": `ask` ya es efectivo hoy a nivel usuario aun con `bypassPermissions`; no depende de que el proyecto fije `acceptEdits`.
- Sección "Consecuencias": "El agente no puede ejecutar borrados recursivos ni reescribir historial aunque lo intente" sobreafirma. Las reglas Bash no son frontera de seguridad (`/bin/rm -rf`, `bash -c '...'`, `git -C . push` las evaden; https://code.claude.com/docs/en/permissions#bash-rule-limits) y no cubren la herramienta PowerShell.
- `Bash(Remove-Item -Recurse:*)` y `Bash(rmdir /s:*)` no casan en la práctica: `Remove-Item` se ejecuta vía la herramienta PowerShell; `rmdir /s` es sintaxis de cmd. Claude Code ya trae chequeos propios para `Remove-Item` y `rd/rmdir/del/erase` en PowerShell (https://code.claude.com/docs/en/permission-modes#remove-item-in-powershell).
- El sandbox no existe en Windows nativo (https://code.claude.com/docs/en/sandboxing); el `sandbox.enabled: false` actual no cambia nada en este host.

## 2. Diff propuesto — `~/.claude/settings.json` (usuario)

```diff
   "permissions": {
     "deny": [
       "Bash(rm -rf:*)",
       "Bash(rm -r:*)",
-      "Bash(rmdir /s:*)",
-      "Bash(Remove-Item -Recurse:*)",
+      "PowerShell(Remove-Item * -Recurse*)",
       "Bash(git push --force:*)",
       ...
+      "PowerShell(git push --force:*)",
+      "PowerShell(git push -f:*)",
+      "PowerShell(git push --force-with-lease:*)",
+      "PowerShell(git reset --hard:*)",
+      "PowerShell(git clean -fd:*)",
+      "PowerShell(git filter-repo:*)",
+      "PowerShell(dvc gc:*)",
+      "PowerShell(docker system prune:*)",
+      "PowerShell(docker volume rm:*)"
     ],
     "ask": [
       "Bash(git push:*)",
       ...
+      "PowerShell(git push:*)",
+      "PowerShell(gh release:*)",
+      "PowerShell(gh repo create:*)",
+      "PowerShell(gh repo delete:*)",
+      "PowerShell(dvc push:*)",
+      "PowerShell(dvc remote:*)",
+      "PowerShell(docker compose down -v:*)"
     ]
```

[provisional] Patrón `PowerShell(Remove-Item * -Recurse*)`: los comodines de PowerShell casan en cualquier posición y los alias (`rm`, `ri`, `del`) se canonicalizan, pero el orden de parámetros puede variar; validar con test en la Fase 3.

## 3. Diff propuesto — `.claude/settings.json` (proyecto)

```diff
 {
+  "worktree": { "baseRef": "head" },
+  "permissions": { "defaultMode": "acceptEdits" },
   "enabledPlugins": { ... },
```

- `baseRef: "head"`: los subagentes con `isolation: worktree` parten del `HEAD` local, no de `origin/HEAD` (https://code.claude.com/docs/en/worktrees#choose-the-base-branch).
- `defaultMode: "acceptEdits"`: ya previsto para la Fase 3; la app de escritorio y VS Code no leen el modo inicial desde el archivo de proyecto.

## 4. Hook propuesto (Fase 3, con test)

`PreToolUse` con matcher `Bash|PowerShell` que normalice el comando (quitar `git -C <dir>`, `-c k=v`, rutas absolutas del binario, `bash -c`) y devuelva exit 2 ante push forzado, `reset --hard`, `clean -fd`, `filter-repo`, `dvc gc` y borrados recursivos. Un hook con exit 2 detiene la llamada antes de evaluar las reglas allow (https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks).
