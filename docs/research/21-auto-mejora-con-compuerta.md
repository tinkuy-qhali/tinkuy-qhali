---
item: 21
titulo: Auto-mejora con compuerta humana
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 21 — Auto-mejora con compuerta humana

## Pregunta
Cómo puede el repo proponer mejoras a sus reglas y skills sin deriva ni sobreajuste, con humano en la compuerta.

## Hallazgos
- Las routines (research preview) corren en la nube con disparo programado, por API o por GitHub; empujan a ramas `claude/`, se controlan con branch protection, y un estado verde no prueba éxito de la tarea (https://code.claude.com/docs/en/routines, 2026-10-16).
- `claude-code-action` con `prompt` corre en modo automatización (también por `schedule`); la documentación pide revisar los cambios antes de fusionar y limitar con `--max-turns` (https://code.claude.com/docs/en/github-actions, 2026-10-16).
- skill-creator compara con/sin skill (o contra la versión anterior) con Δ de aciertos, tiempo y tokens, y exige revisión humana; para descripciones separa 60 % de entrenamiento y 40 % retenido, y elige por la prueba (https://raw.githubusercontent.com/anthropics/skills/main/skills/skill-creator/SKILL.md, 2026-10-16).
- Evaluator-optimizer requiere criterios claros; se recomiendan máximo de iteraciones y pausas con humano (https://www.anthropic.com/engineering/building-effective-agents, 2026-10-16).
- Una evaluación al 100 % solo detecta regresiones; los graders deben resistir trampas y hay que leer transcripciones (https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents, 2026-10-16).
- La memoria automática es markdown editable que Claude escribe solo; CLAUDE.md y memoria son contexto, no configuración obligatoria (https://code.claude.com/docs/en/memory, 2026-10-16).
- **[no oficial]** SpecBench: los agentes pasan las pruebas visibles pero fallan las retenidas (https://arxiv.org/abs/2605.21384, 2026-10-16); DSPy optimiza pipelines contra una métrica (https://arxiv.org/abs/2310.03714, 2026-10-16).
- Costo por ciclo y umbral de Δ con 9 tareas × 3 repeticiones: sin fuente. **[provisional]**

## Decisión propuesta
- Decisión: ciclo disparador → evidencia → propuesta → compuerta → medición → aceptación o reversión (anexo `_21-anexo-ciclo.md`); un cambio por ciclo, PR con revisor humano, Δ en `results` contra `benchmarks.lock`, holdout (p. ej. B07–B09) no visible al proponente, cierre automático del PR si empeora | Alternativa descartada: auto-fusión o edición directa de CLAUDE.md | Confianza: media.
- Decisión: Ronda 1 manual al cierre de fase (skill `reflect` + LESSONS.md); Ronda 2 routine semanal y Action de medición | Alternativa descartada: routine desde Ronda 1 | Confianza: media.

## Riesgos y provisional
- Goodhart, deriva, inflación y costo se mitigan con holdout, tope de reglas y bitácora; el umbral de Δ y el reparto del holdout son **[provisional]** hasta medir varianza en Fase 3.
- El anexo 14 no estaba en el worktree; el formato de `benchmarks.lock` es supuesto **[provisional]**.

## Fuentes nuevas
- https://github.com/anthropics/claude-code-action/blob/main/docs/security.md — límites de la Action antes de dejarla proponer PR.
- https://arxiv.org/abs/2603.28063 — teoría de Goodhart en evaluación de agentes, para fijar el holdout.
