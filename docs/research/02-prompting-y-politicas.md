---
item: 2
titulo: Prompting y políticas de comportamiento según Anthropic
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 2 — Prompting y políticas de comportamiento

## Pregunta
Qué dice Anthropic sobre prompting y contexto, y qué políticas anti-sesgo, anti-deriva y de ahorro de tokens se derivan para el repo.

## Hallazgos
- Dar el motivo de una instrucción ayuda a Claude a entender el objetivo; usar 3–5 ejemplos en `<example>` y etiquetas XML para separar instrucciones, contexto y entradas (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices, 2026-10-16).
- Permitir explícitamente "no sé", extraer citas literales antes de analizar y retirar afirmaciones sin cita reduce alucinaciones (https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/reduce-hallucinations, 2026-10-16).
- Plantilla `investigate_before_answering`: nunca especular sobre código no abierto; leer antes de responder (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices, 2026-10-16).
- Multi-ventana: primera ventana arma el marco (tests, `init.sh`), luego lista de tareas; estado en JSON/git; ventana nueva suele superar a compactar (https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices, 2026-10-16).
- Dar a Claude una verificación ejecutable (tests, script); mostrar evidencia, no afirmar éxito; revisor en subagente con contexto fresco (https://code.claude.com/docs/en/best-practices, 2026-10-16).
- CLAUDE.md corto: si quitar una línea no causa errores, se borra; lo ocasional va en skills; subagentes devuelven resúmenes; `/clear` tras dos correcciones fallidas (https://code.claude.com/docs/en/best-practices, 2026-10-16).
- Contexto es recurso finito; recuperación just-in-time, progressive disclosure, notas persistentes y subagentes que devuelven 1.000–2.000 tokens (https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents, 2026-10-16).
- **[no oficial]** La sycofancia (ceder a la opinión del usuario) y el anclaje están documentados en la literatura sobre LLM. **[provisional]** sin fuente verificada hoy.

## Decisión propuesta
- Decisión: **Anti-sesgo**: (1) tratar la hipótesis del usuario como a contrastar, con evidencia a favor y en contra; (2) permitir "no sé"; (3) toda cifra lleva cita o etiqueta [provisional]; (4) revisor independiente en contexto fresco. | Alternativa descartada: confiar en el tono neutral del prompt | Confianza: media
- Decisión: **Anti-deriva**: (1) criterio de salida ejecutable por ítem; (2) releer la tarea antes de cerrar; (3) resumen de estado de 5 líneas por fase en archivo; (4) `/clear` tras dos correcciones. | Alternativa descartada: sesiones largas con compactación | Confianza: alta
- Decisión: **Ahorro de tokens**: (1) CLAUDE.md mínimo, el resto en skills; (2) scripts que devuelven resúmenes, nunca datos crudos; (3) subagentes para explorar; (4) leer por rangos. | Alternativa descartada: cargar documentación completa | Confianza: alta

## Riesgos y provisional
- Sycofancia/anclaje sin fuente oficial; se cierra en Fase 1 con evaluación propia. Las reglas no se han medido en este repo.

## Fuentes nuevas
- https://arxiv.org/abs/2310.13548 — sycofancia en LLM (literatura, no oficial).
- https://www.anthropic.com/engineering/building-effective-agents — patrones de agentes; no verificada hoy.
