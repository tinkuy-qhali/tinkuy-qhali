---
item: 11
titulo: Automatización, loops y gestión de contexto
modelo: opus
esfuerzo: high
fecha: 2026-10-16
estado: borrador
---
# 11 — Automatización, loops y gestión de contexto

## Pregunta
Mecanismos oficiales para relanzar al agente mientras fallen validadores, programar trabajo y gestionar contexto; ¿vale la política «por fase» de ADR 0000?

## Hallazgos
- Stop: `decision: "block"` exige `reason`; entrada con `stop_hook_active`. Tope nativo: 8 continuaciones seguidas (reinicia con cada tool call), ajustable con `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` (https://code.claude.com/docs/en/hooks.md, 2026-10-16).
- `/goal` es un Stop hook por prompt: un modelo pequeño juzga la condición tras cada turno, sin ejecutar herramientas (https://code.claude.com/docs/en/goal.md, 2026-10-16).
- SubagentStop expone `last_assistant_message` y acepta `block`; `maxTurns` devuelve salida parcial reanudable (https://code.claude.com/docs/en/hooks.md, https://code.claude.com/docs/en/sub-agents.md, 2026-10-16).
- PreCompact (`manual`/`auto`) puede bloquear; PostCompact recibe `compact_summary`, sin decisión; SessionStart tiene matcher `compact` (https://code.claude.com/docs/en/hooks.md, 2026-10-16).
- `idle_prompt`: ~60 s tras responder sin escritura del usuario (https://code.claude.com/docs/en/hooks.md, 2026-10-16).
- Refutado: el umbral de auto-compact SÍ se configura (`autoCompactWindow`, 100k–1M tokens) (https://code.claude.com/docs/en/model-config.md, 2026-10-16).
- Refutado: la sesión inactiva SÍ consume tokens: `idleCompaction` (por defecto, ~54 min, ≥200k tokens) y resúmenes de fondo (https://code.claude.com/docs/en/settings-reference.md, https://code.claude.com/docs/en/costs.md, 2026-10-16).
- Confirmado: ningún hook ejecuta `/compact` ni `/clear` (`/loop` los entrega como texto); ningún timeout cierra la sesión (https://code.claude.com/docs/en/hooks.md, https://code.claude.com/docs/en/scheduled-tasks.md, 2026-10-16).
- Routines: nube, research preview, mínimo 1 h, clon limpio; tareas Desktop: locales, máquina despierta; `/loop`: expira a 7 días (https://code.claude.com/docs/en/routines.md, https://code.claude.com/docs/en/scheduled-tasks.md, 2026-10-16).
- `anthropics/claude-code-action@v1` ejecuta Claude (no determinista) en el workflow; cuesta minutos y tokens (https://code.claude.com/docs/en/github-actions.md, 2026-10-16).
- Graders deterministas cuando sea posible; jueces LLM calibrados con humanos; leer transcripciones (https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents, 2026-10-16); evaluator-optimizer con máximo de iteraciones (https://www.anthropic.com/engineering/building-effective-agents, 2026-10-16).
- scite: citar solo lo recuperado y revisar `editorialNotices` (https://docs.scite.ai/mcp/prompts, 2026-10-16); el conector PubMed es oficial (https://www.anthropic.com/news/claude-for-life-sciences, 2026-10-16).

## Decisión propuesta
- Decisión: mantener la política por fase; PreCompact vuelca estado a bitácora y SessionStart `compact` lo reinyecta | Alternativa descartada: compactar por porcentaje | Confianza: alta.
- Decisión: Stop hook con validadores deterministas y contador en archivo | Alternativa descartada: `/goal` como juez único | Confianza: media.
- Decisión: validadores y benchmark en GitHub Actions con pasos deterministas; `claude-code-action` solo para revisión opcional | Alternativa descartada: validar con la acción | Confianza: alta.
- Decisión: `idleCompaction: false`; crítico como subagente de solo lectura | Alternativa descartada: compactación inactiva | Confianza: media.

## Riesgos y provisional
- Routines en research preview: límites cambiables (Fase 3).
- Contador en archivo: diseño propio **[provisional]**, con tests en Fase 3.
- Sin documentación oficial verificada del MCP de bioRxiv **[provisional]**.

## Fuentes nuevas
- https://code.claude.com/docs/en/hooks-guide.md — tope de bloqueos y hooks por prompt.
- https://github.com/anthropics/claude-code-action/blob/main/docs/security.md — seguridad de la acción antes de usarla en CI.
