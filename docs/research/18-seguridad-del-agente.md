---
item: 18
titulo: Seguridad del agente
modelo: opus
esfuerzo: high
fecha: 2026-10-16
estado: borrador
---
# 18 — Seguridad del agente

## Pregunta
Qué defensas documenta Anthropic contra la inyección indirecta (datos, skills/plugins, memoria) y qué controles mínimos aplicar.

## Hallazgos
- Anthropic admite que la inyección no está resuelta (1 % de éxito residual en navegador); combina RL, clasificadores y red teaming (https://www.anthropic.com/research/prompt-injection-defenses, 2026-10-16).
- Por defecto: WebFetch entrega un resumen de otro modelo, no la página cruda; `curl`/`wget` piden aprobación; fail-closed; Anthropic no audita servidores MCP; recomienda VM ante contenido no confiable (https://code.claude.com/docs/en/security.md, 2026-10-16; https://code.claude.com/docs/en/tools-reference.md, 2026-10-16).
- Orden deny → ask → allow; un deny `Bash(curl *)` no captura rutas ni `sh -c`, por eso se empareja con la red del sandbox (https://code.claude.com/docs/en/permissions.md, 2026-10-16).
- El sandbox (`network.allowedDomains`, `filesystem.denyRead`, `allowUnsandboxedCommands: false`, `failIfUnavailable`) cubre solo shell, no WebFetch, MCP ni hooks; no existe en Windows nativo y admite domain fronting (https://code.claude.com/docs/en/sandboxing.md, 2026-10-16).
- Para aislar el proceso entero: sandbox runtime, contenedor o VM; en Windows, contenedor o WSL2 (https://code.claude.com/docs/en/sandbox-environments.md, 2026-10-16).
- `PreToolUse` puede devolver `permissionDecision: "deny"` o salir con código 2; un timeout no bloquea salvo `onFailure: "block"` (https://code.claude.com/docs/en/hooks.md, 2026-10-16).
- Skills: solo fuentes confiables y auditar todos los archivos (scripts, imágenes), no solo SKILL.md; por tanto, la cuarentena actual es insuficiente (https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview, 2026-10-16). `allowed-tools` rige sin confianza del workspace; `disableSkillShellExecution` anula `!comando` (https://code.claude.com/docs/en/skills.md, 2026-10-16).
- Las fuentes `github`/`git-subdir` aceptan `sha`, también en un marketplace inline `settings`; la autoactualización de terceros viene apagada (https://code.claude.com/docs/en/plugins/marketplace-reference.md, 2026-10-16; https://code.claude.com/docs/en/plugins/host-marketplace.md, 2026-10-16).
- CLAUDE.md y memoria son contexto, no control: para bloquear, hook. MEMORY.md carga 200 líneas; existen `autoMemoryEnabled`, `autoMemoryDirectory`, `claudeMdExcludes` y `/doctor prompt-audit` (https://code.claude.com/docs/en/memory.md, 2026-10-16). La `memory` de subagentes depende de la auto memoria (https://code.claude.com/docs/en/sub-agents.md, 2026-10-16).
- Anthropic no documenta un patrón de auditoría bitácora → memoria **[provisional]**.

## Decisión propuesta
- Decisión: capas para la Fase 3: deny `Bash(curl *)`/`Bash(wget *)` y `WebFetch(domain:...)` solo para `tools/allowed-domains.txt` (inei.gob.pe, datosabiertos.gob.pe, zenodo.org, github.com); hook `PreToolUse` (`Bash|WebFetch|mcp__.*`, `onFailure: "block"`) que niega push a remotos no declarados y hosts fuera de lista; Claude Code en contenedor o WSL2 con sandbox estricto; `quarantine/` con sha256 del árbol completo y `sha` fijado; bitácora → memoria solo por PR humano tras escanear frases de anulación y URL. | Alternativa descartada: confiar en reglas Bash o en el modelo | Confianza: media.

## Riesgos y provisional
- Windows nativo sin sandbox; hooks por regex evadibles. Patrón de memoria **[provisional]**: la Fase 3 lo prueba con inyecciones sembradas.

## Fuentes nuevas
- https://github.com/anthropics/sandbox-runtime — aislar el proceso entero (MCP y hooks).
- https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/ **[no oficial]** — "trifecta letal" como modelo de amenazas.
