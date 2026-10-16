---
titulo: Gestión de contexto y subsesiones
estado: borrador
fecha: 2026-10-16
fase_aplicacion: F3
fuentes: [docs/research/11-automatizacion-loops-contexto.md, docs/research/02-prompting-y-politicas.md, docs/research/13-nomenclatura-bitacoras-metaaprendizaje.md, docs/research/_13-anexo-convenciones.md, docs/adr/0000-alineacion.md, docs/adr/0008-config-claude-code-revision.md]
---
# Política: Gestión de contexto y subsesiones

## Propósito
Mantener el contexto del agente pequeño, recuperable y verificable: el estado vive en archivos y git, no en la ventana. Protege contra la deriva, la pérdida de instrucciones al compactar, el gasto de tokens sin control y los subagentes que no terminan o devuelven ruido.

## Reglas
R1. El contexto se gestiona por fase del plan (ADR 0000), nunca por porcentaje de ventana. — **Por qué:** el informe 11 mantiene la política por fase y descarta compactar por porcentaje. — **Se verifica con:** manual (revisión al cierre de fase).
R2. Al cerrar una fase o una tarea dorada, el agente vuelca a `docs/agent-log/AAAA-MM-DD-faseX-tema.md` un resumen de 5 líneas (hecho, pendiente, decisiones, incidentes, siguiente) y el humano ejecuta `/clear`. — **Por qué:** ningún hook ejecuta `/compact` ni `/clear` (informe 11) y una ventana nueva suele superar a compactar (informe 02). — **Se verifica con:** `ls docs/agent-log/*-faseX-*.md`; test de aceptación de la fase (p. ej. `tests/test_f1_acceptance.sh`).
R3. `PreCompact` (matchers `manual`/`auto`) vuelca el estado a la bitácora y puede bloquear la compactación si el volcado falló; `SessionStart` con matcher `compact` lo reinyecta; `PostCompact` solo recibe `compact_summary`, sin decisión. — **Por qué:** al compactar pueden perderse instrucciones tempranas (informe 13); la compactación es red de seguridad, no el método. — **Se verifica con:** test de hooks de la Fase 3 (por implementar).
R4. `Stop` y `SubagentStop` relanzan al agente (`decision: "block"` con `reason`) solo mientras fallen validadores deterministas; el contador de reintentos vive en un archivo y respeta el tope nativo de 8 continuaciones seguidas (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`). — **Por qué:** `/goal` usa un modelo pequeño sin herramientas y no basta como juez único (informe 11). — **Se verifica con:** tests del contador, Fase 3 (**[provisional]**).
R5. `Notification` con `idle_prompt` (~60 s tras responder sin escritura del usuario) solo avisa; nunca dispara `/compact`, `/clear` ni trabajo nuevo. — **Por qué:** es un aviso, no un temporizador de sesión; ningún timeout cierra la sesión (informe 11). — **Se verifica con:** manual (revisar `settings.json`).
R6. `idleCompaction` queda en `false`, ya aplicado en `~/.claude/settings.json` por el ADR 0008. — **Por qué:** la sesión inactiva sí consume tokens (por defecto ~54 min y >= 200k tokens). — **Se verifica con:** `grep -n idleCompaction ~/.claude/settings.json`.
R7. Todo subagente nace con un criterio de salida ejecutable (comando o validador con código 0/1), p. ej. `tools/check_research.py` en la Fase 1. — **Por qué:** sin criterio ejecutable hay afirmación, no verificación (informes 02 y 11). — **Se verifica con:** el comando del criterio, citado en el prompt de lanzamiento.
R8. Iteraciones máximas por subagente **[propuesta]**: 3 intentos contra su criterio de salida, con `maxTurns` en su definición; al agotarlos informa el fallo en vez de seguir. — **Por qué:** evaluator-optimizer exige un máximo de iteraciones y `maxTurns` devuelve salida parcial reanudable (informe 11). — **Se verifica con:** manual hasta el test de Fase 3; el 3 se calibra tras la Fase 2.
R9. El informe del subagente al padre tiene <= 12 líneas: rutas, resultado del criterio de salida, decisiones, contradicciones y pendientes. — **Por qué:** los subagentes devuelven resúmenes de 1.000–2.000 tokens, no volcados (informe 02). — **Se verifica con:** `SubagentStop` sobre `last_assistant_message` (**[propuesta]**) o manual.
R10. Los subagentes que escriben archivos usan `isolation: worktree` con `worktree.baseRef: "head"` (ya en `.claude/settings.json`) y como máximo 4 en paralelo (`machine-profile.json`). — **Por qué:** con `"fresh"` nacían sin los archivos recién commiteados (ADR 0008; bitácora Fase 1). — **Se verifica con:** `grep baseRef .claude/settings.json`.
R11. Los informes se cosechan con `python tools/harvest_research.py [--prune]` y se validan con `tools/check_research.py`; el padre commitea por grupos. — **Por qué:** el worktree es efímero y el informe debe entrar al repo normalizado a LF. — **Se verifica con:** `bash tests/test_check_research.sh`.
R12. Anti-deriva: releer la tarea antes de cerrar; `/clear` tras dos correcciones fallidas; toda cifra con cita o etiqueta [provisional]; revisor en subagente de solo lectura con contexto fresco. — **Por qué:** informe 02 (sycofancia y anclaje sin fuente oficial: **[provisional]**). — **Se verifica con:** manual / revisor en contexto fresco.
R13. Ahorro de tokens: CLAUDE.md corto (< 200 líneas) y lo ocasional en skills; scripts que devuelven resúmenes, no datos crudos; leer por rangos; explorar con subagentes. — **Por qué:** el contexto es un recurso finito (informes 02 y 13). — **Se verifica con:** `wc -l CLAUDE.md`.
R14. `docs/agent-log/` se rota al cerrar fase o al pasar de 300 líneas por archivo (se divide); lo de más de 90 días va a `docs/agent-log/archivo/AAAA/` con `INDEX.md`; nunca se borra. — **Por qué:** conserva el *por qué* sin inflar el contexto de arranque (informe 13). — **Se verifica con:** `wc -l docs/agent-log/*.md` (umbrales **[provisional]**).
R15. `LESSONS.md` (raíz) tiene <= 100 líneas con entradas fechadas; el agente propone y el humano aprueba; 2 recurrencias la promueven a regla y un incumplimiento crítico a hook. — **Por qué:** los hooks son deterministas y CLAUDE.md es consultivo (informe 13). — **Se verifica con:** `wc -l LESSONS.md`.

## Qué hace el agente y qué no
- Hace: escribe la bitácora de 5 líneas al cerrar fase; propone lecciones; lanza subagentes con criterio de salida y máximo de intentos; devuelve informes de <= 12 líneas; marca [provisional] lo no verificado.
- No hace: ejecutar `/clear` o `/compact` por su cuenta (no existe hook que lo permita); compactar por porcentaje; usar `/goal` como único juez; editar `settings.json`, memoria o CLAUDE.md sin ADR o aprobación; pasar bitácoras o lecciones a la memoria sin PR humano (informe 18, consolidado en `00`).

## Mecanismos que la hacen cumplir (Fase 3)
| Mecanismo | Tipo (hook/test/CI/skill) | Evento o disparador | Estado |
|---|---|---|---|
| Volcado de estado a bitácora | hook | `PreCompact` (`manual`/`auto`) | por implementar |
| Reinyección del volcado | hook | `SessionStart` matcher `compact` | por implementar |
| Relanzar mientras fallen validadores, con contador en archivo | hook | `Stop` / `SubagentStop` | por implementar |
| Test del contador y del tope de 8 | test | CI `validate` | por implementar |
| Aviso de inactividad (solo notifica) | hook | `Notification` `idle_prompt` | por implementar |
| Chequeo de informe <= 12 líneas **[propuesta]** | hook | `SubagentStop` (`last_assistant_message`) | por implementar |
| Umbrales de bitácora y `LESSONS.md` **[propuesta]** | test/CI | `validate` | por implementar |
| Skill de cierre de fase (volcado + checklist) **[propuesta]** | skill | cierre de fase | por implementar |

## Provisional
- Contador de reintentos en archivo: diseño propio; tests en Fase 3 (informe 11).
- Routines en research preview (límites cambiables) y MCP de bioRxiv sin documentación oficial verificada (informe 11; Fase 3).
- Sycofancia/anclaje sin fuente oficial; evaluación propia pendiente (informe 02).
- Umbrales de 300 líneas, 90 días y 100 líneas; rotación en otros proyectos sin fuente; se ajustan tras la Fase 2 (informe 13).
- Máximo de 3 iteraciones por subagente y límite de 12 líneas: sin fuente en los informes; se fijan en la Fase 3.
- Contradicción abierta: `archivo/AAAA/` (informe 13) frente a `archive/AAAA-MM-DD.tar.gz` (informe 17); ver `hygiene.md`.

## Fuentes
- Informes docs/research/11, 02, 13 y `_13-anexo-convenciones.md`; ADR 0000 y 0008; bitácoras `docs/agent-log/2026-10-16-fase0-6-estado.md` y `2026-10-16-fase1-estado.md`.
- https://code.claude.com/docs/en/hooks.md (2026-10-16)
- https://code.claude.com/docs/en/hooks-guide.md (informe 11, fuente nueva)
- https://code.claude.com/docs/en/goal.md (2026-10-16)
- https://code.claude.com/docs/en/sub-agents.md (2026-10-16)
- https://code.claude.com/docs/en/model-config.md (2026-10-16)
- https://code.claude.com/docs/en/settings-reference.md (2026-10-16)
- https://code.claude.com/docs/en/costs.md (2026-10-16)
- https://code.claude.com/docs/en/scheduled-tasks.md (2026-10-16)
- https://code.claude.com/docs/en/routines.md (2026-10-16)
- https://code.claude.com/docs/en/github-actions.md (2026-10-16)
- https://code.claude.com/docs/en/worktrees (2026-10-16)
- https://code.claude.com/docs/en/best-practices (2026-10-16)
- https://code.claude.com/docs/en/memory (2026-10-16)
- https://code.claude.com/docs/en/how-claude-code-works (2026-10-16)
- https://www.anthropic.com/engineering/building-effective-agents (2026-10-16)
- https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents (2026-10-16)
- https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices (2026-10-16)
